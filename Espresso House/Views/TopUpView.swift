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

                        // Amount selection
                        amountSection

                        Divider()

                        // Payment method
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
                        Spacer()
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
            } else if viewModel.topUpValues.isEmpty {
                Text("No top-up amounts available")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.topUpValues) { value in
                        Button {
                            withAnimation { viewModel.selectedAmount = value }
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(Int(value.amount)) \(value.currency)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                if let punches = value.punchReward, punches > 0 {
                                    Text("+\(punches) punches")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                viewModel.selectedAmount?.id == value.id
                                    ? Color.accentColor.opacity(0.12)
                                    : Color(.systemGray6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        viewModel.selectedAmount?.id == value.id
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Payment Method Selection

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)

            if viewModel.creditCards.isEmpty && !viewModel.isSwishAvailable {
                Text("No payment methods available")
                    .foregroundStyle(.secondary)
            } else {
                // Credit cards
                ForEach(viewModel.creditCards) { card in
                    Button {
                        withAnimation { viewModel.selectedCard = card }
                    } label: {
                        HStack {
                            Image(systemName: card.iconName)
                                .font(.title2)
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

                            if viewModel.selectedCard?.id == card.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            viewModel.selectedCard?.id == card.id
                                ? Color.accentColor.opacity(0.08)
                                : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Swish option
                if viewModel.isSwishAvailable {
                    Divider()

                    Button {
                        Task { await viewModel.topUpWithSwish(topUpService: topUpService) }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.arrow.left.circle.fill")
                                .font(.title2)
                                .frame(width: 36)

                            Text("Pay with Swish")
                                .fontWeight(.medium)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.selectedAmount == nil || viewModel.isProcessing)
                }
            }
        }
    }

    // MARK: - Top Up Button

    private var topUpButton: some View {
        Button {
            Task { await viewModel.topUpWithCard(topUpService: topUpService) }
        } label: {
            Group {
                if viewModel.isProcessing {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Processing...")
                    }
                } else if let amount = viewModel.selectedAmount {
                    Text("Top Up \(Int(amount.amount)) \(amount.currency)")
                } else {
                    Text("Select an amount")
                }
            }
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.selectedAmount != nil && viewModel.selectedCard != nil && !viewModel.isProcessing
                    ? Color.accentColor
                    : Color.gray
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding()
        }
        .disabled(viewModel.selectedAmount == nil || viewModel.selectedCard == nil || viewModel.isProcessing)
    }
}
