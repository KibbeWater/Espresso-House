//
//  AuthServiceProtocol.swift
//  Espresso House
//

import Foundation

protocol AuthServiceProtocol {
    func register(msisdn: String, countryCode: String) async throws -> RegistrationResponse
    func sendSMS(registrationId: String, difficulty: Int) async throws
    func verify(registrationId: String, code: String) async throws -> VerificationResponse
}
