//
//  WalletView.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct WalletView: View {
    @StateObject var viewModel: WalletViewModel = WalletViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Text("Wallet")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                MemberID(id: SharedVars.shared.memberId ?? "")
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.secondary.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.horizontal)
                
                CoffeeCard()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal)
                
                NavigationLink {
                    FikaHouseView()
                } label: {
                    FikaClubCard(fikaPoints: $viewModel.points)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    WalletView()
}
