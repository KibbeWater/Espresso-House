//
//  MemberEvent.swift
//  Espresso House
//

import Foundation

struct MemberEventsResponse: Decodable {
    let events: [MemberEvent]?

    init(from decoder: Decoder) throws {
        // Try as keyed container first
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.events = try? container.decode([MemberEvent].self, forKey: .events)
        } else if let array = try? decoder.singleValueContainer().decode([MemberEvent].self) {
            self.events = array
        } else {
            self.events = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case events
    }
}

struct MemberEvent: Decodable, Identifiable {
    var id: String { eventType + (myEspressoHouseNumber ?? UUID().uuidString) }

    let eventType: String
    let myEspressoHouseNumber: String?
    let eventData: String?
    let created: String?

    enum CodingKeys: String, CodingKey {
        case eventName
        case eventType
        case myEspressoHouseNumber
        case eventData
        case created
    }

    // Manual init for fallback JSON parsing
    init(eventType: String, myEspressoHouseNumber: String?, eventData: String?, created: String?) {
        self.eventType = eventType
        self.myEspressoHouseNumber = myEspressoHouseNumber
        self.eventData = eventData
        self.created = created
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // API uses "eventName", not "eventType"
        if let name = try? container.decode(String.self, forKey: .eventName) {
            self.eventType = name
        } else {
            self.eventType = try container.decode(String.self, forKey: .eventType)
        }
        self.myEspressoHouseNumber = try? container.decode(String.self, forKey: .myEspressoHouseNumber)
        self.eventData = try? container.decode(String.self, forKey: .eventData)
        self.created = try? container.decode(String.self, forKey: .created)
    }
}
