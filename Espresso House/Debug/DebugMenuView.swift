//
//  DebugMenuView.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var activeOrderVM: ActiveOrderViewModel

    @State private var debugSettings = DebugSettings.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Order Simulation") {
                    Toggle("Simulate Order Flow", isOn: $debugSettings.isSimulating)

                    if debugSettings.isSimulating {
                        Text("When enabled, the checkout flow uses mock data instead of real API calls. An orange banner will be shown.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Force Order Status") {
                    let statuses = ["Created", "Preparing", "Ready", "Completed"]
                    ForEach(statuses, id: \.self) { status in
                        Button {
                            debugSettings.mockOrderStatus = status

                            // Update or create mock order with stable key
                            let mockOrder = ActiveOrder(
                                digitalOrderKey: "debug-forced-order",
                                orderNumber: 4242,
                                shopNumber: "322",
                                orderStatus: status,
                                orderTotal: 49,
                                orderGrossTotal: 49,
                                currencyCode: "SEK",
                                orderCreated: ISO8601DateFormatter().string(from: Date()),
                                orderLastUpdated: nil,
                                orderFullyPaid: nil,
                                estimatedPickupTime: nil,
                                orderType: "PreOrderTakeAway",
                                customerDisplayName: "Debug",
                                orderPinCode: "0000",
                                shopInformation: ActiveOrder.ShopInfo(shopNumber: 322, shopName: "Debug Espresso House", address1: nil, city: nil),
                                configurations: [
                                    OrderConfiguration(articleNumber: "DBG-001", articleName: "Debug Latte", img: nil, navName: "Standard", shortDescription: nil)
                                ]
                            )
                            activeOrderVM.setMockOrder(mockOrder)
                        } label: {
                            HStack {
                                Text(status)
                                Spacer()
                                if debugSettings.mockOrderStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }

                Section("Actions") {
                    Button("Clear Active Orders") {
                        activeOrderVM.activeOrders.removeAll()
                        activeOrderVM.stopPolling()
                    }

                    Button("Reset Simulation") {
                        debugSettings.isSimulating = false
                        debugSettings.mockOrderStatus = "Created"
                        activeOrderVM.activeOrders.removeAll()
                        activeOrderVM.stopPolling()
                    }
                    .foregroundStyle(.red)
                }

                Section("Info") {
                    LabeledContent("Member ID", value: SharedVars.shared.memberId ?? "Not logged in")
                    LabeledContent("Active Orders", value: "\(activeOrderVM.activeOrders.count)")
                    LabeledContent("Is Polling", value: activeOrderVM.isPolling ? "Yes" : "No")
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif
