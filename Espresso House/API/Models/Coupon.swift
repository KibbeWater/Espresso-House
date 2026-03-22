//
//  Coupon.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

public struct Coupon: Codable, Identifiable, Sendable {
    public var id: String
    public var redeemed: Bool
    
    public var validFrom: Date
    public var validTo: Date
    public var daysRemaining: Int
    
    public var heading: String
    public var description: String
    public var longDescription: String
    
    public var imageURL: URL?
    
    public init(id: String, redeemed: Bool, validFrom: Date, validTo: Date, daysRemaining: Int, heading: String, description: String, longDescription: String, imageURL: URL? = nil) {
        self.id = id
        self.redeemed = redeemed
        self.validFrom = validFrom
        self.validTo = validTo
        self.daysRemaining = daysRemaining
        self.heading = heading
        self.description = description
        self.longDescription = longDescription
        self.imageURL = imageURL
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.redeemed = try container.decode(Bool.self, forKey: .redeemed)
        self.validFrom = parseISODate(from: try container.decode(String.self, forKey: .validFrom)) ?? .distantPast
        self.validTo = parseISODate(from: try container.decode(String.self, forKey: .validTo)) ?? .distantPast
        self.daysRemaining = try container.decode(Int.self, forKey: .daysRemaining)
        self.heading = try container.decode(String.self, forKey: .heading)
        self.description = try container.decode(String.self, forKey: .description)
        self.longDescription = try container.decode(String.self, forKey: .longDescription)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
    }
    
    public enum CodingKeys: String, CodingKey {
        case id = "couponKey"
        case redeemed = "isActivatedByUser"
        case validFrom
        case validTo
        case daysRemaining = "couponDaysOfValidity"
        case heading = "headingText"
        case description = "descriptionText"
        case longDescription = "longDescriptionText"
        case imageURL = "imageUrl"
    }
}
