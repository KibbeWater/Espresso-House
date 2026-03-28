//
//  PaymentOption.swift
//  Espresso House
//
//  Created by Claude on 27/3/26.
//

import Foundation

struct PaymentOptionsResponse: Codable {
    let paymentOptions: [PaymentOption]?

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.paymentOptions = try? container.decode([PaymentOption].self, forKey: .paymentOptions)
        } else if let array = try? decoder.singleValueContainer().decode([PaymentOption].self) {
            self.paymentOptions = array
        } else {
            self.paymentOptions = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case paymentOptions
    }
}

struct PaymentOption: Codable, Identifiable, Hashable {
    var id: String { paymentIdentifier }

    let paymentType: String          // e.g. "CreditCard", "CoffeeCard"
    let paymentIdentifier: String    // UUID or memberId
    let displayName: String?         // e.g. "Visa *4242"
    let cardBrand: String?           // e.g. "Visa", "Mastercard"
    let maskedCardNumber: String?    // e.g. "**** 4242"
    let expiryDate: String?          // e.g. "12/28"
    var balanceAmount: Double?       // Only set for CoffeeCard

    var isCoffeeCard: Bool { paymentType == "CoffeeCard" }

    var displayLabel: String {
        if let displayName { return displayName }
        if let brand = cardBrand, let masked = maskedCardNumber {
            return "\(brand) \(masked)"
        }
        return paymentType
    }

    var iconName: String {
        if isCoffeeCard { return "cup.and.saucer.fill" }
        switch cardBrand?.lowercased() {
        case "visa": return "creditcard.fill"
        case "mastercard", "mc": return "creditcard.fill"
        default: return "creditcard"
        }
    }

    static func coffeeCard(memberId: String, balance: Balance) -> PaymentOption {
        PaymentOption(
            paymentType: "CoffeeCard",
            paymentIdentifier: memberId,
            displayName: "Coffee Card (\(Int(balance.amount)) \(balance.currency))",
            cardBrand: nil,
            maskedCardNumber: nil,
            expiryDate: nil,
            balanceAmount: balance.amount
        )
    }
}
