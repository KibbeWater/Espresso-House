//
//  HockeyAPIKey.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import SwiftUI

struct EspressoAPIKey: EnvironmentKey {
    static let defaultValue = EspressoAPI() // Provide a default instance if needed
}

struct ActiveOrderVMKey: EnvironmentKey {
    static let defaultValue = ActiveOrderViewModel()
}

extension EnvironmentValues {
    var espressoAPI: EspressoAPI {
        get { self[EspressoAPIKey.self] }
        set { self[EspressoAPIKey.self] = newValue }
    }

    var activeOrderVM: ActiveOrderViewModel {
        get { self[ActiveOrderVMKey.self] }
        set { self[ActiveOrderVMKey.self] = newValue }
    }
}
