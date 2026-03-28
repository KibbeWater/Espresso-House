//
//  FikaOffersCard.swift
//  Espresso House
//

import SwiftUI

struct FikaOffersCard: View {
    let couponCount: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "ticket")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Fika Offers (\(couponCount))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("View your Fika Offers ›")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
