//
//  Shops.swift
//  Espresso House
//
//  Created by KibbeWater on 19/12/24.
//

import Foundation
import CoreLocation

public struct CoffeeShop: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    
    public let address1: String?
    public let address2: String?
    public let postalCode: String?
    public let city: String
    public let country: String
    public let phoneNumber: String?
    
    public var location: CLLocationCoordinate2D { get { CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude) } }
    public let latitude: Double
    public let longitude: Double
    
    // Flags
    public let wifi: Bool?
    public let childFriendly: Bool?
    public let handicapFriendly: Bool?
    public let expressCheckout: Bool?
    public let takeAwayOnly: Bool?
    public let preorderOnline: Bool
    
    public let todayOpenFrom: String
    public let todayOpenTo: String
    
    enum CodingKeys: String, CodingKey {
        case id = "coffeeShopId"
        case name = "coffeeShopName"
        case address1
        case address2
        case postalCode
        case city
        case country
        case phoneNumber
        case latitude
        case longitude
        case wifi
        case childFriendly
        case handicapFriendly
        case expressCheckout
        case takeAwayOnly
        case preorderOnline
        case todayOpenFrom
        case todayOpenTo
    }
}
