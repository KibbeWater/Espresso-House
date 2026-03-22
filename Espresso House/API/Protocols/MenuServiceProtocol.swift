//
//  MatchServiceProtocol.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//


import Foundation

public protocol MenuServiceProtocol {
    func getMenu() async throws -> [MenuCategory]
}
