//
//  TopUpViewModel.swift
//  Espresso House
//

import Foundation
import UIKit

@Observable
class TopUpViewModel {
    var topUpValues: [TopUpValue] = []
    var creditCards: [PaymentOption] = []
    var selectedAmount: TopUpValue?
    var selectedCard: PaymentOption?
    var isSwishAvailable = false
    var isLoading = false
    var isProcessing = false
    var error: String?
    var topUpComplete = false
    var swishToken: String?

    private var topUpService: TopUpServiceProtocol?

    func loadData(topUpService: TopUpServiceProtocol, orderService: any OrderServiceProtocol) async {
        self.topUpService = topUpService
        isLoading = true
        defer { isLoading = false }

        do {
            async let valuesTask = topUpService.getTopUpValues()
            async let methodsTask = topUpService.getTopUpPaymentMethods()
            async let cardsTask = orderService.getPaymentOptions()

            let (values, methods, allCards) = try await (valuesTask, methodsTask, cardsTask)

            topUpValues = values
            creditCards = allCards.filter { !$0.isCoffeeCard }
            selectedCard = creditCards.first

            isSwishAvailable = methods.contains { $0.paymentMethodKey == "Swish" && ($0.isAvailable ?? true) }

            if selectedAmount == nil {
                selectedAmount = topUpValues.first
            }
        } catch {
            self.error = "Failed to load top-up options: \(error.localizedDescription)"
        }
    }

    func topUpWithCard(topUpService: TopUpServiceProtocol) async {
        guard let amount = selectedAmount, let card = selectedCard else {
            error = "Please select an amount and payment card"
            return
        }

        isProcessing = true
        error = nil

        do {
            try await topUpService.topUpWithCreditCard(
                paymentTokenKey: card.paymentIdentifier,
                currencyCode: amount.currency,
                amount: amount.amount
            )
            topUpComplete = true
        } catch {
            self.error = "Top-up failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    func topUpWithSwish(topUpService: TopUpServiceProtocol) async {
        guard let amount = selectedAmount else {
            error = "Please select an amount"
            return
        }

        isProcessing = true
        error = nil

        do {
            let token = try await topUpService.topUpWithSwish(
                currencyCode: amount.currency,
                amount: amount.amount
            )
            swishToken = token

            // Open Swish app
            if let url = URL(string: "swish://paymentrequest?token=\(token)") {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }

            // Poll for completion
            let poller = EventPoller(topUpService: topUpService)
            _ = try await poller.pollForEvent(
                expectedType: "TopUpSwishCompleted",
                failureTypes: ["TopUpSwishFailed"]
            )
            topUpComplete = true
        } catch {
            self.error = "Swish top-up failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }
}
