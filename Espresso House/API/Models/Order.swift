//
//  Order.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

// MARK: - Create order (POST /Order/v3)

struct OrderCreateRequest: Encodable {
    let shopNumber: String
    let orderType: String  // "PreOrderTakeAway"
    let includeMemberDiscount: Bool
    let customerDisplayName: String
    let myEspressoHouseNumber: String
    let configurations: [ShopProduct]
}

// MARK: - Confirm order (POST /Order/v3/{digitalOrderKey})

struct OrderConfirmRequest: Encodable {
    let shopNumber: String
    let orderType: String
    let includeMemberDiscount: Bool
    let customerDisplayName: String
    let myEspressoHouseNumber: String
    let digitalOrderKey: String
    let payments: [String]  // Empty array in the real flow
    let configurations: [ShopProduct]
}

// MARK: - Finalize order (POST /Order/v3/{digitalOrderKey}/Finalize)

struct OrderFinalizeRequest: Encodable {
    let myEspressoHouseNumber: String
    let paymentMethod: PaymentMethod
}

struct PaymentMethod: Codable {
    let paymentType: String      // e.g. "CreditCard"
    let paymentIdentifier: String // UUID from payment options
}

// MARK: - Order response (from create/confirm)

struct OrderCreateResponse: Codable {
    let digitalOrderKey: String
    let orderNumber: String?
    let totalAmount: Double?
    let currency: String?
}

// MARK: - Active orders (GET /Order/v2/member/{memberId})

struct ActiveOrdersResponse: Codable {
    let orders: [ActiveOrder]?
}

struct ActiveOrder: Codable, Identifiable {
    var id: String { digitalOrderKey }

    let digitalOrderKey: String
    let orderNumber: Int?
    let shopNumber: String?
    let orderStatus: String?
    let orderTotal: Double?
    let orderGrossTotal: Double?
    let currencyCode: String?
    let orderCreated: String?
    let orderLastUpdated: String?
    let orderFullyPaid: String?
    let estimatedPickupTime: String?
    let orderType: String?
    let customerDisplayName: String?
    let orderPinCode: String?
    let shopInformation: ShopInfo?
    let configurations: [OrderConfiguration]?

    // Convenience accessors for UI
    var status: String? { orderStatus }
    var totalAmount: Double? { orderTotal }
    var currency: String? { currencyCode }
    var shopName: String? { shopInformation?.shopName }

    var items: [OrderConfiguration]? { configurations }

    struct ShopInfo: Codable {
        let shopNumber: Int?
        let shopName: String?
        let address1: String?
        let city: String?
    }
}

struct OrderConfiguration: Codable, Identifiable {
    var id: String { articleNumber ?? UUID().uuidString }

    let articleNumber: String?
    let articleName: String?
    let img: String?
    let navName: String?
    let shortDescription: String?
}
