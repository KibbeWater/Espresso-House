//
//  WalletViewModel.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

class WalletViewModel: ObservableObject {
    private var api = EspressoAPI.shared
    
    @Published var points: Int = 0
    @Published var balance: Balance?
    @Published var coupons: [Coupon] = []
    @Published var paymentCards: [PaymentOption] = []
    @Published var memberFirstName: String = ""
    @Published var memberLastName: String = ""
    @Published var memberPinCode: String?

    init() {
        Task {
            do {
                try await refresh()
            } catch (let err) {
                print(err)
            }
        }
    }

    func refresh() async throws {
        async let memberTask = api.member.getMember()
        async let cardsTask = api.order.getPaymentOptions()

        let member = try await memberTask
        let allCards = (try? await cardsTask) ?? []

        await MainActor.run {
            self.points = member.fikaPoints
            self.balance = member.balance
            self.coupons = member.coupons
            self.paymentCards = allCards.filter { !$0.isCoffeeCard }
            self.memberFirstName = member.firstName
            self.memberLastName = member.lastName
            self.memberPinCode = member.pinCode
        }
    }
}
