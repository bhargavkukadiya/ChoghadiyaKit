//
//  SunTimes.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Data container for astronomical solar boundaries for a given location and day.
public struct SunTimes: Equatable, Hashable, Codable, Sendable {
    /// Sunrise timestamp on the given date.
    public let sunrise: Date

    /// Sunset timestamp on the given date.
    public let sunset: Date

    /// Sunrise timestamp on the following calendar day.
    public let nextSunrise: Date

    /// Local timezone of the observed location.
    public let timeZone: TimeZone

    /// Duration of daylight in seconds.
    public var daylightDuration: TimeInterval {
        sunset.timeIntervalSince(sunrise)
    }

    /// Duration of the night period in seconds.
    public var nighttimeDuration: TimeInterval {
        nextSunrise.timeIntervalSince(sunset)
    }

    /// Validates that astronomical boundaries are chronologically consistent (`sunrise < sunset < nextSunrise`).
    public var isValid: Bool {
        sunrise < sunset && sunset < nextSunrise
    }

    /// Initializes an astronomical sun times record.
    public init(sunrise: Date, sunset: Date, nextSunrise: Date, timeZone: TimeZone) {
        self.sunrise = sunrise
        self.sunset = sunset
        self.nextSunrise = nextSunrise
        self.timeZone = timeZone
    }
}
