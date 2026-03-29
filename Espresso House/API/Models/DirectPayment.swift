//
//  DirectPayment.swift
//  Espresso House
//

import Foundation

struct StartDirectPaymentRequest: Encodable {
    let directPaymentMethodKey: String
    let amount: Double
    let currencyCode: String
    let marketCountryCode: String
    let orderNumber: String?
    let orderType: String               // "TOPUP" for top-ups, "PreOrder" for orders
    let coffeeShopId: Int?

    // Match Gson behavior: omit nil fields entirely instead of sending null
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(directPaymentMethodKey, forKey: .directPaymentMethodKey)
        try container.encode(amount, forKey: .amount)
        try container.encode(orderType, forKey: .orderType)
        try container.encode(marketCountryCode, forKey: .marketCountryCode)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encodeIfPresent(orderNumber, forKey: .orderNumber)
        try container.encodeIfPresent(coffeeShopId, forKey: .coffeeShopId)
    }

    private enum CodingKeys: String, CodingKey {
        case directPaymentMethodKey, amount, orderType, marketCountryCode
        case currencyCode, orderNumber, coffeeShopId
    }
}

struct StartDirectPaymentResponse: Decodable {
    let terminalUrl: String?
    let paymentTransactionKey: String?
    let paymentDirectlyPaid: Bool?
}

struct PaymentTransactionResponse: Decodable {
    let paymentTransactionKey: String?
    let paymentTransactionState: String?
    let paymentType: String?
    let directPaymentMethod: String?
    let amount: Double?
    let currency: String?
}

// MARK: - Direct payment methods (from /TopUp/v2/{id}/paymentoptions)

struct DirectPaymentMethod: Decodable {
    let method: String?
    let methodKey: String?
    let displayName: String?

    // The top-up endpoint uses topUpPayment* prefixed field names
    private enum CodingKeys: String, CodingKey {
        case topUpPaymentMethod, topUpPaymentMethodKey, topUpPaymentDisplayName
        // Market endpoint uses different names
        case paymentMethod, paymentMethodKey, paymentDisplayName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try topUp-prefixed fields first, fall back to market endpoint fields
        method = (try? container.decode(String.self, forKey: .topUpPaymentMethod))
            ?? (try? container.decode(String.self, forKey: .paymentMethod))
        methodKey = (try? container.decode(String.self, forKey: .topUpPaymentMethodKey))
            ?? (try? container.decode(String.self, forKey: .paymentMethodKey))
        displayName = (try? container.decode(String.self, forKey: .topUpPaymentDisplayName))
            ?? (try? container.decode(String.self, forKey: .paymentDisplayName))
    }

    init(method: String?, methodKey: String?, displayName: String?) {
        self.method = method
        self.methodKey = methodKey
        self.displayName = displayName
    }
}
