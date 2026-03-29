//
//  ProductCard.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import SwiftUI
import Kingfisher

struct ProductCard: View {
    let product: ShopMasterProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack {
                Spacer()
                if let _url = product.image,
                   let url = URL(string: _url) {
                    KFImage(url)
                        .placeholder {
                            ProgressView()
                        }
                        .setProcessor(
                            DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))
                        )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "cup.and.saucer")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .frame(width: 172, height: 132)
            .background(Color(.systemGray6))

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let price = product.displayPrice, price > 0 {
                    Text("from \(Int(price)) \(product.currency)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 172)
    }
}

#Preview {
    ProductCard(
        product: ShopMasterProduct(
            name: "Breakfast",
            image: "https://pim-espressohouse.azureedge.net/Products/LTO/2024/BLOCK%201/BUNDLES/BBUNDLE_BREAKFAST_LATTE_TOAST_MULTIGRAIN_EGG_BACON_DE.png",
            menuTags: [],
            configurations: []
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .overlay(
        RoundedRectangle(cornerRadius: 24)
            .stroke(.secondary.opacity(0.3), lineWidth: 1)
    )
}
