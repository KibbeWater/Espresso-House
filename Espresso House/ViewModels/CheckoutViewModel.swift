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
    var isLoading = false
    var isProcessing = false
    var orderComplete = false
    var completedOrderKey: String?
    var error: String?

    private var api: (any OrderServiceProtocol)?

    func loadPaymentOptions(api: any OrderServiceProtocol) async {
        self.api = api
        isLoading = true
        defer { isLoading = false }

        do {
            paymentOptions = try await api.getPaymentOptions()
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

            // Step 3: Finalize with payment
            let finalizeRequest = OrderFinalizeRequest(
                myEspressoHouseNumber: memberId,
                paymentMethod: PaymentMethod(
                    paymentType: payment.paymentType,
                    paymentIdentifier: payment.paymentIdentifier
                )
            )
            try await api.finalizeOrder(digitalOrderKey: orderKey, request: finalizeRequest)

            completedOrderKey = orderKey
            orderComplete = true
            cart.clear()
        } catch {
            self.error = "Order failed: \(error.localizedDescription)"
        }

        isProcessing = false
    }
}
