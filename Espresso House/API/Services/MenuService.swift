//
//  MatchService.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

struct Menu: Codable {
    let menu: [MenuCategory]
}

class MenuService: MenuServiceProtocol {
    private let networkManager: NetworkManager
    private let cache = initCache(forKey: "MenuService")
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func resetCache() {
        try? cache.removeAll()
    }
    
    func getMenu() async throws -> [MenuCategory] {
        let req: Menu = try await networkManager.request(endpoint: Endpoint.getMenu)
        return req.menu
    }
}
