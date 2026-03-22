//
//  FikaService.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

class FikaService: FikaServiceProtocol {
    private let networkManager: NetworkManager
    private let cache = initCache(forKey: "FikaService")
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func resetCache() {
        try? cache.removeAll()
    }
    
    func fetchOffers() async throws -> [FikaOffer] {
        guard let memberId = SharedVars.shared.memberId else { throw EspressoAPIError.unauthorized }
        let req: FikaOffersResponse = try await networkManager.request(endpoint: Endpoint.getFikaOffers(memberId))
        return req.fikaHouseExchangableCouponReadRowsResponse
    }
}

fileprivate struct FikaOffersResponse: Decodable {
    let fikaHouseExchangableCouponReadRowsResponse: [FikaOffer]
}
