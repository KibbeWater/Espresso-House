//
//  MemberIDInfoSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct MemberIDInfoSheet: View {
    @Binding var isPresented: Bool
    
    func bold(_ text: String) -> Text {
        Text(text)
            .fontWeight(.semibold)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader("Member ID", isPresented: $isPresented)
            
            Text("Scan in our coffee shops to pay with your Coffee Card, redeem coupons, and collect Fika Points.")
                .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    MemberIDInfoSheet(isPresented: .constant(true))
}
