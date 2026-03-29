//
//  WalletView.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI
import PassKit

struct WalletView: View {
    @StateObject var viewModel: WalletViewModel = WalletViewModel()
    @State private var showTopUp = false
    @State private var navigateToPaymentCards = false
    @State private var passInWallet = false
    @State private var generatedPass: PKPass?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Text("Wallet")
                        .font(.title)
                        .fontWeight(.semibold)

                    Spacer()
                }
                .padding(.horizontal)

                MemberID(id: SharedVars.shared.memberId ?? "", pinCode: viewModel.memberPinCode)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.secondary.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.horizontal)

                if !passInWallet, let pass = generatedPass {
                    AddPassToWalletButton([pass]) { added in
                        passInWallet = added
                    }
                    .addPassToWalletButtonStyle(.black)
                    .frame(height: 44)
                    .padding(.horizontal)
                }

                CoffeeCard(balance: viewModel.balance) {
                    showTopUp = true
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)

                NavigationLink {
                    FikaHouseView()
                } label: {
                    FikaClubCard(fikaPoints: $viewModel.points)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Fika Offers
                NavigationLink {
                    FikaHouseView()
                } label: {
                    FikaOffersCard(couponCount: viewModel.coupons.count)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Payment Cards
                NavigationLink {
                    PaymentCardsView()
                } label: {
                    PaymentCardsCard(cards: viewModel.paymentCards)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showTopUp) {
            Task { try? await viewModel.refresh() }
        } content: {
            TopUpView()
        }
        .navigationDestination(isPresented: $navigateToPaymentCards) {
            PaymentCardsView()
        }
        .onAppear {
            // Handle pending navigation from Profile
            if SharedVars.shared.pendingNavigation == .walletPaymentCards {
                SharedVars.shared.pendingNavigation = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigateToPaymentCards = true
                }
            }

            // Check if pass is already in wallet
            if let memberId = SharedVars.shared.memberId {
                passInWallet = PassGenerator.isPassInWallet(memberId: memberId)
            }
        }
        .onChange(of: viewModel.memberFirstName) {
            fetchPass()
        }
    }

    private func fetchPass() {
        guard generatedPass == nil,
              !passInWallet,
              let memberId = SharedVars.shared.memberId else { return }
        Task {
            generatedPass = try? await PassGenerator.generatePass(
                memberId: memberId,
                firstName: viewModel.memberFirstName,
                lastName: viewModel.memberLastName,
                pinCode: viewModel.memberPinCode
            )
        }
    }
}

#Preview {
    WalletView()
}
