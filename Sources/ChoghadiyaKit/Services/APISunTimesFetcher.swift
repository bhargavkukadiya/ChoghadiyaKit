//
//  APISunTimesFetcher.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Thread-safe networking client for fetching astronomical solar times from the Sunrise-Sunset API.
public final class APISunTimesFetcher: SunTimesFetching, Sendable {

    // MARK: - Properties

    private let session: URLSession
    private let geocoder: Geocoder

    // MARK: - Init

    public convenience init(session: URLSession = .shared) {
        self.init(session: session, geocoder: { try await Geocoding.coreLocation($0) })
    }

    init(session: URLSession, geocoder: @escaping Geocoder) {
        self.session = session
        self.geocoder = geocoder
    }

    // MARK: - SunTimesFetching

    /// Fetches astronomical solar times for a human-readable location address.
    /// - Parameters:
    ///   - location: Location string (e.g. "Ahmedabad, India").
    ///   - date: Target date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
    /// - Throws: `ChoghadiyaError.timeZoneUnavailable` if the geocoded location has no time zone.
    public func fetchSunTimes(for location: String, date: Date) async throws -> SunTimes {
        let (lat, lon, timeZone) = try await Geocoding.resolve(location, using: geocoder)
        return try await fetchSunTimes(latitude: lat, longitude: lon, timeZone: timeZone, date: date)
    }

    /// Fetches astronomical solar times using geographic coordinates and time zone.
    /// - Parameters:
    ///   - latitude: Geographic latitude.
    ///   - longitude: Geographic longitude.
    ///   - timeZone: The location's own time zone; it determines the target calendar day and the Vedic weekday.
    ///   - date: Target date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
    /// - Throws: `ChoghadiyaError.timeZoneMismatch` if `timeZone` would assign sunrise to a different weekday
    ///   than the location's longitude implies, and `ChoghadiyaError.polarDayOrNight` if the sun does not rise or set.
    public func fetchSunTimes(latitude: Double, longitude: Double, timeZone: TimeZone, date: Date) async throws -> SunTimes {
        try SolarLocationValidation.validateCoordinates(latitude: latitude, longitude: longitude)

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone

        guard let nextDate = localCalendar.date(byAdding: .day, value: 1, to: date) else {
            throw ChoghadiyaError.parsingError
        }

        // Concurrently fetch solar times for target date and next date
        async let todaySolar = fetchSolarTimesForDay(
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            targetDate: date
        )

        async let nextSolar = fetchSolarTimesForDay(
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            targetDate: nextDate
        )

        let ((sunrise, sunset), (nextSunrise, _)) = try await (todaySolar, nextSolar)

        try SolarLocationValidation.validateTimeZone(timeZone, latitude: latitude, longitude: longitude, sunrise: sunrise)

        guard sunrise < sunset && sunset < nextSunrise else {
            throw ChoghadiyaError.invalidSunTimes
        }

        return SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
    }

    // MARK: - Solar Retrieval Helpers

