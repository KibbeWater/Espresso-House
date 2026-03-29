//
//  DebugSettings.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

#if DEBUG
@Observable
class DebugSettings {
    static let shared = DebugSettings()

    var isSimulating = false
    var mockOrderStatus: String = "Auto"
    var mockCoffeeCardBalance: Double = 450
    var fastMockProgression: Bool = false

    private init() {}
}
#else
// Stub for release builds — properties always return false/empty
class DebugSettings {
    static let shared = DebugSettings()
    let isSimulating = false
    let mockCoffeeCardBalance: Double = 0
    private init() {}
}
#endif
