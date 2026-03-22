//
//  MainViewModel.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

class MainViewModel: ObservableObject {
    private let api = EspressoAPI.shared
    
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var points: Int = 0
    @Published var coupons: [Coupon] = []
    @Published var challenges: [Challenge] = []
    
    init() {
        Task {
            do {
                try await refresh()
            } catch (let err) {
                print(err)
            }
        }
    }
    
    func refresh() async throws {
        let member = try await api.member.getMember()
        let challenges = try await api.member.getChallenges()
        
        await MainActor.run {
            self.firstName = member.firstName
            self.lastName = member.lastName
            self.points = member.fikaPoints
            self.challenges = challenges
            self.coupons = member.coupons
        }
    }
}
