//
//  CoffeeCardInfoSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct CoffeeCardInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coffee Card")
                .font(.headline)
                .frame(maxWidth: .infinity)

            Text("Top up your Coffee Card and get Fika Points as a reward. Read more about how to collect points in Fika House.")
                .foregroundStyle(.secondary)

            Text("Minimum Deposit: 100 kr")
                .fontWeight(.medium)
        }
        .padding(.horizontal, 24)
        .padding(.vertical)
        .presentationDetents([.fraction(0.25), .medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("")
        .sheet(isPresented: .constant(true)) {
            CoffeeCardInfoSheet()
        }
}
