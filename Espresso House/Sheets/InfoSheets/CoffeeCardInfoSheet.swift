//
//  CoffeeCardInfoSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 10/12/24.
//

import SwiftUI

struct CoffeeCardInfoSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader("Coffee Card", isPresented: $isPresented)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Top up your Coffee Card and get Fika Points as a reward. Read more about how to collect points in Fika House")
                
                Text("Minimum Deposit: 100 kr")
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    CoffeeCardInfoSheet(isPresented: .constant(true))
}
