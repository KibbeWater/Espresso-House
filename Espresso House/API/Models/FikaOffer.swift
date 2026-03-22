//
//  FikaOffer.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

public struct FikaOffer: Codable, Identifiable {
    public var id: String
    public var points: Int
    public var imageUrl: URL?
    
    public var heading: String
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.points = try container.decode(Int.self, forKey: .points)
        self.imageUrl = URL(string: try container.decode(String.self, forKey: .imageUrl))
        self.heading = try container.decode(String.self, forKey: .heading)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "couponTemplateKey"
        case points = "priceInPunches"
        case imageUrl
        case heading = "headingText"
    }
}
