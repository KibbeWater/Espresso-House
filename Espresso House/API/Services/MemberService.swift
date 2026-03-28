//
//  MemberService.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

class MemberService: MemberServiceProtocol {
    private let networkManager: NetworkManager
    private let cache = initCache(forKey: "MemberService")
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func resetCache() {
        try? cache.removeAll()
    }
    
    func getMember() async throws -> Member {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let req: MemberResponse = try await networkManager.request(endpoint: Endpoint.getMember(memberId))
        return req.toMember()
    }

    func getChallenges() async throws -> [Challenge] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let req: ChallengeResult = try await networkManager.request(endpoint: Endpoint.getChallenges(memberId))
        return req.memberChallenges
    }

    func getCardRegistrationURL() async throws -> String {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let response: CardRegistrationResponse = try await networkManager.request(
            endpoint: Endpoint.getCardRegistrationURL(memberId: memberId)
        )
        return response.paymentCardRegistrationUrl
    }

    func deletePaymentToken(tokenKey: String) async throws {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        try await networkManager.delete(
            endpoint: Endpoint.deletePaymentToken(memberId: memberId, tokenKey: tokenKey)
        )
    }

    func setPreferredPaymentToken(tokenKey: String) async throws {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        // PUT with empty body to set as preferred
        struct EmptyBody: Encodable {}
        try await networkManager.putRaw(
            endpoint: Endpoint.setPreferredPaymentToken(memberId: memberId, tokenKey: tokenKey),
            body: EmptyBody(),
            authenticated: true
        )
    }
}

fileprivate struct ChallengeResult: Decodable {
    let memberChallenges: [Challenge]
}

fileprivate struct MemberResponse: Decodable {
    let fikaClub: FikaClub
    
    let myEspressoHouseNumber: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let email: String?
    
    let coupons: [Coupon]
    let balance: BBalance
    
    func toMember() -> Member {
        Member(
            id: self.myEspressoHouseNumber,
            firstName: self.firstName,
            lastName: self.lastName,
            email: self.email,
            phoneNumber: self.phoneNumber,
            fikaPoints: self.fikaClub.fikaPoints,
            balance: self.balance.toBalance(),
            coupons: self.coupons
        )
    }
    
    class FikaClub: Decodable {
        let fikaPoints: Int
    }
    
    class BBalance: Decodable {
        let amount: Double
        let currency: String
        let countryCode: String
        
        func toBalance() -> Balance {
            Balance(amount: amount, currency: currency, countryCode: countryCode)
        }
    }
}
