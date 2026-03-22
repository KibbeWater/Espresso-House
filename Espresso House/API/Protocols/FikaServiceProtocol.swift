//
//  FikaServiceProtocol.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

public protocol FikaServiceProtocol {
    func fetchOffers() async throws -> [FikaOffer]
}
