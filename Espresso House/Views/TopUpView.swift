//
//  TopUpView.swift
//  Espresso House
//

import SwiftUI

struct TopUpView: View {
    @Environment(\.espressoAPI) private var api
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = TopUpViewModel()

    private var topUpService: TopUpServiceProtocol {
        #if DEBUG
        if DebugSettings.shared.isSimulating { return MockTopUpService() }
        #endif
        return api.topUp
    }

    private var orderService: any OrderServiceProtocol {
        #if DEBUG
        if DebugSettings.shared.isSimulating { return MockOrderService() }
        #endif
        return api.order
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        #if DEBUG
                        if DebugSettings.shared.isSimulating {
                            HStack {
                                Image(systemName: "hammer.fill")
                                Text("SIMULATED TOP-UP")
                                    .fontWeight(.bold)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                        }
                        #endif

                        amountSection

                        Divider()

                        paymentSection

                        Spacer().frame(height: 80)
                    }
                    .padding()
                }

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
                            .onTapGesture { withAnimation { viewModel.error = nil } }
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(5))
                            withAnimation { viewModel.error = nil }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                topUpButton
            }
            .navigationTitle("Top Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                Task { await viewModel.loadData(topUpService: topUpService, orderService: orderService) }
            }
            .onChange(of: viewModel.topUpComplete) { _, complete in
                if complete { dismiss() }
            }
            .onOpenURL { url in
                if url.host == "swish-callback" {
                    viewModel.handleSwishCallback()
                }
            }
            .fullScreenCover(isPresented: $viewModel.showDirectPaymentWebView, onDismiss: {
                Task { await viewModel.completeDirectPayment(topUpService: topUpService) }
            }) {
                if let url = viewModel.directPaymentURL {
                    WebViewSheet(
                        url: url,
                        title: "Complete Payment",
                        onResponseOK: { viewModel.handleDirectPaymentResponseOK() },
                        onResponseCancel: { viewModel.handleDirectPaymentCancel() }
                    )
                }
            }
        }
    }

    // MARK: - Amount Selection

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Amount")
                .font(.headline)

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading options...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.topUpValues.isEmpty && !viewModel.allowCustomAmount {
                Text("No top-up amounts available")
                    .foregroundStyle(.secondary)
            } else {
                // Preset amounts as horizontal chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.topUpValues) { value in
                            amountChip(value)
                        }
                        if viewModel.allowCustomAmount {
                            customChip
                        }
                    }
                }

                // Custom amount editor (shown when custom is selected)
                if viewModel.isCustomAmountMode {
                    customAmountEditor
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Punch reward summary
                if let amount = viewModel.effectiveSelectedAmount,
                   let punches = amount.punchReward, punches > 0 {
                    Label("+\(punches) punches", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func amountChip(_ value: TopUpValue) -> some View {
        let isSelected = !viewModel.isCustomAmountMode && viewModel.selectedAmount?.id == value.id
        return Button {
            withAnimation(.snappy(duration: 0.2)) { viewModel.selectPreset(value) }
        } label: {
            Text("\(Int(value.amount)) \(value.currency)")
                .font(.body)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var customChip: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { viewModel.selectCustom() }
        } label: {
            Label("Custom", systemImage: "pencil")
                .font(.body)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(viewModel.isCustomAmountMode ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(viewModel.isCustomAmountMode ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var customAmountEditor: some View {
        VStack(spacing: 10) {
            #if DEBUG
            // Debug: free-form text input, no restrictions
            HStack(spacing: 0) {
                Text(viewModel.topUpCurrency)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)

                TextField("0", text: $viewModel.customAmountText)
                    .keyboardType(.numberPad)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
            }
            .padding(4)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )

            if viewModel.customAmount > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.customAmountFollowsIncrements ? .green : .orange)
                        .frame(width: 6, height: 6)
                    Text(viewModel.customAmountFollowsIncrements
                         ? "Follows 50 kr increments"
                         : "Does not follow 50 kr increments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            #else
            // Release: stepper locked to 50kr increments
            HStack {
                Button {
                    withAnimation { viewModel.decrementCustomAmount() }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(viewModel.customAmount > viewModel.customAmountMinimum
                                         ? Color.accentColor : Color(.systemGray4))
                }
                .disabled(viewModel.customAmount <= viewModel.customAmountMinimum)

                Spacer()

                Text("\(Int(viewModel.customAmount)) \(viewModel.topUpCurrency)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    withAnimation { viewModel.incrementCustomAmount() }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            #endif
        }
    }

    // MARK: - Payment Method Selection

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)

            if viewModel.creditCards.isEmpty && !viewModel.isSwishAvailable && !viewModel.hasDirectPaymentMethods {
                Text("No payment methods available")
                    .foregroundStyle(.secondary)
            } else {
                // Credit cards
                ForEach(viewModel.creditCards) { card in
                    let isSelected = viewModel.selectedCard?.id == card.id
                    Button {
                        withAnimation { viewModel.selectedCard = card }
                    } label: {
                        HStack {
                            Image(systemName: card.iconName)
                                .font(.title2)
                                .foregroundStyle(.primary)
                                .frame(width: 36)

                            VStack(alignment: .leading) {
                                Text(card.displayLabel)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                if let expiry = card.expiryDate {
                                    Text("Expires \(expiry)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color(.systemGray4))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Swish / Direct Payment methods
                if viewModel.isSwishAvailable || viewModel.hasDirectPaymentMethods {
                    let pspDisabled = viewModel.effectiveSelectedAmount == nil || viewModel.isProcessing
                    let firstDirect = viewModel.directPaymentMethods.first

                    Divider()

                    // Swish + first direct method side-by-side if both exist
                    if viewModel.isSwishAvailable, let method = firstDirect {
                        HStack(spacing: 10) {
                            swishButton(disabled: pspDisabled)
                            directPaymentButton(method: method, disabled: pspDisabled)
                        }
                    } else if viewModel.isSwishAvailable {
                        swishButton(disabled: pspDisabled)
                    } else if let method = firstDirect {
                        directPaymentButton(method: method, disabled: pspDisabled)
                    }

                    // Any additional direct payment methods below
                    ForEach(viewModel.directPaymentMethods.dropFirst(), id: \.methodKey) { method in
                        directPaymentButton(method: method, disabled: pspDisabled)
                    }
                }
            }
        }
    }

    private func swishButton(disabled: Bool) -> some View {
        Button {
            Task { await viewModel.topUpWithSwish(topUpService: topUpService) }
        } label: {
            Image("SwishSecondary")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .environment(\.colorScheme, .light)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
                .opacity(disabled ? 0.4 : 1)
        }
        .disabled(disabled)
    }

    private func directPaymentButton(method: DirectPaymentMethod, disabled: Bool) -> some View {
        Button {
            Task { await viewModel.topUpWithDirectPayment(method: method, topUpService: topUpService) }
        } label: {
            directPaymentButtonLabel(for: method)
                .opacity(disabled ? 0.4 : 1)
        }
        .disabled(disabled)
    }

    @ViewBuilder
    private func directPaymentButtonLabel(for method: DirectPaymentMethod) -> some View {
        let name = (method.displayName ?? method.methodKey ?? "").lowercased()
        if name.contains("paypal") {
            Image("PayPal")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 248/255, green: 213/255, blue: 98/255))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Text(method.displayName ?? method.methodKey ?? "Pay")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Top Up Button

    private var topUpButton: some View {
        let amount = viewModel.effectiveSelectedAmount
        let canTopUp = amount != nil && viewModel.selectedCard != nil && !viewModel.isProcessing

        return Button {
            Task { await viewModel.topUpWithCard(topUpService: topUpService) }
        } label: {
            Group {
                if viewModel.isProcessing {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Processing...")
                    }
                } else if let amount {
                    Text("Top Up \(Int(amount.amount)) \(amount.currency)")
                } else {
                    Text("Select an amount")
                }
            }
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canTopUp ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding()
        }
        .disabled(!canTopUp)
    }
}
