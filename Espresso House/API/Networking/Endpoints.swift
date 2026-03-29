//
//  Endpoints.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import Foundation

protocol Endpoints {
    static var baseURL: URL { get }

    var url: URL { get }
}

enum Endpoint: Endpoints {
    static let baseURL = URL(string: "https://myespressohouse.com")!

    case getMenu
    case getShops
    case getMember(String)
    case getChallenges(String)
    case getFikaOffers(String)

    // Auth endpoints
    case register
    case sendSMS(String)
    case verify(String)

    // Shop menu & ordering
    case getShopMenu(shopNumber: String, memberId: String)
    case getArticleConfiguration(shopNumber: String, articleNumbers: [String])
    case getPickupOptions(shopNumber: String)
    case getShopStatus(shopNumber: String)
    case getShopInventory(shopNumber: String)
    case getUpsell(shopNumber: String, memberId: String)

    // Orders
    case createOrder
    case confirmOrder(digitalOrderKey: String)
    case finalizeOrder(digitalOrderKey: String)
    case getActiveOrders(memberId: String)
    case getPreviousPurchases(memberId: String)

    // Payment
    case getPaymentOptions(countryCode: String, memberId: String)
    case getDirectPaymentMethods(countryCode: String, memberId: String, pspKey: String)

    // Top-up
    case getTopUpValues(memberId: String)
    case getTopUpPaymentOptions(memberId: String)
    case topUpCreditCard(memberId: String)
    case topUpSwish(memberId: String)

    // Events
    case getMemberEvents(memberId: String)

    // Card registration & management
    case getCardRegistrationURL(memberId: String)
    case deletePaymentToken(memberId: String, tokenKey: String)
    case setPreferredPaymentToken(memberId: String, tokenKey: String)

    // DirectPayment (PayPal)
    case createDirectPayment(memberId: String)
    case getPaymentTransaction(memberId: String, transactionKey: String)

    var url: URL {
        switch self {
        case .getMenu: return Self.baseURL.appendingPathComponent("/DoeApi/api/Market/v1/menu/se/en")
        case .getShops: return Self.baseURL.appendingPathComponent("/beproud/api/CoffeeShop/v2")
        case .getMember(let memberId): return Self.baseURL.appendingPathComponent("/beproud/api/member/v2/\(memberId)")
        case .getChallenges(let memberId): return Self.baseURL.appendingPathComponent("/beproud/api/Member/v1/\(memberId)/challenges")
        case .getFikaOffers(let memberId): return Self.baseURL.appendingPathComponent("/beproud/api/FikaHouse/v1/SE/\(memberId)")
        case .register: return Self.baseURL.appendingPathComponent("/beproud/api/registration/v2")
        case .sendSMS(let id): return Self.baseURL.appendingPathComponent("/beproud/api/registration/v1/\(id)/sendsms")
        case .verify(let id): return Self.baseURL.appendingPathComponent("/beproud/api/registration/v1/\(id)/verify")

        case .getShopMenu(let shopNumber, let memberId):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let menuTime = formatter.string(from: Date())
            var components = URLComponents(string: Self.baseURL.absoluteString + "/DoeApi/api/Shop/v3/\(shopNumber)/menu/\(memberId)")!
            components.queryItems = [
                URLQueryItem(name: "MenuTime", value: menuTime),
                URLQueryItem(name: "myEspressoHouseNumber", value: memberId),
                URLQueryItem(name: "shopNumber", value: shopNumber),
            ]
            return components.url!
        case .getArticleConfiguration(let shopNumber, let articleNumbers):
            let articles = articleNumbers.joined(separator: ",")
            return URL(string: Self.baseURL.absoluteString + "/DoeApi/api/ArticleConfiguration/v3/Configuration/\(shopNumber)/\(articles)")!
        case .getPickupOptions(let shopNumber):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Shop/v1/\(shopNumber)/PickupOptions")
        case .getShopInventory(let shopNumber):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Shop/v1/\(shopNumber)/inventory")
        case .getShopStatus(let shopNumber):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Shop/v1/\(shopNumber)/status")
        case .getUpsell(let shopNumber, let memberId):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Shop/v3/\(shopNumber)/upsell/\(memberId)")

        case .createOrder:
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Order/v3")
        case .confirmOrder(let digitalOrderKey):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Order/v3/\(digitalOrderKey)")
        case .finalizeOrder(let digitalOrderKey):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Order/v3/\(digitalOrderKey)/Finalize")
        case .getActiveOrders(let memberId):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Order/v2/member/\(memberId)")
        case .getPreviousPurchases(let memberId):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Order/previouspurchase/v1/\(memberId)")

        case .getPaymentOptions(let countryCode, let memberId):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Market/v1/paymentoption/\(countryCode)/\(memberId)")
        case .getDirectPaymentMethods(let countryCode, let memberId, let pspKey):
            return Self.baseURL.appendingPathComponent("/DoeApi/api/Market/v2/paymentoption/\(countryCode)/\(memberId)/\(pspKey)")

        // Top-up
        case .getTopUpValues(let memberId):
            return Self.baseURL.appendingPathComponent("/beproud/api/TopUp/v2/\(memberId)/topupvalues")
        case .getTopUpPaymentOptions(let memberId):
            return Self.baseURL.appendingPathComponent("/beproud/api/TopUp/v2/\(memberId)/paymentoptions")
        case .topUpCreditCard(let memberId):
            return Self.baseURL.appendingPathComponent("/beproud/api/TopUp/v1/\(memberId)")
        case .topUpSwish(let memberId):
            return Self.baseURL.appendingPathComponent("/beproud/api/TopUp/v1/\(memberId)/swish")

        // Events
        case .getMemberEvents(let memberId):
            return Self.baseURL.appendingPathComponent("/beproud/api/Member/v1/\(memberId)/event")

        // Card registration & management
        case .getCardRegistrationURL(let memberId):
            return Self.baseURL.appendingPathComponent("/beproud/api/PaymentCardRegistration/v1/\(memberId)")
        case .deletePaymentToken(let memberId, let tokenKey):
            return Self.baseURL.appendingPathComponent("/beproud/api/Member/v1/\(memberId)/paymentToken/\(tokenKey)")
        case .setPreferredPaymentToken(let memberId, let tokenKey):
            return Self.baseURL.appendingPathComponent("/beproud/api/Member/v1/\(memberId)/paymentToken/\(tokenKey)")

        // DirectPayment
        case .createDirectPayment(let memberId):
            return Self.baseURL.appendingPathComponent("/beproud/api/Psp/v1/member/\(memberId)/directpayment")
        case .getPaymentTransaction(let memberId, let transactionKey):
            return Self.baseURL.appendingPathComponent("/beproud/api/Member/v1/\(memberId)/paymenttransaction/\(transactionKey)")
        }
    }
}
