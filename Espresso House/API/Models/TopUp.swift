//
//  TopUp.swift
//  Espresso House
//

import Foundation

// MARK: - Top-up values (GET /TopUp/v2/{memberId}/topupvalues)

struct TopUpValuesResponse: Decodable {
    let topUpValues: [TopUpValue]?
}

struct TopUpValue: Codable, Identifiable, Hashable {
    var id: Double { amount }

    let amount: Double
    let currency: String
    let punchReward: Int?

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case punchReward = "numberOfPunches"
    }
}

// MARK: - Top-up payment options (GET /TopUp/v2/{memberId}/paymentoptions)

struct TopUpPaymentOptionsResponse: Decodable {
    let paymentOptions: [TopUpPaymentMethod]?
}

struct TopUpPaymentMethod: Decodable {
    let paymentMethodKey: String    // e.g. "CreditCard", "Swish", "PayPal", "MobilePay", "Vipps"
    let isAvailable: Bool?
}

// MARK: - Credit card top-up request (POST /TopUp/v1/{memberId})

struct TopUpCreditCardRequest: Encodable {
    let paymentTokenKey: String
    let currencyCode: String
    let amount: Double
}

// MARK: - Swish top-up (POST /TopUp/v1/{memberId}/swish)

struct TopUpSwishRequest: Encodable {
    let currencyCode: String
    let amount: Double
}

struct TopUpSwishResponse: Decodable {
    let swishPaymentRequestToken: String
}
