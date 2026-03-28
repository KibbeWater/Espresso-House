//
//  PaymentCardsView.swift
//  Espresso House
//

import SwiftUI

struct PaymentCardsView: View {
    @Environment(\.espressoAPI) private var api
    @State private var cards: [PaymentOption] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var isPolling = false

    /// Polling task stored at module level so it survives NavigationStack resets
    private static var pollingTask: Task<Void, Never>?

    var body: some View {
        List {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading cards...")
                        .foregroundStyle(.secondary)
                }
            } else if cards.isEmpty {
                Text("No saved payment cards")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(cards) { card in
                    HStack {
                        Image(systemName: card.iconName)
                            .font(.title2)
                            .frame(width: 36)

                        VStack(alignment: .leading) {
                            Text(card.displayLabel)
                                .fontWeight(.medium)
                            if let expiry = card.expiryDate {
                                Text("Expires \(expiry)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            Task { await setPreferred(card) }
                        } label: {
                            if cards.first?.id == card.id {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            } else {
                                Image(systemName: "star")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete(perform: deleteCards)
            }

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Section {
                Button {
                    Task { await startAddCard() }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Payment Card")
                    }
                }
                .disabled(isPolling)

                if isPolling {
                    HStack {
                        ProgressView()
                        Text("Waiting for card verification...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Payment Cards")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Check if polling is still running (e.g. after nav stack reset)
            if Self.pollingTask != nil && !Self.pollingTask!.isCancelled {
                isPolling = true
            }
            Task { await loadCards() }
        }
    }

    // MARK: - Actions

    private func loadCards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let allOptions = try await api.order.getPaymentOptions()
            cards = allOptions.filter { !$0.isCoffeeCard }
        } catch {
            self.error = "Failed to load cards: \(error.localizedDescription)"
        }
    }

    private func startAddCard() async {
        error = nil
        do {
            let urlString = try await api.member.getCardRegistrationURL()
            guard let url = URL(string: urlString) else { return }

            SafariPresenter.shared.present(url: url, onSuccess: { [self] in
                startPolling()
            })
        } catch {
            self.error = "Failed to get registration URL: \(error.localizedDescription)"
        }
    }

    private func startPolling() {
        Self.pollingTask?.cancel()
        isPolling = true
        error = nil

        let topUpService = api.topUp
        Self.pollingTask = Task {
            defer {
                Task { @MainActor in
                    Self.pollingTask = nil
                }
            }

            do {
                let poller = EventPoller(topUpService: topUpService)
                let event = try await poller.pollForEvent(
                    expectedType: "PaymentCardVerified",
                    failureTypes: ["PaymentCardRegistrationFailed"]
                )
                print("[PaymentCards] Card verified: \(event.eventType)")
                await MainActor.run {
                    SafariPresenter.shared.dismiss()
                    isPolling = false
                }
                await loadCards()
            } catch is CancellationError {
                // Ignore
            } catch EventPollerError.timeout {
                await MainActor.run {
                    isPolling = false
                    self.error = "Verification timed out. If you completed card entry, try refreshing."
                }
            } catch {
                await MainActor.run {
                    isPolling = false
                    self.error = "Card verification: \(error.localizedDescription)"
                }
            }
        }
    }

    private func setPreferred(_ card: PaymentOption) async {
        error = nil
        do {
            try await api.member.setPreferredPaymentToken(tokenKey: card.paymentIdentifier)
            await loadCards()
        } catch {
            self.error = "Failed to set preferred: \(error.localizedDescription)"
        }
    }

    private func deleteCards(at offsets: IndexSet) {
        let toDelete = offsets.map { cards[$0] }
        for card in toDelete {
            Task {
                do {
                    try await api.member.deletePaymentToken(tokenKey: card.paymentIdentifier)
                    await MainActor.run { cards.removeAll { $0.id == card.id } }
                } catch {
                    await MainActor.run { self.error = "Failed to delete: \(error.localizedDescription)" }
                }
            }
        }
    }
}
