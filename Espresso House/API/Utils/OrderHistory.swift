//
//  OrderHistory.swift
//  Espresso House
//

import Foundation

struct SavedOrder: Codable, Identifiable {
    let id: String
    let shopId: Int
    let shopName: String
    let date: Date
    let items: [SavedOrderItem]

    var totalPrice: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    var currency: String {
        items.first?.currency ?? "SEK"
    }

    var displayName: String {
        items.map { $0.name }.joined(separator: ", ")
    }

    var firstImageURL: String? {
        items.first(where: { $0.imageURL != nil })?.imageURL
    }
}

struct SavedOrderItem: Codable {
    let articleNumber: String
    let name: String
    let sizeName: String?
    let imageURL: String?
    let price: Double
    let currency: String
    let quantity: Int

    var totalPrice: Double { price * Double(quantity) }

    func toShopProduct() -> ShopProduct {
        ShopProduct(
            articleNumber: articleNumber,
            articleName: name,
            img: imageURL,
            description: nil,
            shortDescription: nil,
            navName: sizeName,
            outOfStock: false,
            icon: nil, iconSelected: nil, articleUrl: nil,
            isComplexConfiguration: false,
            price: price,
            currency: currency,
            levels: [],
            upsell: nil,
            extraChoices: nil
        )
    }
}

class OrderHistory {
    static let shared = OrderHistory()
    private let key = "savedOrderHistory"
    private let maxOrders = 20

    private init() {}

    func save(cart: CartViewModel) {
        let items = cart.items.map { item in
            SavedOrderItem(
                articleNumber: item.product.articleNumber,
                name: item.product.articleName,
                sizeName: item.product.navName,
                imageURL: item.product.img,
                price: item.unitPrice,
                currency: item.product.currency ?? "SEK",
                quantity: item.quantity
            )
        }

        let order = SavedOrder(
            id: UUID().uuidString,
            shopId: cart.shop.id,
            shopName: cart.shop.name,
            date: Date(),
            items: items
        )

        var history = loadAll()
        history.insert(order, at: 0)

        // Keep only the most recent orders
        if history.count > maxOrders {
            history = Array(history.prefix(maxOrders))
        }

        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadAll() -> [SavedOrder] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let orders = try? JSONDecoder().decode([SavedOrder].self, from: data) else {
            return []
        }
        return orders
    }

    /// Orders for a specific shop, deduplicated by item combination
    func ordersForShop(_ shopId: Int) -> [SavedOrder] {
        let shopOrders = loadAll().filter { $0.shopId == shopId }

        // Deduplicate: keep the most recent order for each unique item combination
        var seen = Set<String>()
        var unique: [SavedOrder] = []
        for order in shopOrders {
            let fingerprint = order.items.map { "\($0.articleNumber)x\($0.quantity)" }.sorted().joined(separator: "|")
            if seen.insert(fingerprint).inserted {
                unique.append(order)
            }
        }
        return unique
    }
}
