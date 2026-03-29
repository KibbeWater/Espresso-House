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

    /// Parse "HH:mm:ss" into total minutes since midnight
    private func parseMinutes(_ timeStr: String) -> Int? {
        let parts = timeStr.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    /// Whether the shop is currently open based on todayOpenFrom/todayOpenTo
    public var isCurrentlyOpen: Bool {
        guard let openMin = parseMinutes(todayOpenFrom),
              let closeMin = parseMinutes(todayOpenTo) else {
            return false
        }

        // Closed today: open == close (e.g. "00:00:00" to "00:00:00")
        if openMin == closeMin { return false }

        let calendar = Calendar.current
        let now = Date()
        let nowMin = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        if closeMin > openMin {
            // Normal: e.g. 08:00–20:00
            return nowMin >= openMin && nowMin < closeMin
        } else {
            // Overnight: e.g. 22:00–06:00
            return nowMin >= openMin || nowMin < closeMin
        }
    }

    /// Whether the shop is closed today (special hours / holiday)
    public var isClosedToday: Bool {
        guard let openMin = parseMinutes(todayOpenFrom),
              let closeMin = parseMinutes(todayOpenTo) else {
            return true
        }
        return openMin == closeMin
    }

    /// Formatted opening hours string (e.g. "08:00 – 20:00" or "Closed today")
    public var formattedHours: String {
        if isClosedToday { return "Closed today" }
        let trimOpen = String(todayOpenFrom.prefix(5))
        let trimClose = String(todayOpenTo.prefix(5))
        return "\(trimOpen) – \(trimClose)"
    }

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
