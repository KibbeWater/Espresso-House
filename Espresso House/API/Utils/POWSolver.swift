//
//  POWSolver.swift
//  Espresso House
//

import Foundation
import CryptoKit

struct POWSolver {
    private static let charset = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    private static let nonceLength = 100

    /// Solve POW: find 100-char nonce from [A-Z0-9] where SHA256(challenge + nonce) starts with `difficulty` zeros.
    static func solve(challenge: String, difficulty: Int = 3) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let prefix = Array(challenge.utf8)
                let target = String(repeating: "0", count: difficulty)

                while true {
                    let nonce = randomNonce()
                    let input = prefix + Array(nonce.utf8)
                    let hash = SHA256.hash(data: input)
                    let hex = hash.map { String(format: "%02x", $0) }.joined()
                    if hex.hasPrefix(target) {
                        continuation.resume(returning: nonce)
                        return
                    }
                }
            }
        }
    }

    /// Build the first POW challenge string.
    static func buildChallenge(deviceId: String, msisdn: String, countryCode: String, buildNumber: String, timestamp: String) -> String {
        "iPhone_\(deviceId)_\(msisdn)_\(countryCode)_\(buildNumber)_\(timestamp)"
    }

    /// Build the registration timestamp in the required format: "yyyy-MM-dd HH:mm:ss.SSSSSS"
    static func buildTimestamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let base = formatter.string(from: now)
        let microseconds = Int(now.timeIntervalSince1970.truncatingRemainder(dividingBy: 1) * 1_000_000)
        return "\(base).\(String(format: "%06d", microseconds))"
    }

    /// Compute BPAuth hash: SHA256(sharedSecret + smsCode) uppercased hex.
    static func buildAuthToken(sharedSecret: String, smsCode: String) -> String {
        let input = sharedSecret + smsCode
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.map { String(format: "%02X", $0) }.joined()
    }

    private static func randomNonce() -> String {
        String((0..<nonceLength).map { _ in charset.randomElement()! })
    }
}
