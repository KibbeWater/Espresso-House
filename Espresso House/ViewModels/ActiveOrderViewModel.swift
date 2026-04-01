//
//  ActiveOrderViewModel.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation
import UIKit

@Observable
class ActiveOrderViewModel {
    var activeOrders: [ActiveOrder] = []
    var isPolling = false
    private var pollingTask: Task<Void, Never>?
    private var notifiedOrderKeys: Set<String> = []

    var hasActiveOrder: Bool {
        !activeOrders.isEmpty
    }

    var latestOrder: ActiveOrder? {
        activeOrders.first
    }

    func startPolling(api: any OrderServiceProtocol) {
        guard !isPolling else { return }
        isPolling = true

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchOrders(api: api)
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    func stopPolling() {
        isPolling = false
        pollingTask?.cancel()
        pollingTask = nil
    }

    func fetchOrders(api: any OrderServiceProtocol) async {
        do {
            let orders = try await api.getActiveOrders()
            await MainActor.run {
                let previousStatuses: [String: String] = Dictionary(
                    uniqueKeysWithValues: self.activeOrders.compactMap { order in
                        guard let status = order.status else { return nil }
                        return (order.digitalOrderKey, status)
                    }
                )
                self.activeOrders = orders

                // Check for newly ready orders and trigger haptic
                for order in orders {
                    let isReady = order.status == "ReadyForPickup" || order.status == "Delivered"
                    let prev = previousStatuses[order.digitalOrderKey]
                    let wasNotReady = prev != "ReadyForPickup" && prev != "Delivered"
                    let notYetNotified = !self.notifiedOrderKeys.contains(order.digitalOrderKey)

                    if isReady && (wasNotReady || notYetNotified) && notYetNotified {
                        self.notifiedOrderKeys.insert(order.digitalOrderKey)
                        self.playOrderReadyHaptic()
                    }
                }
            }
        } catch {
            print("[ActiveOrderVM] Polling error: \(error)")
        }
    }

    func clearCompletedOrders() {
        activeOrders.removeAll { order in
            order.status == "Delivered"
        }
        if activeOrders.isEmpty {
            stopPolling()
        }
    }

    /// Plays a prominent haptic burst pattern to grab attention
    private func playOrderReadyHaptic() {
        Task {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.prepare()

            // Three heavy buzzes with short pauses — noticeable even face-down
            heavy.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(150))
            heavy.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(150))
            heavy.impactOccurred(intensity: 1.0)

            try? await Task.sleep(for: .milliseconds(400))

            // Finish with a success notification for the distinct "done" feel
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    // For debug: set/replace a mock order (uses digitalOrderKey to find existing)
    func setMockOrder(_ order: ActiveOrder) {
        if let index = activeOrders.firstIndex(where: { $0.digitalOrderKey == order.digitalOrderKey }) {
            activeOrders[index] = order
        } else {
            activeOrders.insert(order, at: 0)
        }
    }
}
