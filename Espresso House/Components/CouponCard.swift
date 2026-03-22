//
//  CouponCard.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import SwiftUI
import Kingfisher

struct CouponCard: View {
    let coupon: Coupon
    
    var body: some View {
        VStack {
            KFImage(coupon.imageURL)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(coupon.heading)
                        .font(.headline)
                    Text("Expires in \(coupon.daysRemaining) days")
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            HStack {
                HStack {
                    Text("More info")
                    Image(systemName: "info.circle")
                }
                .foregroundStyle(.accent)
                
                Spacer()
                
                Button("Activate") {
                    print("Activated coupon: \(coupon.id)")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CouponCard(coupon: Coupon(
            id: "123456789",
            redeemed: false,
            validFrom: .distantPast,
            validTo: .distantFuture,
            daysRemaining: 12,
            heading: "20% off Cinnamon Bun Latte",
            description: "123",
            longDescription: "123",
            imageURL: URL(string: "https://myespressohouse.azureedge.net/images/a4cd4a96-c9a1-4893-b401-b34b09280491.jpg")!
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.secondary.opacity(0.3), lineWidth: 2)
        )
    .padding()
    
}
