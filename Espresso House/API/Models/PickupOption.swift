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
    var id: String { type }

    let type: String           // e.g. "TakeAway", "EatIn"
    let displayName: String?
}
