//
//  PhoneFormatter.swift
//  Espresso House
//

import Foundation

struct PhoneFormatter {
    /// Convert "0701234567" to "46701234567" (strip leading 0, prepend country calling code).
    static func toInternational(_ number: String, callingCode: String = "46") -> String {
        var cleaned = number.filter { $0.isNumber }
        if cleaned.hasPrefix("0") {
            cleaned = String(cleaned.dropFirst())
        }
        return callingCode + cleaned
    }
}
