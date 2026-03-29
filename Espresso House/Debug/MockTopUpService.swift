//
//  MockTopUpService.swift
//  Espresso House
//

#if DEBUG
import Foundation

class MockTopUpService: TopUpServiceProtocol {
    func getTopUpValues() async throws -> [TopUpValue] {
        [
            TopUpValue(amount: 100, currency: "SEK", countryCode: "SE", punchReward: 2),
            TopUpValue(amount: 200, currency: "SEK", countryCode: "SE", punchReward: 4),
            TopUpValue(amount: 300, currency: "SEK", countryCode: "SE", punchReward: 6),
            TopUpValue(amount: 500, currency: "SEK", countryCode: "SE", punchReward: 10)
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

    func getDirectPaymentMethods() async throws -> [DirectPaymentMethod] {
        [DirectPaymentMethod(method: "PayPal", methodKey: "mock-paypal-key", displayName: "PayPal")]
    }

    func createDirectPayment(request: StartDirectPaymentRequest) async throws -> StartDirectPaymentResponse {
        try await Task.sleep(for: .milliseconds(500))
        await MainActor.run {
            DebugSettings.shared.mockCoffeeCardBalance += request.amount
        }
        return StartDirectPaymentResponse(
            terminalUrl: "https://example.com/mock-paypal",
            paymentTransactionKey: UUID().uuidString,
            paymentDirectlyPaid: true
        )
    }

    func getPaymentTransactionStatus(transactionKey: String) async throws -> PaymentTransactionResponse {
        PaymentTransactionResponse(paymentTransactionKey: transactionKey, paymentTransactionState: "Completed", paymentType: nil, directPaymentMethod: nil, amount: nil, currency: nil)
    }
}
#endif
