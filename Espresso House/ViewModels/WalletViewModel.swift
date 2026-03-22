//
//  WalletViewModel.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

class WalletViewModel: ObservableObject {
    private var api = EspressoAPI.shared
    
    @Published var points: Int = 0
    
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
        
        await MainActor.run {
            self.points = member.fikaPoints
        }
    }
}
