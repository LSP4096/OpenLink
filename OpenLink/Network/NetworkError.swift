//
//  NetworkError.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidUrl
    case requestFailed(String)
    case serverError(code: Int, message: String)
    case decodingError
    case unauthorized
    case forbidden
    case unexpectedResponse
    case connectionLost
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Invalid URL"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Session expired"
        case .forbidden:
            return "Access forbidden"
        case .unexpectedResponse:
            return "Unexpected response from server"
        case .connectionLost:
            return "The internet connection appears to be offline"
        }
    }
}
