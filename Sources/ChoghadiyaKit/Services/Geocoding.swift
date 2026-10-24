//
//  Geocoding.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation
import CoreLocation

/// Result of forward geocoding an address string.
struct GeocodedLocation: Sendable {
    let latitude: Double
    let longitude: Double
    let timeZone: TimeZone?
}

/// Resolves an address to a location, or `nil` when nothing matches.
typealias Geocoder = @Sendable (String) async throws -> GeocodedLocation?

/// Address lookup shared by the solar time providers.
enum Geocoding {
    /// Resolves an address to coordinates and the location's own time zone.
    /// - Throws: `ChoghadiyaError.geocodingFailed`, `.locationNotFound`, or `.timeZoneUnavailable`.
    static func resolve(_ location: String, using geocoder: Geocoder) async throws -> (lat: Double, lon: Double, timeZone: TimeZone) {
        let match: GeocodedLocation?
        do {
            match = try await geocoder(location)
        } catch {
            throw ChoghadiyaError.geocodingFailed(error.localizedDescription)
        }

        guard let match else {
            throw ChoghadiyaError.locationNotFound
        }

        guard let timeZone = match.timeZone else {
            throw ChoghadiyaError.timeZoneUnavailable
        }

        return (match.latitude, match.longitude, timeZone)
    }

    /// Forward geocodes with `CLGeocoder`, which requires network access.
    static func coreLocation(_ address: String) async throws -> GeocodedLocation? {
        let placemarks = try await CLGeocoder().geocodeAddressString(address)
        guard let placemark = placemarks.first, let loc = placemark.location else {
            return nil
        }
        return GeocodedLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, timeZone: placemark.timeZone)
    }
}
