//
//  SharedVars.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import Foundation

class SharedVars: ObservableObject {
    public static let shared = SharedVars()

    @Published var memberId: String?
    @Published var deviceId: String
    @Published var sharedSecret: String?
    @Published var smsCode: String?

    var isAuthenticated: Bool {
        memberId != nil && sharedSecret != nil && smsCode != nil
    }

    var bpAuth: String? {
        guard let memberId, let sharedSecret, let smsCode else { return nil }
        let authToken = POWSolver.buildAuthToken(sharedSecret: sharedSecret, smsCode: smsCode)
        return "\(memberId);\(deviceId);\(authToken)"
    }

    private init() {
        // Device ID: persist in UserDefaults, generate if absent
        if let stored = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = stored
        } else {
            let newId = UUID().uuidString.uppercased()
            UserDefaults.standard.set(newId, forKey: "deviceId")
            self.deviceId = newId
        }

        // Load credentials from Keychain
        self.memberId = KeychainHelper.read(key: "memberId")
        self.sharedSecret = KeychainHelper.read(key: "sharedSecret")
        self.smsCode = KeychainHelper.read(key: "smsCode")
    }

    func save(memberId: String, sharedSecret: String, smsCode: String) {
        KeychainHelper.save(key: "memberId", value: memberId)
        KeychainHelper.save(key: "sharedSecret", value: sharedSecret)
        KeychainHelper.save(key: "smsCode", value: smsCode)

        self.memberId = memberId
        self.sharedSecret = sharedSecret
        self.smsCode = smsCode
    }

    func logout() {
        KeychainHelper.delete(key: "memberId")
        KeychainHelper.delete(key: "sharedSecret")
        KeychainHelper.delete(key: "smsCode")

        self.memberId = nil
        self.sharedSecret = nil
        self.smsCode = nil
    }
}
