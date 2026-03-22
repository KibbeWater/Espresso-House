//
//  FikaClubCard.swift
//  Espresso House
//
//  Created by KibbeWater on 9/12/24.
//

import SwiftUI

struct FikaClubCard: View {
    @Binding public var fikaPoints: Int
    
    var body: some View {
        VStack(spacing:0) {
            HStack {
                HStack {}
                    .frame(width: 48)
                    .background(.red)
                Text("Fika Points")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }
            
            HStack(alignment: .top) {
                Text("\(fikaPoints)")
                    .font(.system(size: 64))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 48)
                Text("Choose your rewards in\nFika House")
                    .font(.system(size: 18))
                    .fontWeight(.medium)
                    .padding(.top, 12)
                    .fixedSize()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            HStack {
                HStack {
                    Text("Fika House")
                    Image(systemName: "arrow.right")
                }
                .fontWeight(.semibold)
                .padding(.leading)
                
                Spacer()
            }
            
        }
        .padding(12)
        .background(Color.background.opacity(0.4))
    }
}

#Preview {
    VStack {
        FikaClubCard(fikaPoints: .constant(5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        
        Spacer()

        NavigationLink {
            EmptyView()
        } label: {
            FikaClubCard(fikaPoints: .constant(5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
        }
        .foregroundColor(.primary)
        .padding(.horizontal)
        
        Spacer()
        
        FikaClubCard(fikaPoints: .constant(5))
    }
}
