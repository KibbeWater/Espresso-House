//
//  MockOrderService.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

#if DEBUG
import Foundation

class MockOrderService: OrderServiceProtocol {
    private var mockOrderKey = UUID().uuidString
    private var orderCreatedAt: Date?

    func getArticleConfigurations(shopNumber: String, articleNumbers: [String]) async throws -> [ShopProduct] {
        // Return mock configurations with upsells
        articleNumbers.map { articleNumber in
            ShopProduct(
                articleNumber: articleNumber,
                articleName: "Mock Product",
                img: nil,
                description: "A delicious mock product",
                shortDescription: "Mock product",
                navName: "Standard",
                outOfStock: false,
                icon: nil, iconSelected: nil, articleUrl: nil,
                isComplexConfiguration: false,
                price: 49,
                currency: "SEK",
                levels: [],
                upsell: [
                    UpsellOption(
                        articleNumber: "MOCK-U01",
                        articleName: "Vanilla Syrup",
                        price: 5, currency: "SEK",
                        selected: false, outOfStock: false,
                        isAffectingPrice: true,
                        icon: nil, iconSelected: nil,
                        quantityAlternatives: nil, quantity: 1
                    )
                ],
                extraChoices: nil
            )
        }
    }

    func getShopMenu(shopNumber: String) async throws -> [ShopMenuCategory] {
        [
            ShopMenuCategory(
                name: "Hot Drinks",
                masterProducts: [
                    ShopMasterProduct(
                        name: "Latte",
                        image: nil,
                        menuTags: [.init(priority: 1, text: "Hot")],
                        configurations: [
                            ShopProduct(
                                articleNumber: "MOCK-001",
                                articleName: "Latte Standard",
                                img: nil,
                                description: "A smooth and creamy latte made with our signature espresso.",
                                shortDescription: "Classic latte",
                                navName: "Standard",
                                outOfStock: false,
                                icon: nil, iconSelected: nil, articleUrl: nil,
                                isComplexConfiguration: false,
                                price: 49,
                                currency: "SEK",
                                levels: [],
                                upsell: [
                                    UpsellOption(
                                        articleNumber: "MOCK-U01",
                                        articleName: "Vanilla Syrup",
                                        price: 5,
                                        currency: "SEK",
                                        selected: false,
                                        outOfStock: false,
                                        isAffectingPrice: true,
                                        icon: nil, iconSelected: nil,
                                        quantityAlternatives: nil,
                                        quantity: 1
                                    )
                                ],
                                extraChoices: nil
                            ),
                            ShopProduct(
                                articleNumber: "MOCK-002",
                                articleName: "Latte Large",
                                img: nil,
                                description: "A smooth and creamy latte made with our signature espresso.",
                                shortDescription: "Classic latte",
                                navName: "Large",
                                outOfStock: false,
                                icon: nil, iconSelected: nil, articleUrl: nil,
                                isComplexConfiguration: false,
                                price: 59,
                                currency: "SEK",
                                levels: [],
                                upsell: nil,
                                extraChoices: nil
                            )
                        ]
                    ),
                    ShopMasterProduct(
                        name: "Cappuccino",
                        image: nil,
                        menuTags: [.init(priority: 1, text: "Hot")],
                        configurations: [
                            ShopProduct(
                                articleNumber: "MOCK-003",
                                articleName: "Cappuccino Standard",
                                img: nil,
                                description: "Rich espresso with perfectly steamed milk foam.",
                                shortDescription: "Classic cappuccino",
                                navName: "Standard",
                                outOfStock: false,
                                icon: nil, iconSelected: nil, articleUrl: nil,
                                isComplexConfiguration: false,
                                price: 45,
                                currency: "SEK",
                                levels: [],
                                upsell: nil,
                                extraChoices: nil
                            )
                        ]
                    )
                ]
            ),
            ShopMenuCategory(
                name: "Bakery",
                masterProducts: [
                    ShopMasterProduct(
                        name: "Cinnamon Bun",
                        image: nil,
                        menuTags: [.init(priority: 1, text: "Pastry")],
                        configurations: [
                            ShopProduct(
                                articleNumber: "MOCK-010",
                                articleName: "Cinnamon Bun",
                                img: nil,
                                description: "Freshly baked Swedish kanelbulle.",
                                shortDescription: "Classic cinnamon bun",
                                navName: "Standard",
                                outOfStock: false,
                                icon: nil, iconSelected: nil, articleUrl: nil,
                                isComplexConfiguration: false,
                                price: 35,
                                currency: "SEK",
                                levels: [],
                                upsell: nil,
                                extraChoices: nil
                            )
                        ]
                    )
                ]
            )
        ]
    }

