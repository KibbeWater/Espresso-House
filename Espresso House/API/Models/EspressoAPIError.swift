//
//  EspressoAPIError.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//

import Foundation

enum EspressoAPIError: Error, LocalizedError, Equatable {
    case networkError
    case decodingError
    case notFound
    case serverError(statusCode: Int)
    case internalError(description: String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error occurred. Please try again."
        case .decodingError:
            return "Failed to decode the response."
        case .notFound:
            return "Resource not found."
        case .serverError(let statusCode):
            return "Server error with status code \(statusCode)."
        case .internalError(let description):
            return "Internal error: \(description)."
        case .unauthorized:
            return "Unauthorized."
        }
    }
}
