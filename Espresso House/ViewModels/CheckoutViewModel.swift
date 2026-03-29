//
//  CheckoutViewModel.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

@Observable
class CheckoutViewModel {
    var paymentOptions: [PaymentOption] = []
    var selectedPayment: PaymentOption?
    var coffeeCardBalance: Double = 0
    var isLoading = false
    var isProcessing = false
    var orderComplete = false
    var completedOrderKey: String?
    var error: String?

    // DirectPayment (PayPal) state
    var showDirectPaymentWebView = false
    var directPaymentURL: URL?
    var directPaymentTransactionKey: String?

    private var api: (any OrderServiceProtocol)?

    func loadPaymentOptions(api: any OrderServiceProtocol) async {
        self.api = api
        isLoading = true
        defer { isLoading = false }

        do {
            paymentOptions = try await api.getPaymentOptions()
            if let ccOption = paymentOptions.first(where: { $0.isCoffeeCard }) {
                coffeeCardBalance = ccOption.balanceAmount ?? 0
            }
            if selectedPayment == nil {
                selectedPayment = paymentOptions.first
            }
        } catch {
            self.error = "Failed to load payment methods: \(error.localizedDescription)"
        }
    }

    func placeOrder(cart: CartViewModel, api: any OrderServiceProtocol, memberName: String) async {
        guard let payment = selectedPayment else {
            error = "Please select a payment method"
            return
        }
        guard let memberId = SharedVars.shared.memberId else {
            error = "Not authenticated"
            return
        }

        self.api = api
        isProcessing = true
        error = nil

        do {
            let configurations = cart.buildConfigurations()

            // Step 1: Create order
            let createRequest = OrderCreateRequest(
                shopNumber: String(cart.shop.id),
                orderType: "PreOrderTakeAway",
                includeMemberDiscount: true,
                customerDisplayName: memberName,
                myEspressoHouseNumber: memberId,
                configurations: configurations
            )
            let createResponse = try await api.createOrder(request: createRequest)
            let orderKey = createResponse.digitalOrderKey

            // Step 2: Confirm order
            let confirmRequest = OrderConfirmRequest(
                shopNumber: String(cart.shop.id),
                orderType: "PreOrderTakeAway",
                includeMemberDiscount: false,
                customerDisplayName: memberName,
                myEspressoHouseNumber: memberId,
                digitalOrderKey: orderKey,
                payments: [],
                configurations: configurations
            )
            _ = try await api.confirmOrder(digitalOrderKey: orderKey, request: confirmRequest)

            // Step 3: Handle payment based on type
            if payment.paymentType == "DIRECT_PAYMENT" {
                // DirectPayment (PayPal) — need to open WebView first
                let dpRequest = StartDirectPaymentRequest(
                    directPaymentMethodKey: payment.paymentIdentifier, // e.g. "PAYPAL"
                    amount: cart.totalPrice,
                    currencyCode: cart.currency,
                    marketCountryCode: "SE", // TODO: derive from member
                    orderNumber: createResponse.orderNumber ?? orderKey,
                    orderType: "PreOrder",
                    coffeeShopId: cart.shop.id
                )
                let dpResponse = try await api.createDirectPayment(request: dpRequest)

                if dpResponse.paymentDirectlyPaid == true {
                    // Already paid — finalize directly
                    try await finalizeWithDirectPayment(orderKey: orderKey, memberId: memberId, api: api)
                } else {
                    // Need user to complete payment in WebView
                    directPaymentURL = dpResponse.terminalUrl.flatMap { URL(string: $0) }
                    directPaymentTransactionKey = dpResponse.paymentTransactionKey
                    completedOrderKey = orderKey
                    showDirectPaymentWebView = true
                    isProcessing = false
                    return // Will continue in completeDirectPayment()
                }
            } else {
                // CoffeeCard or CreditCard — finalize directly
                let finalizeRequest = OrderFinalizeRequest(
                    myEspressoHouseNumber: memberId,
                    paymentMethod: PaymentMethod(
                        paymentType: payment.paymentType,
                        paymentIdentifier: payment.paymentIdentifier
                    )
                )
                try await api.finalizeOrder(digitalOrderKey: orderKey, request: finalizeRequest)
            }

            completedOrderKey = orderKey
            orderComplete = true
            cart.clear()
        } catch {
            self.error = "Order failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    /// Called after user completes DirectPayment in WebView
    func completeDirectPayment(cart: CartViewModel) async {
        guard let api, let transactionKey = directPaymentTransactionKey,
              let orderKey = completedOrderKey,
              let memberId = SharedVars.shared.memberId else {
            error = "Missing payment context"
            return
        }

        isProcessing = true
        showDirectPaymentWebView = false
        error = nil

        do {
            // Poll transaction status until completed
            var attempts = 0
            while attempts < 30 {
                let status = try await api.getPaymentTransactionStatus(transactionKey: transactionKey)
                if status.paymentTransactionState == "Completed" || status.paymentTransactionState == "Authorized" {
                    break
                }
                if status.paymentTransactionState == "Failed" || status.paymentTransactionState == "Cancelled" {
                    throw EspressoAPIError.internalError(description: "Payment was \(status.paymentTransactionState ?? "cancelled")")
                }
                try await Task.sleep(for: .seconds(2))
                attempts += 1
            }

            // Finalize the order
            try await finalizeWithDirectPayment(orderKey: orderKey, memberId: memberId, api: api)

            orderComplete = true
            cart.clear()
        } catch {
            self.error = "Payment failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    private func finalizeWithDirectPayment(orderKey: String, memberId: String, api: any OrderServiceProtocol) async throws {
        let finalizeRequest = OrderFinalizeRequest(
            myEspressoHouseNumber: memberId,
            paymentMethod: PaymentMethod(
                paymentType: "DIRECT_PAYMENT",
                paymentIdentifier: directPaymentTransactionKey ?? ""
            )
        )
        try await api.finalizeOrder(digitalOrderKey: orderKey, request: finalizeRequest)
    }
}
