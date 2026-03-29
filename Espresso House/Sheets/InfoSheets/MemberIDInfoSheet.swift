//
//  MemberIDInfoSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct MemberIDInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Member ID")
                .font(.headline)

            Text("Scan in our coffee shops to pay with your Coffee Card, redeem coupons, and collect Fika Points.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical)
        .presentationDetents([.fraction(0.2), .medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("")
        .sheet(isPresented: .constant(true)) {
            MemberIDInfoSheet()
        }
}
