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
        }
    }
}
