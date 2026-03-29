//
//  ProductSheet.swift
//  Espresso House
//
//  Created by KibbeWater on 20/12/24.
//

import SwiftUI
import Kingfisher

struct ProductSheet: View {
    let masterProduct: ShopMasterProduct
    @Bindable var cart: CartViewModel

    @Environment(\.espressoAPI) private var api
    @Environment(\.dismiss) private var dismiss

    @State private var selectedConfigIndex: Int = 0
    @State private var upsellSelections: [String: Bool] = [:]
    @State private var levelSelections: [Int: String] = [:] // levelNumber -> selected articleNumber
    @State private var quantity: Int = 1
    @State private var detailedConfigs: [ShopProduct]? = nil
    @State private var isLoadingConfig: Bool = false

    private var orderService: any OrderServiceProtocol {
        #if DEBUG
        if DebugSettings.shared.isSimulating {
            return MockOrderService.shared
        }
        #endif
        return api.order
    }

    private var configurations: [ShopProduct] {
        detailedConfigs ?? masterProduct.configurations
    }

    private var selectedConfig: ShopProduct {
        guard selectedConfigIndex < configurations.count else {
            return configurations[0]
        }
        return configurations[selectedConfigIndex]
    }

    private var basePrice: Double {
        selectedConfig.price ?? 0
    }

    private var upsellTotal: Double {
        guard let upsells = selectedConfig.upsell else { return 0 }
        return upsells.reduce(0) { total, upsell in
            let isSelected = upsellSelections[upsell.articleNumber] ?? upsell.selected
            if isSelected && upsell.isAffectingPrice {
                return total + upsell.price * Double(upsell.quantity ?? 1)
            }
            return total
        }
    }

    private var totalPrice: Double {
        (basePrice + upsellTotal) * Double(quantity)
    }

