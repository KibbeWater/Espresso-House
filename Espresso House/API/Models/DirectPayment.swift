//
//  DirectPayment.swift
//  Espresso House
//

import Foundation

struct StartDirectPaymentRequest: Encodable {
    let directPaymentMethodKey: String  // e.g. "PAYPAL"
    let amount: Double
    let currencyCode: String
    let marketCountryCode: String
    let orderNumber: String
    let orderType: String               // e.g. "TopUp"
    let coffeeShopId: String?
}

struct StartDirectPaymentResponse: Decodable {
    let terminalUrl: String
    let paymentTransactionKey: String
    let paymentDirectlyPaid: Bool?
}

struct PaymentTransactionResponse: Decodable {
    let paymentTransactionKey: String?
    let paymentTransactionState: String?
}
