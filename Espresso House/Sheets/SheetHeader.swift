//
//  SheetHeader.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI

struct SheetHeader: View {
    @Binding var isPresented: Bool
    let title: String
    
    init(_ title: String, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.title = title
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            Text(title)
                .fontWeight(.semibold)
            Spacer()
        }
        .frame(height: 50)
        .overlay(alignment: .trailing) {
            Button("Done") {
                isPresented.toggle()
            }
            .fontWeight(.medium)
            .padding(.trailing)
        }
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 0) {
            SheetHeader("My ID", isPresented: .constant(true))
            ScrollView {
                
            }
            .background(.primary)
        }
    }
}
