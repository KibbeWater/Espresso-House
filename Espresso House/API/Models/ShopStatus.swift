//
//  ShopStatus.swift
//  Espresso House
//

import Foundation

struct ShopStatusResponse: Codable {
    let shopNumber: Int?
    let shopStatus: String?
    let queueInfo: QueueInfo?
    let nextSlot: QueueSlot?

    var isOnline: Bool {
        shopStatus?.lowercased() == "online"
    }
}

struct QueueInfo: Codable {
    let notStarted: Int?
    let started: Int?
    let finishedButNotPickedUp: Int?
}

struct QueueSlot: Codable {
    let startDateTime: String?
    let endDateTime: String?
    let itemsInSlot: Int?
    let maxItemsInSlot: Int?
}
