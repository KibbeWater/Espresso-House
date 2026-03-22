//
//  Item.swift
//  Espresso House
//
//  Created by KibbeWater on 8/12/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
