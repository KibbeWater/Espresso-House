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
    var directPaymentMethods: [DirectPaymentMethod] = []
    var isLoading = false
    var isProcessing = false
    var error: String?
    var topUpComplete = false
    var swishToken: String?

    // Custom amount
    var allowCustomAmount = false
    var isCustomAmountMode = false
    var customAmountText: String = ""

    // DirectPayment state
    var showDirectPaymentWebView = false
    var directPaymentURL: URL?
    var directPaymentTransactionKey: String?
    var directPaymentResponseOK = false

    private(set) var topUpCurrency: String = "SEK"

    private var topUpService: TopUpServiceProtocol?
    private var punchRatio: Double = 50.0
    private var marketCountryCode: String = "SE"
    private var activePoller: EventPoller?

    var hasDirectPaymentMethods: Bool {
        !directPaymentMethods.isEmpty
    }

    var customAmount: Double {
        Double(customAmountText) ?? 0
    }

    var customAmountMinimum: Double {
        #if DEBUG
        return 1
        #else
        return 300
        #endif
    }

    var isCustomAmountValid: Bool {
        let amount = customAmount
        guard amount >= customAmountMinimum else { return false }
        #if DEBUG
        return true
        #else
        return amount.truncatingRemainder(dividingBy: punchRatio) == 0
        #endif
    }

    var customAmountFollowsIncrements: Bool {
        customAmount.truncatingRemainder(dividingBy: punchRatio) == 0
    }

    var customAmountPunches: Int {
        Int(customAmount / punchRatio)
    }

    var effectiveSelectedAmount: TopUpValue? {
        if isCustomAmountMode && isCustomAmountValid {
            return TopUpValue(
                amount: customAmount,
                currency: topUpCurrency,
                countryCode: marketCountryCode,
                punchReward: customAmountPunches
            )
        }
        return selectedAmount
    }

    func loadData(topUpService: TopUpServiceProtocol, orderService: any OrderServiceProtocol) async {
        self.topUpService = topUpService
        isLoading = true
        defer { isLoading = false }

        do {
            async let valuesTask = topUpService.getTopUpValues()
            async let methodsTask = topUpService.getTopUpPaymentMethods()
            async let cardsTask = orderService.getPaymentOptions()

            let (values, methods, allCards) = try await (valuesTask, methodsTask, cardsTask)

            // Detect uniform 1-punch-per-50kr ratio
            let hasUniform50Ratio = !values.isEmpty && values.allSatisfy { value in
                guard let punches = value.punchReward, punches > 0 else { return false }
                return value.amount / Double(punches) == 50.0
            }

            if hasUniform50Ratio {
                let currency = values.first?.currency ?? "SEK"
                let country = values.first?.countryCode ?? "SE"
                topUpCurrency = currency
                marketCountryCode = country
                punchRatio = 50.0

                topUpValues = [
                    TopUpValue(amount: 300, currency: currency, countryCode: country, punchReward: 6),
                    TopUpValue(amount: 500, currency: currency, countryCode: country, punchReward: 10),
                    TopUpValue(amount: 700, currency: currency, countryCode: country, punchReward: 14),
                ]
                allowCustomAmount = true
                customAmountText = "\(Int(customAmountMinimum))"
            } else {
                topUpValues = values
                topUpCurrency = values.first?.currency ?? "SEK"
                marketCountryCode = values.first?.countryCode ?? "SE"
                allowCustomAmount = false
            }

            creditCards = allCards.filter { !$0.isCoffeeCard }
            selectedCard = creditCards.first

            // Get direct payment methods from top-up payment options endpoint
            // Filter to only methods that aren't handled by other flows (CreditCard, Swish, CoffeeCard)
            let allDirect = (try? await topUpService.getDirectPaymentMethods()) ?? []
            let excludedMethods: Set<String> = ["creditcard", "swish", "coffeecard"]
            directPaymentMethods = allDirect.filter {
                guard let method = $0.method?.lowercased() ?? $0.methodKey?.lowercased() else { return false }
                return !excludedMethods.contains(method)
            }

            // Check Swish availability by app presence rather than API response
            await MainActor.run {
                isSwishAvailable = UIApplication.shared.canOpenURL(URL(string: "swish://")!)
            }

            if selectedAmount == nil && !isCustomAmountMode {
                selectedAmount = topUpValues.first
            }
        } catch {
            self.error = "Failed to load top-up options: \(error.localizedDescription)"
        }
    }

    /// Called when the app receives the Swish callback URL.
    func handleSwishCallback() {
        activePoller?.nudge()
        Task {
            try? await Task.sleep(for: .seconds(1))
            activePoller?.nudge()
        }
    }

    func selectPreset(_ value: TopUpValue) {
        isCustomAmountMode = false
        selectedAmount = value
    }

    func selectCustom() {
        isCustomAmountMode = true
        selectedAmount = nil
    }

    // MARK: - Credit Card Top-Up

    func topUpWithCard(topUpService: TopUpServiceProtocol) async {
        guard let amount = effectiveSelectedAmount, let card = selectedCard else {
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

    // MARK: - Swish Top-Up

    func topUpWithSwish(topUpService: TopUpServiceProtocol) async {
        guard let amount = effectiveSelectedAmount else {
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

            let callback = "espresso-hause://swish-callback"
            if let url = URL(string: "swish://paymentrequest?token=\(token)&callbackurl=\(callback)") {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }

            let poller = EventPoller(topUpService: topUpService)
            activePoller = poller
            _ = try await poller.pollForEvent(
                expectedType: "TopUpSwishCompleted",
                failureTypes: ["TopUpSwishFailed"]
            )
            activePoller = nil
            topUpComplete = true
        } catch {
            self.error = "Swish top-up failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    // MARK: - DirectPayment Top-Up (PayPal, etc.)

    func topUpWithDirectPayment(method: DirectPaymentMethod, topUpService: TopUpServiceProtocol) async {
        guard let amount = effectiveSelectedAmount,
              let methodKey = method.methodKey else {
            error = "Please select an amount"
            return
        }

        self.topUpService = topUpService
        isProcessing = true
        error = nil

        do {
            guard let memberId = SharedVars.shared.memberId else {
                error = "Not authenticated"
                isProcessing = false
                return
            }

            let request = StartDirectPaymentRequest(
                directPaymentMethodKey: methodKey,
                amount: amount.amount,
                currencyCode: amount.currency,
                marketCountryCode: marketCountryCode,
                orderNumber: memberId,
                orderType: "TOPUP",
                coffeeShopId: nil
            )
            let response = try await topUpService.createDirectPayment(request: request)
            print("[DirectPayment] Response: terminalUrl=\(response.terminalUrl ?? "nil") transactionKey=\(response.paymentTransactionKey ?? "nil") directlyPaid=\(response.paymentDirectlyPaid?.description ?? "nil")")

            if response.paymentDirectlyPaid == true {
                topUpComplete = true
            } else {
                directPaymentURL = response.terminalUrl.flatMap { URL(string: $0) }
                directPaymentTransactionKey = response.paymentTransactionKey
                directPaymentResponseOK = false
                print("[DirectPayment] Opening WebView: url=\(directPaymentURL?.absoluteString ?? "nil")")
                showDirectPaymentWebView = true
                isProcessing = false
                return
            }
        } catch {
            self.error = "Payment failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    /// Called when WebView detects responseCode=OK
    func handleDirectPaymentResponseOK() {
        directPaymentResponseOK = true
    }

    /// Called when WebView detects responseCode=Cancel
    func handleDirectPaymentCancel() {
        showDirectPaymentWebView = false
        directPaymentTransactionKey = nil
        directPaymentURL = nil
        error = "Payment was cancelled"
    }

    func completeDirectPayment(topUpService: TopUpServiceProtocol) async {
        guard let transactionKey = directPaymentTransactionKey else {
            error = "Missing payment context"
            return
        }

        isProcessing = true
        showDirectPaymentWebView = false
        error = nil

        do {
            // Run event polling and status polling concurrently — first to succeed wins
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Event-based detection
                group.addTask {
                    let poller = EventPoller(topUpService: topUpService)
                    _ = try await poller.pollForEvent(
                        expectedType: "DirectPaymentSuccess",
                        failureTypes: ["DirectPaymentFailed"]
                    )
                }

                // Status polling
                group.addTask {
                    var attempts = 0
                    while attempts < 30 {
                        try Task.checkCancellation()
                        let status = try await topUpService.getPaymentTransactionStatus(transactionKey: transactionKey)
                        if status.paymentTransactionState == "Completed" || status.paymentTransactionState == "Authorized" {
                            return
                        }
                        if status.paymentTransactionState == "Failed" || status.paymentTransactionState == "Cancelled" {
                            throw EspressoAPIError.internalError(description: "Payment was \(status.paymentTransactionState ?? "cancelled")")
                        }
                        try await Task.sleep(for: .seconds(2))
                        attempts += 1
                    }
                    throw EventPollerError.timeout
                }

                // First task to complete wins, cancel the other
                if let result = try await group.next() {
                    group.cancelAll()
                    return result
                }
            }
            topUpComplete = true
        } catch {
            self.error = "Payment failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    // MARK: - Custom Amount Stepper (release mode)

    func incrementCustomAmount() {
        let current = customAmount
        customAmountText = "\(Int(current + punchRatio))"
    }

    func decrementCustomAmount() {
        let current = customAmount
        let newVal = current - punchRatio
        if newVal >= customAmountMinimum {
            customAmountText = "\(Int(newVal))"
        }
    }
}
