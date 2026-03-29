//
//  OrderService.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

class OrderService: OrderServiceProtocol {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func getShopMenu(shopNumber: String) async throws -> [ShopMenuCategory] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let endpoint = Endpoint.getShopMenu(shopNumber: shopNumber, memberId: memberId)

        let data = try await networkManager.requestData(endpoint: endpoint)

        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(ShopMenuResponse.self, from: data)
            print("[OrderService] Decoded shop menu: \(response.menu.count) categories")
            return response.menu
        } catch {
            print("[OrderService] ShopMenuResponse decode failed: \(error)")
            if let preview = String(data: data.prefix(1000), encoding: .utf8) {
                print("[OrderService] Response preview: \(preview)")
            }
            throw EspressoAPIError.internalError(description: "Failed to decode shop menu")
        }
    }

    func getArticleConfigurations(shopNumber: String, articleNumbers: [String]) async throws -> [ShopProduct] {
        let endpoint = Endpoint.getArticleConfiguration(shopNumber: shopNumber, articleNumbers: articleNumbers)
        let data = try await networkManager.requestData(endpoint: endpoint)

        let decoder = JSONDecoder()
        // The response should be an array of configurations matching the order POST body format
        // Try array first, then wrapped in an object
        if let configs = try? decoder.decode([ShopProduct].self, from: data) {
            return configs
        }
        // Try as {"configurations": [...]}
        struct Wrapped: Decodable { let configurations: [ShopProduct] }
        if let wrapped = try? decoder.decode(Wrapped.self, from: data) {
            return wrapped.configurations
        }
        // Log what we got for debugging
        let preview = String(data: data.prefix(2000), encoding: .utf8) ?? "?"
        print("[OrderService] ArticleConfiguration unexpected format: \(preview)")
        throw EspressoAPIError.internalError(description: "Failed to decode article configurations")
    }

    func getPaymentOptions() async throws -> [PaymentOption] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }

        // Payment tokens and balance come from the member endpoint
        let data = try await networkManager.requestData(endpoint: Endpoint.getMember(memberId))

        struct MemberPaymentResponse: Decodable {
            let paymentTokens: [PaymentToken]?
            let balance: BalanceResponse?

            struct BalanceResponse: Decodable {
                let amount: Double
                let currency: String
                let countryCode: String

                func toBalance() -> Balance {
                    Balance(amount: amount, currency: currency, countryCode: countryCode)
                }
            }
        }

        struct PaymentToken: Decodable {
            let tokenKey: String
            let cardExpirationDate: String?  // e.g. "2609" (YYMM)
            let cardNumberMasked: String?    // e.g. "522660******1657"
            let cardIssuer: String?          // e.g. "SwedishDebitMasterCard"
            let name: String?
            let preferred: Bool?
            let pspKey: String?              // e.g. "Nets"

            func toPaymentOption() -> PaymentOption {
                let brand = formatCardBrand(cardIssuer)
                let masked = formatMaskedNumber(cardNumberMasked)
                let expiry = formatExpiry(cardExpirationDate)

                return PaymentOption(
                    paymentType: "CreditCard",
                    paymentIdentifier: tokenKey,
                    displayName: nil,
                    cardBrand: brand,
                    maskedCardNumber: masked,
                    expiryDate: expiry
                )
            }

            private func formatCardBrand(_ issuer: String?) -> String? {
                guard let issuer = issuer?.lowercased() else { return nil }
                if issuer.contains("mastercard") { return "Mastercard" }
                if issuer.contains("visa") { return "Visa" }
                if issuer.contains("amex") || issuer.contains("american") { return "Amex" }
                return issuer.capitalized
            }

            private func formatMaskedNumber(_ masked: String?) -> String? {
                guard let masked else { return nil }
                // "522660******1657" → "**** 1657"
                let last4 = String(masked.suffix(4))
                return "**** \(last4)"
            }

            private func formatExpiry(_ raw: String?) -> String? {
                guard let raw, raw.count == 4 else { return nil }
                // "2609" → "09/26"
                let yy = raw.prefix(2)
                let mm = raw.suffix(2)
                return "\(mm)/\(yy)"
            }
        }

        var options: [PaymentOption] = []
        let decoder = JSONDecoder()

        if let response = try? decoder.decode(MemberPaymentResponse.self, from: data) {
            // Always include the CoffeeCard so checkout can offer top-up
            if let bal = response.balance {
                options.append(.coffeeCard(memberId: memberId, balance: bal.toBalance()))
            }

            // Add credit card tokens
            if let tokens = response.paymentTokens, !tokens.isEmpty {
                options.append(contentsOf: tokens.map { $0.toPaymentOption() })
            }
        }

        return options
    }

    func getPickupOptions(shopNumber: String) async throws -> [PickupOption] {
        let response: PickupOptionsResponse = try await networkManager.request(
            endpoint: Endpoint.getPickupOptions(shopNumber: shopNumber)
        )
        return response.pickupOptions ?? []
    }

    func getShopStatus(shopNumber: String) async throws -> ShopStatusResponse {
        try await networkManager.request(
            endpoint: Endpoint.getShopStatus(shopNumber: shopNumber)
        )
    }

    func createOrder(request: OrderCreateRequest) async throws -> OrderCreateResponse {
        try await networkManager.post(
            endpoint: Endpoint.createOrder,
            body: request,
            authenticated: true
        )
    }

    func confirmOrder(digitalOrderKey: String, request: OrderConfirmRequest) async throws -> OrderCreateResponse {
        try await networkManager.post(
            endpoint: Endpoint.confirmOrder(digitalOrderKey: digitalOrderKey),
            body: request,
            authenticated: true
        )
    }

    func finalizeOrder(digitalOrderKey: String, request: OrderFinalizeRequest) async throws {
        try await networkManager.postRaw(
            endpoint: Endpoint.finalizeOrder(digitalOrderKey: digitalOrderKey),
            body: request,
            authenticated: true
        )
    }

    func getActiveOrders() async throws -> [ActiveOrder] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let response: ActiveOrdersResponse = try await networkManager.request(
            endpoint: Endpoint.getActiveOrders(memberId: memberId)
        )
        return response.orders ?? []
    }

    func createDirectPayment(request: StartDirectPaymentRequest) async throws -> StartDirectPaymentResponse {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        return try await networkManager.post(
            endpoint: Endpoint.createDirectPayment(memberId: memberId),
            body: request,
            authenticated: true
        )
    }

    func getPaymentTransactionStatus(transactionKey: String) async throws -> PaymentTransactionResponse {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        return try await networkManager.request(
            endpoint: Endpoint.getPaymentTransaction(memberId: memberId, transactionKey: transactionKey)
        )
    }
}
