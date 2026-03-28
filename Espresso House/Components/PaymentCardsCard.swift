//
//  PaymentCardsCard.swift
//  Espresso House
//

import SwiftUI

struct PaymentCardsCard: View {
    let cards: [PaymentOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 14) {
                Image(systemName: "creditcard")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 48, height: 48)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment cards")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Manage payment cards ›")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }

                Spacer()
            }
            .padding()

            // Card list
            if !cards.isEmpty {
                ForEach(cards) { card in
                    Divider()
                        .padding(.leading)
                    HStack {
                        Text(card.displayLabel)
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}
