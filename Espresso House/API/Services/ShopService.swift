//
//  ShopService.swift
//  Espresso House
//
//  Created by KibbeWater on 19/12/24.
//

import Foundation

struct Shops: Codable {
    let coffeeShops: [CoffeeShop]
}

class ShopService: ShopServiceProtocol {
    private let networkManager: NetworkManager
    private let cache = initCache(forKey: "ShopService")
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func resetCache() {
        try? cache.removeAll()
    }
    
    func getShops() async throws -> [CoffeeShop] {
        let shopsStorage = cache.transformCodable(ofType: [CoffeeShop].self)
        
        if let cachedShops = try? await shopsStorage.async.object(forKey: "coffee-shops") {
            return cachedShops
        }
        
        let req: Shops = try await networkManager.request(endpoint: Endpoint.getShops)
        
        try? await shopsStorage.async.setObject(req.coffeeShops, forKey: "coffee-shops", expiry: .seconds(7 * 24 * 60 * 60))
        
        return req.coffeeShops
    }
}
