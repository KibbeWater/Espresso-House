//
//  CheckoutView.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import SwiftUI
import Kingfisher

struct CheckoutView: View {
    @Environment(\.espressoAPI) private var api
    @Environment(\.dismiss) private var dismiss

    @Bindable var cart: CartViewModel
    @Environment(\.activeOrderVM) private var activeOrderVM

    @State private var viewModel = CheckoutViewModel()
    @State private var memberName = ""
    @State private var showActiveOrder = false
    @State private var showTopUp = false

    private var orderService: any OrderServiceProtocol {
        #if DEBUG
        if DebugSettings.shared.isSimulating {
            return MockOrderService.shared
        }
        #endif
        return api.order
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    #if DEBUG
                    if DebugSettings.shared.isSimulating {
                        HStack {
                            Image(systemName: "hammer.fill")
                            Text("SIMULATED ORDER")
                                .fontWeight(.bold)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                    }
                    #endif

                    // Order summary
                    orderSummarySection

                    Divider()

                    // Payment methods
                    paymentMethodsSection

                    Divider()

                    // Order type
                    orderTypeSection

                    Spacer().frame(height: 100)
                }
                .padding()
            }

            // Error banner
            if let error = viewModel.error {
                VStack {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    Spacer()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            payButton
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showActiveOrder) {
            ActiveOrderView()
        }
        .onAppear {
            Task {
                await viewModel.loadPaymentOptions(api: orderService)
                if let member = try? await api.member.getMember() {
                    memberName = member.firstName
                }
            }
        }
        .onChange(of: viewModel.orderComplete) { _, complete in
            if complete {
                activeOrderVM.startPolling(api: orderService)
                #if DEBUG
                if DebugSettings.shared.isSimulating {
                    // In simulation: go to Home tab so user sees the active order banner
                    SharedVars.shared.selectedTab = 0
                    dismiss()
                    return
                }
                #endif
                showActiveOrder = true
            }
        }
        .onChange(of: showActiveOrder) { _, showing in
            // When ActiveOrderView is dismissed and order was completed, pop back to root
            if !showing && viewModel.orderComplete {
                dismiss()
            }
        }
        .sheet(isPresented: $showTopUp, onDismiss: {
            Task { await viewModel.loadPaymentOptions(api: orderService) }
        }) {
            TopUpView()
        }
        .fullScreenCover(isPresented: $viewModel.showDirectPaymentWebView, onDismiss: {
            Task { await viewModel.completeDirectPayment(cart: cart) }
        }) {
            if let url = viewModel.directPaymentURL {
                WebViewSheet(url: url, title: "Complete Payment")
            }
        }
    }

    // MARK: - Sections

    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.headline)

            ForEach(cart.items) { item in
                HStack(alignment: .top) {
                    if let imgUrl = item.product.img, let url = URL(string: imgUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.product.articleName)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        Text(item.sizeName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Show selected upsells
                        if let upsells = item.product.upsell?.filter({ $0.selected }) {
                            ForEach(upsells) { upsell in
                                Text("+ \(upsell.articleName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(Int(item.totalPrice)) \(cart.currency)")
                            .fontWeight(.medium)
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(cart.totalPrice)) \(cart.currency)")
                    .fontWeight(.bold)
                    .font(.title3)
            }
        }
    }

    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading payment methods...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.paymentOptions.isEmpty {
                Text("No saved payment methods found")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.paymentOptions) { option in
                    let insufficientBalance = option.isCoffeeCard && viewModel.coffeeCardBalance < cart.totalPrice

                    Button {
                        if !insufficientBalance {
                            withAnimation {
                                viewModel.selectedPayment = option
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: option.iconName)
                                .font(.title2)
                                .frame(width: 36)

                            VStack(alignment: .leading) {
                                Text(option.displayLabel)
                                    .fontWeight(.medium)
                                    .foregroundStyle(insufficientBalance ? .secondary : .primary)
                                if let expiry = option.expiryDate {
                                    Text("Expires \(expiry)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if insufficientBalance {
                                    HStack(spacing: 4) {
                                        Text("Insufficient balance")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                        Text("·")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Button("Top up") {
                                            showTopUp = true
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    }
                                }
                            }

                            Spacer()

                            if viewModel.selectedPayment?.id == option.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            viewModel.selectedPayment?.id == option.id
                                ? Color.accentColor.opacity(0.08)
                                : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(insufficientBalance)
                }
            }
        }
    }

    private var orderTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order Type")
                .font(.headline)

            let takeAwayOnly = cart.shop.takeAwayOnly ?? false

            if takeAwayOnly {
                HStack {
                    Image(systemName: "bag.fill")
                    Text("Take Away")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(CheckoutViewModel.OrderType.allCases, id: \.self) { type in
                    Button {
                        withAnimation {
                            viewModel.selectedOrderType = type
                        }
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                                .fontWeight(.medium)
                            Spacer()
                            if viewModel.selectedOrderType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                        .padding()
                        .background(
                            viewModel.selectedOrderType == type
                                ? Color.accentColor.opacity(0.08)
                                : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var canPay: Bool {
        guard let payment = viewModel.selectedPayment, !viewModel.isProcessing else { return false }
        if payment.isCoffeeCard && viewModel.coffeeCardBalance < cart.totalPrice {
            return false
        }
        return true
    }

    private var payButton: some View {
        Button {
            Task {
                await viewModel.placeOrder(cart: cart, api: orderService, memberName: memberName)
            }
        } label: {
            Group {
                if viewModel.isProcessing {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Processing...")
                    }
                } else {
                    Text("Pay \(Int(cart.totalPrice)) \(cart.currency)")
                }
            }
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canPay ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding()
        }
        .disabled(!canPay)
    }
}
