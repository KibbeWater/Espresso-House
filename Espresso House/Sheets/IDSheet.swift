//
//  IDSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI

struct IDSheet: View {
    @Environment(\.dismiss) private var dismiss
    var balance: Balance?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MemberID(id: SharedVars.shared.memberId ?? "")
                    .background(Color(uiColor: UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                CoffeeCard(balance: balance)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal)
            }
            .padding(.top, 8)
        }
        .navigationTitle("My ID")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        IDSheet(balance: Balance(amount: 450, currency: "SEK", countryCode: "SE"))
    }
}
