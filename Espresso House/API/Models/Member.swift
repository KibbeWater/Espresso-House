//
//  Member.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

public struct Member: Sendable, Identifiable {
    public var id: String
    
    public var firstName: String
    public var lastName: String
    public var email: String?
    public var phoneNumber: String
    
    public var fikaPoints: Int
    public var pinCode: String?

    public var balance: Balance
    public var coupons: [Coupon]
}

public struct Balance: Sendable {
    public var amount: Double
    public var currency: String
    public var countryCode: String
}
