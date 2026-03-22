//
//  ProductCard.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import SwiftUI
import Kingfisher

struct ProductCard: View {
    let product: MenuProduct
    
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
                    Image("cross")
                }
                Spacer()
            }
            .frame(width: 172, height: 132)
            .background(.background.opacity(0.2))
            
            VStack(alignment: .leading) {
                Text(product.name)
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Text("32kr")
                    .foregroundStyle(.primary)
            }
            .padding(.leading)
            .padding(.vertical, 8)
        }
        .frame(width: 172)
    }
}

#Preview {
    ProductCard(
        product: MenuProduct(
            name: "Breakfast",
            image: "https://pim-espressohouse.azureedge.net/Products/LTO/2024/BLOCK%201/BUNDLES/BBUNDLE_BREAKFAST_LATTE_TOAST_MULTIGRAIN_EGG_BACON_DE.png",
            menuTags: [],
            defaultArticleNumber: "hello"
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .overlay(
        RoundedRectangle(cornerRadius: 24)
            .stroke(.secondary.opacity(0.3), lineWidth: 1)
    )
}
