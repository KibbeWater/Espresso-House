//
//  CoffeeCard.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct CoffeeCard: View {
    var balance: Balance?
    var onTopUp: (() -> Void)?

    @State private var showInfo = false

    var body: some View {
        VStack {
            Text("\(Int(balance?.amount ?? 0)) \(balance?.currency ?? "kr")")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Coffee card balance")
                .font(.title3)
                .fontWeight(.medium)
            Button("Top up") {
                onTopUp?()
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(.secondaryAccent)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(Color(uiColor: UIColor.systemBackground))
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 152)
        .padding(.vertical)
        .overlay(alignment: .topTrailing, content: {
            Button {
                showInfo.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text("info")
                    Image(systemName: "info.circle")
                }
            }
            .padding()
            .foregroundStyle(.secondaryAccent)
            .sheet(isPresented: $showInfo) {
                CoffeeCardInfoSheet()
            }
        })
        .background(Color.secondaryAccent.opacity(0.3))
    }
}

#Preview {
    VStack {
        Spacer()
        
        CoffeeCard(balance: Balance(amount: 450, currency: "SEK", countryCode: "SE"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding()

        Spacer()

        CoffeeCard(balance: nil)
        
        Spacer()
    }
}
