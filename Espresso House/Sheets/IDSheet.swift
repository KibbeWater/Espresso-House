//
//  IDSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI

struct IDSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader("My ID", isPresented: $isPresented)
            ScrollView {
                VStack(spacing: 12) {
                    MemberID(id: SharedVars.shared.memberId ?? "")
                        .background(Color(uiColor: UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.secondary.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal)
                        // .shadow(radius: 6, x: 5, y: 5)
                        .padding(.top)
                    
                    CoffeeCard()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding()
                }
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        IDSheet(isPresented: .constant(true))
    }
}
