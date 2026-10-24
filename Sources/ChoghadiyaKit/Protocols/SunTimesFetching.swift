//
//  SunTimesFetching.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Protocol defining astronomical solar times retrieval by address string or geographic coordinates.
public protocol SunTimesFetching: Sendable {
    /// Fetches astronomical solar times for a given location string.
    /// - Parameters:
    ///   - location: Human-readable location string (e.g. "Ahmedabad, India").
    ///   - date: Target calendar date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
    func fetchSunTimes(for location: String, date: Date) async throws -> SunTimes

    /// Fetches astronomical solar times for geographic coordinates and a target time zone.
    /// - Parameters:
    ///   - latitude: Geographic latitude.
    ///   - longitude: Geographic longitude.
    ///   - timeZone: The location's own time zone; it determines the target calendar day and the Vedic weekday.
    ///   - date: Target calendar date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
    func fetchSunTimes(latitude: Double, longitude: Double, timeZone: TimeZone, date: Date) async throws -> SunTimes
}

#if canImport(CoreLocation)
import CoreLocation

extension SunTimesFetching {
    /// Fetches astronomical solar times using a `CLLocationCoordinate2D` coordinate.
    /// - Note: `timeZone` must be the coordinate's own time zone. The `.current` default is only correct
    ///   when the coordinate is in the device's time zone.
    public func fetchSunTimes(
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone = .current,
        date: Date = Date()
    ) async throws -> SunTimes {
        try await fetchSunTimes(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZone: timeZone,
            date: date
        )
    }
}
#endif
