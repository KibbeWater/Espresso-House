//
//  AuthService.swift
//  Espresso House
//

import Foundation

class AuthService: AuthServiceProtocol {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func register(msisdn: String, countryCode: String) async throws -> RegistrationResponse {
        let deviceId = SharedVars.shared.deviceId
        let timestamp = POWSolver.buildTimestamp()
        let buildNumber = "3555"

        let challenge = POWSolver.buildChallenge(
            deviceId: deviceId,
            msisdn: msisdn,
            countryCode: countryCode,
            buildNumber: buildNumber,
            timestamp: timestamp
        )

        let pow = await POWSolver.solve(challenge: challenge, difficulty: 3)

        let body = RegistrationRequest(
            deviceId: deviceId,
            msisdn: msisdn,
            registrationStartedTime: timestamp,
            clientApplicationBuildNumber: buildNumber,
            clientApplicationDeviceType: "iPhone",
            countryCode: countryCode,
            pow: pow
        )

        return try await networkManager.post(endpoint: Endpoint.register, body: body, authenticated: false)
    }

    func sendSMS(registrationId: String, difficulty: Int) async throws {
        let pow = await POWSolver.solve(challenge: registrationId, difficulty: difficulty)
        let body = SendSMSRequest(pow: pow)
        try await networkManager.postRaw(endpoint: Endpoint.sendSMS(registrationId), body: body, authenticated: false)
    }

    func verify(registrationId: String, code: String) async throws -> VerificationResponse {
        let body = VerifyRequest(verificationCode: code)
        return try await networkManager.post(endpoint: Endpoint.verify(registrationId), body: body, authenticated: false)
    }
}

// MARK: - Request Bodies

private struct RegistrationRequest: Encodable {
    let deviceId: String
    let msisdn: String
    let registrationStartedTime: String
    let clientApplicationBuildNumber: String
    let clientApplicationDeviceType: String
    let countryCode: String
    let pow: String
}

private struct SendSMSRequest: Encodable {
    let pow: String
}

private struct VerifyRequest: Encodable {
    let verificationCode: String
}
