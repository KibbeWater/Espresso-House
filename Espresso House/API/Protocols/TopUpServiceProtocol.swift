//
//  TopUpServiceProtocol.swift
//  Espresso House
//

import Foundation

protocol TopUpServiceProtocol {
    func getTopUpValues() async throws -> [TopUpValue]
    func getTopUpPaymentMethods() async throws -> [TopUpPaymentMethod]
    func topUpWithCreditCard(paymentTokenKey: String, currencyCode: String, amount: Double) async throws
    func topUpWithSwish(currencyCode: String, amount: Double) async throws -> String
    func getMemberEvents() async throws -> [MemberEvent]
    func getDirectPaymentMethods() async throws -> [DirectPaymentMethod]
    func createDirectPayment(request: StartDirectPaymentRequest) async throws -> StartDirectPaymentResponse
    func getPaymentTransactionStatus(transactionKey: String) async throws -> PaymentTransactionResponse
}
