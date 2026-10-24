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
    case timeZoneUnavailable
    case timeZoneMismatch
    case polarDayOrNight

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
        case .timeZoneUnavailable:
            return "Could not determine the time zone of the specified location."
        case .timeZoneMismatch:
            return "The supplied time zone does not match the location; it would assign sunrise to a different weekday. Use the location's own time zone."
        case .polarDayOrNight:
            return "The sun does not rise or set at this location on the requested date (polar day or polar night)."
        }
    }
}
