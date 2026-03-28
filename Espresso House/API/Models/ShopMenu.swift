//
//  ShopMenu.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

// MARK: - Top-level response from GET /DoeApi/api/Shop/v3/{shop}/menu/{member}
// Actual response: {"name":"Menu","menu":[...categories...]}

struct ShopMenuResponse: Codable {
    let name: String?
    let menu: [ShopMenuCategory]
}

struct ShopMenuCategory: Codable, Identifiable {
    var id: String { name }
    let name: String
    let image: String?
    let masterProducts: [ShopMasterProduct]

    init(name: String, masterProducts: [ShopMasterProduct]) {
        self.name = name
        self.image = nil
        self.masterProducts = masterProducts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.image = try? container.decode(String.self, forKey: .image)
        self.masterProducts = (try? container.decode([ShopMasterProduct].self, forKey: .masterProducts)) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case name, image, masterProducts
    }
}

// MARK: - Master product (groups size variants / articles)
// Actual: {"name":"Hazelnut Latte","image":"...","articles":[...],"defaultArticleNumber":"...","priceFrom":{"amount":54.0,"currencyCode":"SEK"},"menuTags":[...],"masterProductKey":"...","outOfStock":false}

struct ShopMasterProduct: Codable, Identifiable {
    var id: String { masterProductKey ?? name }
    let name: String
    let image: String?
    let articles: [ShopArticle]
    let defaultArticleNumber: String?
    let priceFrom: Price?
    let menuTags: [MenuProductTag]
    let masterProductKey: String?
    let outOfStock: Bool?

    struct MenuProductTag: Codable, Hashable {
        let priority: Int
        let text: String
    }

    // Convenience: first article's price or priceFrom
    var displayPrice: Double? {
        priceFrom?.amount ?? articles.first?.price?.amount
    }

    var currency: String {
        priceFrom?.currencyCode ?? articles.first?.price?.currencyCode ?? "SEK"
    }

    // Map to ShopProduct for cart/checkout compatibility
    var configurations: [ShopProduct] {
        articles.map { article in
            ShopProduct(
                articleNumber: article.articleNumber,
                articleName: name,
                img: article.img ?? image,
                description: article.description,
                shortDescription: article.shortDescription,
                navName: article.navigationName,
                outOfStock: article.outOfStock ?? false,
                icon: article.icon ?? article.navigationIcon,
                iconSelected: article.iconSelected ?? article.navigationIconSelected,
                articleUrl: article.articleUrl,
                isComplexConfiguration: article.isComplexConfiguration,
                price: article.price?.amount,
                currency: article.price?.currencyCode ?? priceFrom?.currencyCode,
                levels: article.levels ?? [],
                upsell: article.upsell,
                extraChoices: article.extraChoices
            )
        }
    }

    init(name: String, image: String?, menuTags: [MenuProductTag], configurations: [ShopProduct]) {
        self.name = name
        self.image = image
        self.menuTags = menuTags
        self.masterProductKey = nil
        self.defaultArticleNumber = configurations.first?.articleNumber
        self.priceFrom = configurations.first.flatMap { p in
            p.price.map { Price(amount: $0, currencyCode: p.currency ?? "SEK") }
        }
        self.outOfStock = false
        self.articles = configurations.map { config in
            ShopArticle(
                articleNumber: config.articleNumber,
                name: config.articleName,
                navigationName: config.navName,
                navigationIcon: config.icon,
                navigationIconSelected: config.iconSelected,
                price: config.price.map { Price(amount: $0, currencyCode: config.currency ?? "SEK") },
                outOfStock: config.outOfStock,
                description: config.description,
                shortDescription: config.shortDescription,
                articleUrl: config.articleUrl,
                isComplexConfiguration: config.isComplexConfiguration,
                icon: config.icon,
                iconSelected: config.iconSelected,
                img: config.img,
                levels: config.levels,
                upsell: config.upsell,
                extraChoices: config.extraChoices
            )
        }
    }
}

// MARK: - Article (a specific size/variant)
// Actual: {"articleNumber":"3712272","name":"nothing from pimcore","navigationName":"Small","navigationIcon":"...","price":{"amount":54.0,"currencyCode":"SEK"},"outOfStock":false}

struct ShopArticle: Codable, Identifiable {
    var id: String { articleNumber }

    let articleNumber: String
    let name: String?
    let navigationName: String?
    let navigationIcon: String?
    let navigationIconSelected: String?
    let price: Price?
    let outOfStock: Bool?
    let description: String?
    let shortDescription: String?
    let articleUrl: String?
    let isComplexConfiguration: Bool?
    let icon: String?
    let iconSelected: String?
    let img: String?

    // Configuration data (levels, upsells) — present in the full menu response
    let levels: [ProductLevel]?
    let upsell: [UpsellOption]?
    let extraChoices: [ExtraChoice]?
}

struct Price: Codable, Hashable {
    let amount: Double
    let currencyCode: String
}

// MARK: - ShopProduct (used for cart/order — a configured product ready for the order API)
// This is what we build when the user selects options and adds to cart.
// Also used directly by MockOrderService for debug flows.

struct ShopProduct: Codable, Identifiable {
    var id: String { articleNumber }

    let articleNumber: String
    let articleName: String
    let img: String?
    let description: String?
    let shortDescription: String?
    let navName: String?
    let outOfStock: Bool
    let icon: String?
    let iconSelected: String?
    let articleUrl: String?
    let isComplexConfiguration: Bool?
    let price: Double?
    let currency: String?

    var levels: [ProductLevel]
    var upsell: [UpsellOption]?
    var extraChoices: [ExtraChoice]?
}

// MARK: - Customization levels (milk, cream, etc.) — used during order configuration

struct ProductLevel: Codable {
    let levelNumber: Int
    let requiredNumberOfSelections: Int
    let customerMustSelect: Bool
    var rows: [ProductRow]
}

struct ProductRow: Codable, Identifiable {
    var id: String { articleNumber }

    let articleNumber: String
    let articleName: String
    let quantity: Double?
    let quantityUnit: String?
    var selected: Bool
    let outOfStock: Bool
    let rowNumber: Int?
    let icon: String?
    let iconSelected: String?
    let selectedDateTime: Double?
    let configuration: ProductRowConfiguration?
}

struct ProductRowConfiguration: Codable {
    let articleNumber: String
    let articleName: String
    let isComplexConfiguration: Bool?
    let outOfStock: Bool?
    let icon: String?
    let iconSelected: String?
    let navName: String?
    let levels: [ProductLevel]?
}

// MARK: - Upsell options (extra syrup, whipped cream, etc.)

struct UpsellOption: Codable, Identifiable {
    var id: String { articleNumber }

    let articleNumber: String
    let articleName: String
    let price: Double
    let currency: String
    var selected: Bool
    let outOfStock: Bool
    let isAffectingPrice: Bool
    let icon: String?
    let iconSelected: String?
    let quantityAlternatives: [QuantityAlternative]?
    let quantity: Int?
}

struct QuantityAlternative: Codable {
    let quantity: Int
    let displayText: String
}

// MARK: - Extra choices

struct ExtraChoice: Codable {}