    private func fetchSolarTimesForDay(
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone,
        targetDate: Date
    ) async throws -> (sunrise: Date, sunset: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        // Compute initial query date taking into account difference between civil timezone and solar longitude
        let civilOffsetHours = Double(timeZone.secondsFromGMT(for: targetDate)) / 3600.0
        let solarOffsetHours = longitude / 15.0
        let dayShift = Int(((civilOffsetHours - solarOffsetHours) / 24.0).rounded())

        guard let initialQueryDate = calendar.date(byAdding: .day, value: -dayShift, to: targetDate) else {
            throw ChoghadiyaError.parsingError
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = timeZone

        var currentQueryDate = initialQueryDate
        var currentQueryString = dateFormatter.string(from: currentQueryDate)

        var data = try await Self.fetchSunriseData(
            session: self.session,
            lat: latitude,
            lon: longitude,
            dateString: currentQueryString,
            timeZone: timeZone
        )

        var (sunrise, sunset) = try Self.parseSolarTimes(data.results, queryDate: currentQueryDate)

        // If returned sunrise does not match targetDate in timeZone, perform a self-correcting re-query
        if !calendar.isDate(sunrise, inSameDayAs: targetDate) {
            let startOfTarget = calendar.startOfDay(for: targetDate)
            let startOfReturned = calendar.startOfDay(for: sunrise)
            let dayDiff = calendar.dateComponents([.day], from: startOfTarget, to: startOfReturned).day ?? 0

            // A genuine API date offset is at most a day or two; anything larger is not correctable.
            guard abs(dayDiff) <= 2 else {
                throw ChoghadiyaError.invalidSunTimes
            }

            if dayDiff != 0, let correctedDate = calendar.date(byAdding: .day, value: -dayDiff, to: currentQueryDate) {
                currentQueryDate = correctedDate
                currentQueryString = dateFormatter.string(from: currentQueryDate)

                data = try await Self.fetchSunriseData(
                    session: self.session,
                    lat: latitude,
                    lon: longitude,
                    dateString: currentQueryString,
                    timeZone: timeZone
                )

                (sunrise, sunset) = try Self.parseSolarTimes(data.results, queryDate: currentQueryDate)
            }
        }

        // Final verification that the returned local solar day strictly matches targetDate
        guard calendar.isDate(sunrise, inSameDayAs: targetDate) else {
            throw ChoghadiyaError.invalidSunTimes
        }

        return (sunrise, sunset)
    }

    /// Parses sunrise and sunset timestamps, detecting the placeholders the API returns when the sun
    /// does not rise or set: exactly 1970-01-01T00:00:00Z (polar night) or 00:00:01Z (polar day).
    /// - Parameter queryDate: The date that was requested. Near the epoch a lone placeholder value could be a
    ///   genuine time, so only a pair of placeholders (a day length of at most one second) counts there.
    private static func parseSolarTimes(_ results: SunriseSunsetResults, queryDate: Date) throws -> (sunrise: Date, sunset: Date) {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        guard let sunrise = isoFormatter.date(from: results.sunrise),
              let sunset = isoFormatter.date(from: results.sunset) else {
            throw ChoghadiyaError.parsingError
        }

        let placeholderTimestamps: Set<TimeInterval> = [0, 1]
        let sunriseIsPlaceholder = placeholderTimestamps.contains(sunrise.timeIntervalSince1970)
        let sunsetIsPlaceholder = placeholderTimestamps.contains(sunset.timeIntervalSince1970)
        let queryIsNearEpoch = abs(queryDate.timeIntervalSince1970) < 2 * 86_400

        if (sunriseIsPlaceholder && sunsetIsPlaceholder)
            || (!queryIsNearEpoch && (sunriseIsPlaceholder || sunsetIsPlaceholder)) {
            throw ChoghadiyaError.polarDayOrNight
        }

        return (sunrise, sunset)
    }

    // MARK: - Private API Helpers

    private struct SunriseSunsetResponse: Decodable, Sendable {
        let results: SunriseSunsetResults
        let status: String
    }

    private struct SunriseSunsetResults: Decodable, Sendable {
        let sunrise: String
        let sunset: String
    }

    private static func fetchSunriseData(
        session: URLSession,
        lat: Double,
        lon: Double,
        dateString: String,
        timeZone: TimeZone
    ) async throws -> SunriseSunsetResponse {
        var components = URLComponents(string: "https://api.sunrise-sunset.org/json")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lng", value: "\(lon)"),
            URLQueryItem(name: "date", value: dateString),
            URLQueryItem(name: "formatted", value: "0"),
            URLQueryItem(name: "tzid", value: timeZone.identifier)
        ]

        guard let url = components?.url else {
            throw ChoghadiyaError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ChoghadiyaError.invalidResponse
        }

        let result: SunriseSunsetResponse
        do {
            result = try JSONDecoder().decode(SunriseSunsetResponse.self, from: data)
        } catch {
            throw ChoghadiyaError.parsingError
        }

        guard result.status == "OK" else {
            throw ChoghadiyaError.invalidResponse
        }

        return result
    }
}
