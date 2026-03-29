//
//  CartViewModel.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

@Observable
class CartViewModel {
    var items: [CartItem] = []
    let shop: CoffeeShop

    struct CartItem: Identifiable {
        let id = UUID()
        var product: ShopProduct
        var quantity: Int = 1

        var unitPrice: Double {
            var base = product.price ?? 0
            if let upsells = product.upsell {
                for upsell in upsells where upsell.selected && upsell.isAffectingPrice {
                    base += upsell.price * Double(upsell.quantity ?? 1)
                }
            }
            return base
        }

        var totalPrice: Double {
            unitPrice * Double(quantity)
        }

        var sizeName: String {
            product.navName ?? "Standard"
        }
    }

    init(shop: CoffeeShop) {
        self.shop = shop
    }

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totalPrice: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    var currency: String {
        items.first?.product.currency ?? "SEK"
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    func addItem(product: ShopProduct, quantity: Int = 1) {
        items.append(CartItem(product: product, quantity: quantity))
    }

    func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }

    func updateQuantity(id: UUID, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
    }

    func clear() {
        items.removeAll()
    }

    func buildConfigurations() -> [ShopProduct] {
        items.map { $0.product }
    }
}
