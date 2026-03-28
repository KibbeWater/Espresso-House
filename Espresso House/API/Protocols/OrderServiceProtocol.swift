//
//  OrderServiceProtocol.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

protocol OrderServiceProtocol {
    func getShopMenu(shopNumber: String) async throws -> [ShopMenuCategory]
    func getArticleConfigurations(shopNumber: String, articleNumbers: [String]) async throws -> [ShopProduct]
    func getPaymentOptions() async throws -> [PaymentOption]
    func getPickupOptions(shopNumber: String) async throws -> [PickupOption]
    func createOrder(request: OrderCreateRequest) async throws -> OrderCreateResponse
    func confirmOrder(digitalOrderKey: String, request: OrderConfirmRequest) async throws -> OrderCreateResponse
    func finalizeOrder(digitalOrderKey: String, request: OrderFinalizeRequest) async throws
    func getActiveOrders() async throws -> [ActiveOrder]
}
