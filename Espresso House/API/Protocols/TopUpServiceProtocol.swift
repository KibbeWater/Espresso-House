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
}
