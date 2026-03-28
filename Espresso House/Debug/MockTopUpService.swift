//
//  MockTopUpService.swift
//  Espresso House
//

#if DEBUG
import Foundation

class MockTopUpService: TopUpServiceProtocol {
    func getTopUpValues() async throws -> [TopUpValue] {
        [
            TopUpValue(amount: 100, currency: "SEK", punchReward: 1),
            TopUpValue(amount: 200, currency: "SEK", punchReward: 2),
            TopUpValue(amount: 300, currency: "SEK", punchReward: 4),
            TopUpValue(amount: 500, currency: "SEK", punchReward: 7)
        ]
    }

    func getTopUpPaymentMethods() async throws -> [TopUpPaymentMethod] {
        [
            TopUpPaymentMethod(paymentMethodKey: "CreditCard", isAvailable: true),
            TopUpPaymentMethod(paymentMethodKey: "Swish", isAvailable: true)
        ]
    }

    func topUpWithCreditCard(paymentTokenKey: String, currencyCode: String, amount: Double) async throws {
        try await Task.sleep(for: .milliseconds(500))
        await MainActor.run {
            DebugSettings.shared.mockCoffeeCardBalance += amount
        }
    }

    func topUpWithSwish(currencyCode: String, amount: Double) async throws -> String {
        try await Task.sleep(for: .milliseconds(500))
        await MainActor.run {
            DebugSettings.shared.mockCoffeeCardBalance += amount
        }
        return "mock-swish-token-\(UUID().uuidString)"
    }

    func getMemberEvents() async throws -> [MemberEvent] {
        [MemberEvent(eventType: "TopUpSwishCompleted", myEspressoHouseNumber: "mock", eventData: nil, created: nil)]
    }
}
#endif