    func getPaymentOptions() async throws -> [PaymentOption] {
        let balance = DebugSettings.shared.mockCoffeeCardBalance
        return [
            PaymentOption(
                paymentType: "CoffeeCard",
                paymentIdentifier: "mock-member-id",
                displayName: "Coffee Card (\(Int(balance)) SEK)",
                cardBrand: nil,
                maskedCardNumber: nil,
                expiryDate: nil,
                balanceAmount: balance
            ),
            PaymentOption(
                paymentType: "CreditCard",
                paymentIdentifier: "mock-visa-4242",
                displayName: "Visa *4242",
                cardBrand: "Visa",
                maskedCardNumber: "**** 4242",
                expiryDate: "12/28"
            ),
            PaymentOption(
                paymentType: "CreditCard",
                paymentIdentifier: "mock-mc-1234",
                displayName: "Mastercard *1234",
                cardBrand: "Mastercard",
                maskedCardNumber: "**** 1234",
                expiryDate: "06/27"
            )
        ]
    }

    func getPickupOptions(shopNumber: String) async throws -> [PickupOption] {
        [PickupOption(type: "TakeAway", displayName: "Take Away")]
    }

    func createOrder(request: OrderCreateRequest) async throws -> OrderCreateResponse {
        mockOrderKey = UUID().uuidString
        orderCreatedAt = Date()
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(500))
        return OrderCreateResponse(
            digitalOrderKey: mockOrderKey,
            orderNumber: "MOCK-\(Int.random(in: 1000...9999))",
            totalAmount: 49,
            currency: "SEK"
        )
    }

    func confirmOrder(digitalOrderKey: String, request: OrderConfirmRequest) async throws -> OrderCreateResponse {
        try await Task.sleep(for: .milliseconds(300))
        return OrderCreateResponse(
            digitalOrderKey: digitalOrderKey,
            orderNumber: "MOCK-\(Int.random(in: 1000...9999))",
            totalAmount: 49,
            currency: "SEK"
        )
    }

    func finalizeOrder(digitalOrderKey: String, request: OrderFinalizeRequest) async throws {
        try await Task.sleep(for: .milliseconds(500))
        // Success — no response needed
    }

    func getActiveOrders() async throws -> [ActiveOrder] {
        guard let createdAt = orderCreatedAt else { return [] }

        let elapsed = Date().timeIntervalSince(createdAt)
        let debugStatus = DebugSettings.shared.mockOrderStatus

        // If debug has forced a status, use that
        let status: String
        if debugStatus != "Created" {
            status = debugStatus
        } else {
            // Auto-progress: Created -> Preparing (10s) -> Ready (20s)
            if elapsed > 20 {
                status = "Ready"
            } else if elapsed > 10 {
                status = "Preparing"
            } else {
                status = "Created"
            }
        }

        return [
            ActiveOrder(
                digitalOrderKey: mockOrderKey,
                orderNumber: 4242,
                shopNumber: "322",
                orderStatus: status,
                orderTotal: 49,
                orderGrossTotal: 49,
                currencyCode: "SEK",
                orderCreated: ISO8601DateFormatter().string(from: createdAt),
                orderLastUpdated: nil,
                orderFullyPaid: ISO8601DateFormatter().string(from: createdAt),
                estimatedPickupTime: nil,
                orderType: "PreOrderTakeAway",
                customerDisplayName: "Mock",
                orderPinCode: "1234",
                shopInformation: ActiveOrder.ShopInfo(shopNumber: 322, shopName: "Mock Espresso House", address1: nil, city: nil),
                configurations: [
                    OrderConfiguration(articleNumber: "MOCK-001", articleName: "Latte Standard", img: nil, navName: "Standard", shortDescription: nil)
                ]
            )
        ]
    }

    func createDirectPayment(request: StartDirectPaymentRequest) async throws -> StartDirectPaymentResponse {
        try await Task.sleep(for: .milliseconds(300))
        return StartDirectPaymentResponse(
            terminalUrl: "https://example.com/mock-paypal",
            paymentTransactionKey: UUID().uuidString,
            paymentDirectlyPaid: false
        )
    }

    func getPaymentTransactionStatus(transactionKey: String) async throws -> PaymentTransactionResponse {
        PaymentTransactionResponse(
            paymentTransactionKey: transactionKey,
            paymentTransactionState: "Completed"
        )
    }
}
#endif
