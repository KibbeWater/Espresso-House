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
    var mockOrderStatus: String = "Created"

    private init() {}
}
#else
// Stub for release builds — properties always return false/empty
class DebugSettings {
    static let shared = DebugSettings()
    let isSimulating = false
    private init() {}
}
#endif
