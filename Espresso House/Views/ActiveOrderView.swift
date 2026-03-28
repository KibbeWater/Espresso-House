//
//  ActiveOrderView.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import SwiftUI

struct ActiveOrderView: View {
    @Environment(\.espressoAPI) private var api
    @Environment(\.dismiss) private var dismiss

    @Environment(\.activeOrderVM) private var viewModel

    private var orderService: any OrderServiceProtocol {
        #if DEBUG
        if DebugSettings.shared.isSimulating {
            return MockOrderService()
        }
        #endif
        return api.order
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                if let order = viewModel.latestOrder {
                    // Success header
                    successHeader(for: order)

                    // Progress tracker
                    orderProgressView(for: order)

                    // Order details
                    orderDetailsView(for: order)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No active orders")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                }
            }
            .padding()
        }
        .navigationTitle("Order Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.startPolling(api: orderService)
        }
    }

    // MARK: - Components

    private func isOrderReady(_ order: ActiveOrder) -> Bool {
        let s = order.status?.lowercased() ?? ""
        return s.contains("ready") || s.contains("delivered") || s.contains("completed") || s.contains("pickup")
    }

    @ViewBuilder
    private func successHeader(for order: ActiveOrder) -> some View {
        VStack(spacing: 12) {
            let ready = isOrderReady(order)

            Image(systemName: ready ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 56))
                .foregroundStyle(ready ? .green : Color.accentColor)
                .symbolEffect(.bounce, value: ready)

            Text(ready ? "Your order is ready!" : "Order placed!")
                .font(.title2)
                .fontWeight(.bold)

            if let orderNumber = order.orderNumber {
                Text("Order #\(orderNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let pin = order.orderPinCode {
                Text("PIN: \(pin)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private func orderProgressView(for order: ActiveOrder) -> some View {
        let status = order.status?.lowercased() ?? ""
        let isDelivered = status.contains("delivered") || status.contains("completed")
        let isReady = status.contains("ready") || status.contains("pickup") || isDelivered
        let isPreparing = status.contains("preparing") || status.contains("inprogress") || isReady
        let steps: [(String, String, Bool)] = [
            ("Placed", "checkmark.circle.fill", true),
            ("Preparing", "flame.fill", isPreparing),
            ("Ready", "cup.and.saucer.fill", isReady),
        ]

        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(step.2 ? Color.accentColor : Color(.systemGray4))
                            .frame(width: 36, height: 36)

                        Image(systemName: step.1)
                            .font(.system(size: 16))
                            .foregroundColor(step.2 ? .white : .secondary)
                    }

                    Text(step.0)
                        .fontWeight(step.2 ? .semibold : .regular)
                        .foregroundStyle(step.2 ? .primary : .secondary)

                    Spacer()
                }

                if index < steps.count - 1 {
                    HStack {
                        Rectangle()
                            .fill(steps[index + 1].2 ? Color.accentColor : Color(.systemGray4))
                            .frame(width: 2, height: 24)
                            .padding(.leading, 17)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func orderDetailsView(for order: ActiveOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Details")
                .font(.headline)

            if let shopName = order.shopName {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(shopName)
                }
            }

            if let configs = order.configurations {
                ForEach(configs) { config in
                    HStack {
                        Text(config.articleName ?? "Item")
                        if let size = config.navName {
                            Text("(\(size))")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }

            if let total = order.totalAmount {
                Divider()
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(Int(total)) \(order.currency ?? "SEK")")
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
