//
//  ChoghadiyaError.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Domain-specific errors thrown by ChoghadiyaKit.
public enum ChoghadiyaError: LocalizedError, Sendable, Equatable {
    case invalidURL
    case invalidCoordinates
    case locationNotFound
    case geocodingFailed(String)
    case invalidResponse
    case parsingError
    case invalidSunTimes

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration."
        case .invalidCoordinates:
            return "Coordinates are out of valid range (-90...90 latitude, -180...180 longitude) or non-finite."
        case .locationNotFound:
            return "Could not find the specified location."
        case .geocodingFailed(let reason):
            return "Geocoding failed: \(reason)"
        case .invalidResponse:
            return "Received an invalid or unsuccessful response from the astronomical server."
        case .parsingError:
            return "Failed to parse the astronomical data from the server."
        case .invalidSunTimes:
            return "Astronomical sunrise and sunset times are inconsistent."
        }
    }
}
