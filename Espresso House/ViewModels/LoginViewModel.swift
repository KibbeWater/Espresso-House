//
//  LoginViewModel.swift
//  Espresso House
//

import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    enum LoginState {
        case phoneEntry
        case loading(String)
        case smsEntry
        case error(String)
    }

    @Published var phoneNumber: String = ""
    @Published var smsCode: String = ""
    @Published var state: LoginState = .phoneEntry

    private var registrationId: String?
    private var sharedSecret: String?
    private var powDifficulty: Int = 3

    private let api = EspressoAPI.shared

    func submitPhone() async {
        let msisdn = PhoneFormatter.toInternational(phoneNumber)
        state = .loading("Connecting...")

        do {
            let reg = try await api.auth.register(msisdn: msisdn, countryCode: "SE")
            registrationId = reg.memberRegistrationId
            sharedSecret = reg.sharedSecret
            powDifficulty = reg.powDifficulty

            state = .loading("Sending SMS...")
            try await api.auth.sendSMS(registrationId: reg.memberRegistrationId, difficulty: powDifficulty)

            state = .smsEntry
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func submitSMSCode() async {
        guard let registrationId, let sharedSecret else {
            state = .error("Missing registration data. Please try again.")
            return
        }

        state = .loading("Verifying...")

        do {
            let result = try await api.auth.verify(registrationId: registrationId, code: smsCode)
            SharedVars.shared.save(
                memberId: result.myEspressoHouseNumber,
                sharedSecret: sharedSecret,
                smsCode: smsCode
            )
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func retry() {
        phoneNumber = ""
        smsCode = ""
        registrationId = nil
        sharedSecret = nil
        state = .phoneEntry
    }
}