    private var currency: String {
        selectedConfig.currency ?? "SEK"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero image
                    productImage
                        .overlay(alignment: .topTrailing) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, height: 30)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(12)
                        }

                    VStack(alignment: .leading, spacing: 16) {
                        // Name & description
                        productInfo

                        // Size picker (if multiple configurations)
                        if configurations.count > 1 {
                            sizePicker
                        }

                        if isLoadingConfig {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text("Loading options...")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 24)
                        } else {
                            // Customization levels
                            customizationLevels

                            // Upsell options
                            upsellOptions
                        }

                        // Quantity
                        quantityPicker
                    }
                    .padding()
                }
            }
            .safeAreaInset(edge: .bottom) {
                addToCartButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                Task {
                    await loadArticleConfigurations()
                }
            }
        }
    }

    private func loadArticleConfigurations() async {
        let articleNumbers = masterProduct.articles.map { $0.articleNumber }
        guard !articleNumbers.isEmpty else { return }

        isLoadingConfig = true
        defer { isLoadingConfig = false }

        do {
            let configs = try await orderService.getArticleConfigurations(
                shopNumber: String(cart.shop.id),
                articleNumbers: articleNumbers
            )
            if !configs.isEmpty {
                // Merge: keep prices from menu articles, overlay config data
                detailedConfigs = masterProduct.articles.map { article in
                    if let config = configs.first(where: { $0.articleNumber == article.articleNumber }) {
                        return ShopProduct(
                            articleNumber: config.articleNumber,
                            articleName: masterProduct.name,
                            img: config.img ?? masterProduct.image,
                            description: config.description,
                            shortDescription: config.shortDescription,
                            navName: config.navName ?? article.navigationName,
                            outOfStock: config.outOfStock,
                            icon: config.icon ?? article.navigationIcon,
                            iconSelected: config.iconSelected,
                            articleUrl: config.articleUrl,
                            isComplexConfiguration: config.isComplexConfiguration,
                            price: article.price?.amount ?? config.price,
                            currency: article.price?.currencyCode ?? config.currency,
                            levels: config.levels,
                            upsell: config.upsell,
                            extraChoices: config.extraChoices
                        )
                    } else {
                        // No config found for this article, use the basic one
                        return masterProduct.configurations.first(where: { $0.articleNumber == article.articleNumber })
                            ?? masterProduct.configurations[0]
                    }
                }
                print("[ProductSheet] Loaded \(configs.count) configurations, upsells: \(configs.filter { $0.upsell != nil }.count)")
            }
        } catch {
            print("[ProductSheet] Failed to load configurations: \(error)")
            // Fall back to basic configurations from menu
        }
    }

    // MARK: - Components

    private var productImage: some View {
        Group {
            let imgUrl = selectedConfig.img ?? masterProduct.image
            if let urlStr = imgUrl, let url = URL(string: urlStr) {
                KFImage(url)
                    .placeholder { ProgressView() }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedConfig.articleName)
                .font(.title2)
                .fontWeight(.bold)

            if let desc = selectedConfig.description ?? selectedConfig.shortDescription, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if basePrice > 0 {
                Text("\(Int(basePrice)) \(currency)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Size")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(Array(configurations.enumerated()), id: \.element.id) { index, config in
                    Button {
                        withAnimation {
                            selectedConfigIndex = index
                            // Reset upsell selections for new config
                            upsellSelections.removeAll()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(config.navName ?? "Standard")
                                .fontWeight(selectedConfigIndex == index ? .bold : .regular)
                            if let price = config.price, price > 0 {
                                Text("\(Int(price)) \(config.currency ?? currency)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedConfigIndex == index ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                        .foregroundStyle(selectedConfigIndex == index ? Color.accentColor : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedConfigIndex == index ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                    .disabled(config.outOfStock)
                    .opacity(config.outOfStock ? 0.4 : 1)
                }
            }
        }
    }

    private var customizationLevels: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(selectedConfig.levels, id: \.levelNumber) { level in
                if !level.rows.isEmpty && level.customerMustSelect {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(levelTitle(for: level))
                            .font(.headline)

                        ForEach(level.rows) { row in
                            Button {
                                withAnimation {
                                    levelSelections[level.levelNumber] = row.articleNumber
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: symbolForItem(row.articleName))
                                        .font(.system(size: 18))
                                        .foregroundStyle(isRowSelected(row, in: level) ? Color.accentColor : .secondary)
                                        .frame(width: 28)

                                    Text(row.articleName)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Image(systemName: isRowSelected(row, in: level) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isRowSelected(row, in: level) ? Color.accentColor : .secondary)
                                        .font(.title3)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(isRowSelected(row, in: level) ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(row.outOfStock)
                            .opacity(row.outOfStock ? 0.4 : 1)
                        }
                    }
                }
            }
        }
    }

    private var upsellOptions: some View {
        Group {
            if let upsells = selectedConfig.upsell, !upsells.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extras")
                        .font(.headline)

                    ForEach(upsells) { upsell in
                        Button {
                            let current = upsellSelections[upsell.articleNumber] ?? upsell.selected
                            upsellSelections[upsell.articleNumber] = !current
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: symbolForItem(upsell.articleName))
                                    .font(.system(size: 18))
                                    .foregroundStyle(isUpsellSelected(upsell) ? Color.accentColor : .secondary)
                                    .frame(width: 28)

                                VStack(alignment: .leading) {
                                    Text(upsell.articleName)
                                        .foregroundStyle(.primary)
                                    if upsell.isAffectingPrice {
                                        Text("+\(Int(upsell.price)) \(upsell.currency)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: isUpsellSelected(upsell) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(isUpsellSelected(upsell) ? Color.accentColor : .secondary)
                                    .font(.title3)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(isUpsellSelected(upsell) ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(upsell.outOfStock)
                        .opacity(upsell.outOfStock ? 0.4 : 1)
                    }
                }
            }
        }
    }

    private var quantityPicker: some View {
        HStack {
            Text("Quantity")
                .font(.headline)
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if quantity > 1 { quantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(quantity > 1 ? Color.accentColor : .secondary)
                }
                .disabled(quantity <= 1)

                Text("\(quantity)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(minWidth: 30)

                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private var addToCartButton: some View {
        Button {
            var configuredProduct = selectedConfig
            // Apply upsell selections
            if var upsells = configuredProduct.upsell {
                for i in upsells.indices {
                    if let override = upsellSelections[upsells[i].articleNumber] {
                        upsells[i].selected = override
                    }
                }
                configuredProduct.upsell = upsells
            }
            // Apply level selections
            for levelIdx in configuredProduct.levels.indices {
                let level = configuredProduct.levels[levelIdx]
                if let selectedArticle = levelSelections[level.levelNumber] {
                    for rowIdx in configuredProduct.levels[levelIdx].rows.indices {
                        configuredProduct.levels[levelIdx].rows[rowIdx].selected =
                            configuredProduct.levels[levelIdx].rows[rowIdx].articleNumber == selectedArticle
                    }
                }
            }

            cart.addItem(product: configuredProduct, quantity: quantity)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "cart.badge.plus")
                if totalPrice > 0 {
                    Text("Add to Cart — \(Int(totalPrice)) \(currency)")
                } else {
                    Text("Add to Cart")
                }
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding()
        }
    }

    // MARK: - Helpers

    private func levelTitle(for level: ProductLevel) -> String {
        // Derive a title from the row contents
        let names = level.rows.map { $0.articleName }
        if names.contains(where: { $0.lowercased().contains("milk") }) { return "Milk" }
        if names.contains(where: { $0.lowercased().contains("cream") || $0.lowercased().contains("whip") }) { return "Topping" }
        if names.contains(where: { $0.lowercased().contains("syrup") }) { return "Syrup" }
        return "Option \(level.levelNumber)"
    }

    private func isRowSelected(_ row: ProductRow, in level: ProductLevel) -> Bool {
        if let selected = levelSelections[level.levelNumber] {
            return row.articleNumber == selected
        }
        return row.selected
    }

    private func isUpsellSelected(_ upsell: UpsellOption) -> Bool {
        upsellSelections[upsell.articleNumber] ?? upsell.selected
    }

    private func symbolForItem(_ name: String) -> String {
        let lower = name.lowercased()
        // Milk types
        if lower.contains("milk") || lower.contains("mjölk") || lower.contains("lactose") || lower.contains("laktos") {
            return "drop.fill"
        }
        if lower.contains("oat") || lower.contains("haver") || lower.contains("soy") || lower.contains("soja") {
            return "leaf.fill"
        }
        // Cream / whip
        if lower.contains("cream") || lower.contains("whip") || lower.contains("grädde") || lower.contains("visp") {
            return "cloud.fill"
        }
        if lower.contains("no cream") || lower.contains("no whip") || lower.contains("utan") {
            return "xmark.circle"
        }
        // Syrup / flavor
        if lower.contains("syrup") || lower.contains("sirap") || lower.contains("vanilla") || lower.contains("vanilj")
            || lower.contains("caramel") || lower.contains("hazelnut") || lower.contains("hasselnöt")
            || lower.contains("strawberry") || lower.contains("jordgubb") {
            return "drop.triangle.fill"
        }
        // Sugar / sweetener
        if lower.contains("sugar") || lower.contains("socker") || lower.contains("sweetener") {
            return "cube.fill"
        }
        // Ice
        if lower.contains("ice") || lower.contains("is") {
            return "snowflake"
        }
        // Mix / base
        if lower.contains("mix") || lower.contains("frapino") || lower.contains("blend") {
            return "mug.fill"
        }
        // Extra / add-on
        if lower.contains("extra") {
            return "plus.circle.fill"
        }
        // Default
        return "circle.grid.2x1.fill"
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            ProductSheet(
                masterProduct: ShopMasterProduct(
                    name: "Frapino Strawberry",
                    image: nil,
                    menuTags: [],
                    configurations: [
                        ShopProduct(
                            articleNumber: "123",
                            articleName: "Frapino Strawberry Standard",
                            img: nil,
                            description: "A delicious strawberry frapino",
                            shortDescription: "Strawberry frapino",
                            navName: "Standard",
                            outOfStock: false,
                            icon: nil,
                            iconSelected: nil,
                            articleUrl: nil,
                            isComplexConfiguration: false,
                            price: 59,
                            currency: "SEK",
                            levels: [],
                            upsell: nil,
                            extraChoices: nil
                        )
                    ]
                ),
                cart: CartViewModel(shop: CoffeeShop(
                    id: 322, name: "Test", address1: nil, address2: nil,
                    postalCode: "", city: "", country: "", phoneNumber: nil,
                    latitude: 0, longitude: 0, wifi: nil, childFriendly: nil,
                    handicapFriendly: nil, expressCheckout: nil, takeAwayOnly: nil,
                    preorderOnline: false, todayOpenFrom: "", todayOpenTo: ""
                ))
            )
        }
}
