//
//  PassGenerator.swift
//  Espresso House
//
//  Created by Claude on 29/3/26.
//

import Foundation
import PassKit

enum PassGeneratorError: LocalizedError {
    case serverError(String)
    case invalidPassData
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return "Pass server error: \(message)"
        case .invalidPassData:
            return "Server returned invalid pass data."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

struct PassGenerator {
    private static let passTypeIdentifier = "pass.com.kibbewater.coffee-shop"
    private static let endpoint = "https://pass.lrlnet.se"
    private static let apiKey = "832cdfffd0036b51adcd045f66ac26c456a72c3f0a4c459808f1f8db372a1403"

    // MARK: - Public API

    static func generatePass(memberId: String, firstName: String, lastName: String, pinCode: String? = nil) async throws -> PKPass {
        let url = URL(string: endpoint)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: String] = [
            "memberId": memberId,
            "firstName": firstName,
            "lastName": lastName
        ]
        if let pinCode {
            body["pinCode"] = pinCode
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PassGeneratorError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PassGeneratorError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["error"] as? String {
                errorMessage = msg
            } else {
                errorMessage = "HTTP \(httpResponse.statusCode)"
            }
            throw PassGeneratorError.serverError(errorMessage)
        }

        guard httpResponse.mimeType == "application/vnd.apple.pkpass" else {
            throw PassGeneratorError.invalidPassData
        }

        do {
            return try PKPass(data: data)
        } catch {
            throw PassGeneratorError.invalidPassData
        }
    }

    static func isPassInWallet(memberId: String) -> Bool {
        let library = PKPassLibrary()
        let serialNumber = "member-\(memberId)"
        return library.passes().contains { pass in
            pass.passTypeIdentifier == passTypeIdentifier && pass.serialNumber == serialNumber
        }
    }
}
