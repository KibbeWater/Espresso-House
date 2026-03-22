//
//  CoffeeCard.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct CoffeeCard: View {
    @State private var showInfo = false
    
    var body: some View {
        VStack {
            Text("0 kr")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Coffe card balance")
                .font(.title3)
                .fontWeight(.medium)
            Button("Top up") {
                
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
                MemberIDInfoSheet(isPresented: $showInfo)
                    .presentationDetents([.fraction(0.15), .medium])
            }
        })
        .background(Color.secondaryAccent.opacity(0.3))
    }
}

#Preview {
    VStack {
        Spacer()
        
        CoffeeCard()
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding()
        
        Spacer()
        
        CoffeeCard()
        
        Spacer()
    }
}
