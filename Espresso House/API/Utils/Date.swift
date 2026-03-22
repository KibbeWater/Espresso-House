//
//  Date.swift
//  Espresso House
//
//  Created by KibbeWater on 11/1/25.
//

import Foundation

func parseISODate(from string: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures consistent parsing
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    // Attempt parsing with fractional seconds first
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    if let date = formatter.date(from: string) {
        return date
    }
    
    // Fallback to parsing without fractional seconds
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter.date(from: string)
}
