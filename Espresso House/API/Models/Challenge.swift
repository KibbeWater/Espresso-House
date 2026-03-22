//
//  Challenge.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

public struct Challenge: Codable, Identifiable {
    public var id: String
    public var imageUrl: URL
    
    public var stepsDone: Int
    public var totalSteps: Int
    
    public var startDate: Date
    public var endDate: Date
    public var created: Date
    
    public var heading: String
    public var description: String
    public var longDescription: String
    
    public var isActive: Bool
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.imageUrl = URL(string: try container.decode(String.self, forKey: .imageUrl)) ?? URL(string: "https://google.com")!
        self.stepsDone = try container.decode(Int.self, forKey: .stepsDone)
        self.totalSteps = try container.decode(Int.self, forKey: .totalSteps)
        self.startDate = parseISODate(from: try container.decode(String.self, forKey: .startDate)) ?? .distantPast
        self.endDate = parseISODate(from: try container.decode(String.self, forKey: .endDate)) ?? .distantPast
        self.created = parseISODate(from: try container.decode(String.self, forKey: .created)) ?? .distantPast
        self.heading = try container.decode(String.self, forKey: .heading)
        self.description = try container.decode(String.self, forKey: .description)
        self.longDescription = try container.decode(String.self, forKey: .longDescription)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "challengeKey"
        case imageUrl
        case stepsDone
        case totalSteps
        case startDate
        case endDate
        case created
        case heading
        case description
        case longDescription
        case isActive
    }
}
