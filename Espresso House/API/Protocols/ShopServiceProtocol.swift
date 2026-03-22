//
//  ShopServiceProtocol.swift
//  Espresso House
//
//  Created by KibbeWater on 19/12/24.
//

import Foundation

public protocol ShopServiceProtocol {
    func getShops() async throws -> [CoffeeShop]
}
