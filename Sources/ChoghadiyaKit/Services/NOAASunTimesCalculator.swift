//
//  NOAASunTimesCalculator.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Offline solar engine computing sunrise and sunset with the NOAA solar position algorithm.
///
/// Coordinate-based calculations make no network requests, so they work in widgets, complications,
/// and without connectivity. Results typically agree with the Sunrise-Sunset.org API to within a minute;
/// near the polar circles, where the sun grazes the horizon, differences of a few minutes are normal.
/// Address-based lookups still need the network for geocoding.
public final class NOAASunTimesCalculator: SunTimesFetching, Sendable {

    // MARK: - Properties

    private let geocoder: Geocoder

    // MARK: - Init

    public convenience init() {
        self.init(geocoder: { try await Geocoding.coreLocation($0) })
    }

    init(geocoder: @escaping Geocoder) {
        self.geocoder = geocoder
    }

    // MARK: - SunTimesFetching

    /// Computes solar times for a human-readable location address.
    /// - Note: Geocoding the address uses `CLGeocoder`, which requires network access. Use the coordinate-based
    ///   methods for fully offline calculation.
    /// - Parameters:
    ///   - location: Location string (e.g. "Ahmedabad, India").
    ///   - date: Target date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
    /// - Throws: `ChoghadiyaError.timeZoneUnavailable` if the geocoded location has no time zone.
    public func fetchSunTimes(for location: String, date: Date) async throws -> SunTimes {
        let (lat, lon, timeZone) = try await Geocoding.resolve(location, using: geocoder)
        return try sunTimes(latitude: lat, longitude: lon, timeZone: timeZone, date: date)
    }

    /// Computes solar times offline for geographic coordinates; equivalent to `sunTimes(latitude:longitude:timeZone:date:)`.
    public func fetchSunTimes(latitude: Double, longitude: Double, timeZone: TimeZone, date: Date) async throws -> SunTimes {
        try sunTimes(latitude: latitude, longitude: longitude, timeZone: timeZone, date: date)
    }

    // MARK: - Offline Calculation

    /// Computes solar times offline and synchronously for geographic coordinates.
    /// - Parameters:
    ///   - latitude: Geographic latitude.
    ///   - longitude: Geographic longitude.
    ///   - timeZone: The location's own time zone; it determines the target calendar day and the Vedic weekday.
    ///   - date: Target date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
    /// - Throws: `ChoghadiyaError.invalidCoordinates` for out-of-range coordinates,
    ///   `ChoghadiyaError.timeZoneMismatch` if `timeZone` would assign sunrise to a different weekday than the
    ///   location's longitude implies, and `ChoghadiyaError.polarDayOrNight` if the sun does not rise or set.
    public func sunTimes(latitude: Double, longitude: Double, timeZone: TimeZone, date: Date = Date()) throws -> SunTimes {
        try SolarLocationValidation.validateCoordinates(latitude: latitude, longitude: longitude)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
            throw ChoghadiyaError.parsingError
        }

        let (sunrise, noon) = try sunrise(onDayOf: date, calendar: calendar, latitude: latitude, longitude: longitude)
        let sunset = try NOAASolarPosition.time(of: .sunset, solarNoon: noon, latitude: latitude, longitude: longitude)
        // Only the next day's sunrise is needed; it may have no sunset of its own as the midnight sun begins.
        let (nextSunrise, _) = try self.sunrise(onDayOf: nextDate, calendar: calendar, latitude: latitude, longitude: longitude)

        try SolarLocationValidation.validateTimeZone(timeZone, latitude: latitude, longitude: longitude, sunrise: sunrise)

        guard sunrise < sunset && sunset < nextSunrise else {
            throw ChoghadiyaError.invalidSunTimes
        }

        return SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
    }

    // MARK: - Private Helpers

    /// Sunrise on the calendar day of `date` in `calendar`'s time zone, and the solar noon that follows it.
    private func sunrise(
        onDayOf date: Date,
        calendar: Calendar,
        latitude: Double,
        longitude: Double
    ) throws -> (sunrise: Date, solarNoon: Date) {
        guard let civilNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else {
            throw ChoghadiyaError.parsingError
        }

        // The day's sunrise normally precedes the solar noon nearest civil noon; in a time zone far from local
        // solar time it can precede the adjacent one instead.
        var sunDidNotCross = false
        for dayOffset in [0.0, -1.0, 1.0] {
            let noon = NOAASolarPosition.solarNoon(near: civilNoon.addingTimeInterval(dayOffset * 86_400), longitude: longitude)
            let sunrise: Date
            do {
                sunrise = try NOAASolarPosition.time(of: .sunrise, solarNoon: noon, latitude: latitude, longitude: longitude)
            } catch ChoghadiyaError.polarDayOrNight {
                sunDidNotCross = true
                continue
            }
            if calendar.isDate(sunrise, inSameDayAs: date) {
                return (sunrise, noon)
            }
        }

        throw sunDidNotCross ? ChoghadiyaError.polarDayOrNight : ChoghadiyaError.invalidSunTimes
    }
}
