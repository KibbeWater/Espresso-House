//
//  PickupOption.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

struct PickupOptionsResponse: Codable {
    let pickupOptions: [PickupOption]?

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.pickupOptions = try? container.decode([PickupOption].self, forKey: .pickupOptions)
        } else if let array = try? decoder.singleValueContainer().decode([PickupOption].self) {
            self.pickupOptions = array
        } else {
            self.pickupOptions = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case pickupOptions
    }
}

struct PickupOption: Codable, Identifiable, Hashable {
    var id: String { pickupOptionKey ?? pickupOption ?? UUID().uuidString }

    let pickupOption: String?              // e.g. "TakeAway", "EatIn"
    let pickupOptionDisplayText: String?   // e.g. "Take Away", "Eat In"
    let pickupOptionKey: String?           // unique key
    let orderType: String?                 // e.g. "PreOrderTakeAway"
    let sortOrder: Int?

    // Convenience for display
    var displayName: String {
        pickupOptionDisplayText ?? pickupOption ?? "Unknown"
    }

    var type: String {
        pickupOption ?? ""
    }

    // Manual init for mock data
    init(pickupOption: String, displayText: String, orderType: String? = nil, key: String? = nil, sortOrder: Int? = nil) {
        self.pickupOption = pickupOption
        self.pickupOptionDisplayText = displayText
        self.pickupOptionKey = key ?? pickupOption
        self.orderType = orderType
        self.sortOrder = sortOrder
    }
}
