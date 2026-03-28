//
//  MemberServiceProtocol.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

public protocol MemberServiceProtocol {
    func getMember() async throws -> Member
    func getChallenges() async throws -> [Challenge]
    func getCardRegistrationURL() async throws -> String
    func deletePaymentToken(tokenKey: String) async throws
    func setPreferredPaymentToken(tokenKey: String) async throws
}
