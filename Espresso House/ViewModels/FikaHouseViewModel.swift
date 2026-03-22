//
//  FikaHouseViewModel.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

class FikaHouseViewModel: ObservableObject {
    private let api = EspressoAPI.shared
    
    @Published var points: Int = 0
    @Published var offers: [FikaOffer] = []
    
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
        let offers = try await api.fika.fetchOffers()
        
        await MainActor.run {
            self.points = member.fikaPoints
            self.offers = offers
        }
    }
}
