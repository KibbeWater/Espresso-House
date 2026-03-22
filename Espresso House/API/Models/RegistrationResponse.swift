//
//  RegistrationResponse.swift
//  Espresso House
//

import Foundation

struct RegistrationResponse: Decodable {
    let memberRegistrationId: String
    let powDifficulty: Int
    let sharedSecret: String
}
