//
//  ProductSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 20/12/24.
//

import SwiftUI

struct ProductSheet: View {
    let product: MenuProduct
    let callback: () -> Void
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            // ProductSheet(product: <#T##MenuProduct#>, callback: <#T##() -> Void#>)
        }
}
