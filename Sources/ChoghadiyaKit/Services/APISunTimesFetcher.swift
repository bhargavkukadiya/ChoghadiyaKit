//
//  APISunTimesFetcher.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation
import CoreLocation

/// Thread-safe networking client for fetching astronomical solar times from the Sunrise-Sunset API.
public final class APISunTimesFetcher: SunTimesFetching, Sendable {

    // MARK: - Types

    /// Result of forward geocoding an address string.
    struct GeocodedLocation: Sendable {
        let latitude: Double
        let longitude: Double
        let timeZone: TimeZone?
    }

    /// Resolves an address to a location, or `nil` when nothing matches.
    typealias Geocoder = @Sendable (String) async throws -> GeocodedLocation?

    // MARK: - Constants

    /// Largest accepted gap, in hours, between a time zone's UTC offset and local mean solar time
    /// when the zone places sunrise on a different calendar day than local solar time does.
    /// Real-world zones stay within about 3 hours.
    private static let maxSolarOffsetDeviationHours = 4.0

    /// Territory lying across the date line from its time zone's calendar day. Inside these regions the civil
    /// weekday is a full day away from the solar one by local convention, so the gap check does not apply.
    /// Regions are drawn tightly around the territory's own land so that neighbouring land under another
    /// calendar day (St. Lawrence Island, Alaska, beside Chukotka; Jarvis Island beside the Line Islands;
    /// American Samoa beside Samoa) is excluded.
    private struct DateLineTerritory {
        struct Region {
            let latitudes: ClosedRange<Double>
            let longitudes: ClosedRange<Double>
        }

        let timeZoneIdentifiers: Set<String>
        let regions: [Region]

        func contains(timeZone: TimeZone, latitude: Double, longitude: Double) -> Bool {
            timeZoneIdentifiers.contains(timeZone.identifier)
                && regions.contains { $0.latitudes.contains(latitude) && $0.longitudes.contains(longitude) }
        }
    }

    private static let dateLineTerritories: [DateLineTerritory] = [
        // Line Islands, Kiribati (UTC+14): Teraina, Tabuaeran, and Kiritimati; Malden and Starbuck;
        // Caroline, Vostok, and Flint
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Kiritimati"], regions: [
            .init(latitudes: 1.5...5.0, longitudes: -160.6...(-157.0)),
            .init(latitudes: -5.8...(-3.8), longitudes: -156.1...(-154.7)),
            .init(latitudes: -11.6...(-9.8), longitudes: -152.6...(-150.0))
        ]),
        // Phoenix Islands, Kiribati (UTC+13)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Kanton", "Pacific/Enderbury"], regions: [
            .init(latitudes: -5.5...(-2.0), longitudes: -175.5...(-170.0))
        ]),
        // Samoa (UTC+13), west of American Samoa's Tutuila
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Apia"], regions: [
            .init(latitudes: -14.3...(-13.2), longitudes: -173.0...(-171.2))
        ]),
        // Tokelau (UTC+13), north of Swains Island
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Fakaofo"], regions: [
            .init(latitudes: -9.7...(-8.3), longitudes: -172.8...(-170.9))
        ]),
        // Tonga (UTC+13)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Tongatapu"], regions: [
            .init(latitudes: -23.0...(-15.0), longitudes: -176.5...(-173.0))
        ]),
        // Wallis and Futuna (UTC+12)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Wallis"], regions: [
            .init(latitudes: -14.6...(-13.0), longitudes: -178.5...(-175.9))
        ]),
        // Fiji's Lau group (UTC+12)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Fiji"], regions: [
            .init(latitudes: -21.5...(-15.0), longitudes: -180.0...(-178.0))
        ]),
        // Chatham Islands, New Zealand (UTC+12:45)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Chatham", "NZ-CHAT"], regions: [
            .init(latitudes: -44.7...(-43.3), longitudes: -177.2...(-175.5))
        ]),
        // Kermadec Islands, New Zealand (UTC+12)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Auckland", "NZ"], regions: [
            .init(latitudes: -31.8...(-29.0), longitudes: -179.2...(-177.5))
        ]),
        // Ross Dependency, Antarctica (New Zealand time)
        DateLineTerritory(timeZoneIdentifiers: ["Antarctica/McMurdo", "Antarctica/South_Pole"], regions: [
            .init(latitudes: -90.0...(-60.0), longitudes: -180.0...(-150.0))
        ]),
        // Chukotka east of 180° (UTC+12): Cape Chukotsky (64.2° N) northward to Wrangel Island, west of the
        // Diomede border. St. Lawrence Island, Alaska, ends at 63.8° N.
        DateLineTerritory(timeZoneIdentifiers: ["Asia/Anadyr"], regions: [
            .init(latitudes: 64.0...72.0, longitudes: -180.0...(-169.0))
        ]),
        // Western Aleutians west of 180° (UTC−10)
        DateLineTerritory(timeZoneIdentifiers: ["America/Adak", "America/Atka", "US/Aleutian"], regions: [
            .init(latitudes: 50.5...54.0, longitudes: 172.0...180.0)
        ])
    ]

    // MARK: - Properties

    private let session: URLSession
    private let geocoder: Geocoder

    // MARK: - Init

    public convenience init(session: URLSession = .shared) {
        self.init(session: session, geocoder: { try await Self.geocodeWithCoreLocation($0) })
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
        let (lat, lon, timeZone) = try await geocode(location: location)
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
        guard latitude.isFinite, (-90.0...90.0).contains(latitude),
              longitude.isFinite, (-180.0...180.0).contains(longitude) else {
            throw ChoghadiyaError.invalidCoordinates
        }

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

        try Self.validateTimeZone(timeZone, latitude: latitude, longitude: longitude, sunrise: sunrise)

        guard sunrise < sunset && sunset < nextSunrise else {
            throw ChoghadiyaError.invalidSunTimes
        }

        return SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
    }

    // MARK: - Time Zone Validation

    /// Rejects a time zone that assigns sunrise to a different calendar day (and so a different Vedic weekday)
    /// than local mean solar time does, unless the coordinates lie in that zone's territory across the date line.
    static func validateTimeZone(_ timeZone: TimeZone, latitude: Double, longitude: Double, sunrise: Date) throws {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var civilCalendar = Calendar(identifier: .gregorian)
        civilCalendar.timeZone = timeZone

        let solarOffsetHours = longitude / 15.0
        let solarDay = utcCalendar.dateComponents([.year, .month, .day], from: sunrise.addingTimeInterval(solarOffsetHours * 3600))
        let civilDay = civilCalendar.dateComponents([.year, .month, .day], from: sunrise)

        guard solarDay.year != civilDay.year || solarDay.month != civilDay.month || solarDay.day != civilDay.day else {
            return
        }

        let deviation = abs(Double(timeZone.secondsFromGMT(for: sunrise)) / 3600.0 - solarOffsetHours)
        if deviation <= maxSolarOffsetDeviationHours {
            return
        }

        let isDateLineTerritory = dateLineTerritories.contains {
            $0.contains(timeZone: timeZone, latitude: latitude, longitude: longitude)
        }
        guard isDateLineTerritory else {
            throw ChoghadiyaError.timeZoneMismatch
        }
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

    // MARK: - Geocoding

    private func geocode(location: String) async throws -> (lat: Double, lon: Double, timeZone: TimeZone) {
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

    private static func geocodeWithCoreLocation(_ address: String) async throws -> GeocodedLocation? {
        let placemarks = try await CLGeocoder().geocodeAddressString(address)
        guard let placemark = placemarks.first, let loc = placemark.location else {
            return nil
        }
        return GeocodedLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, timeZone: placemark.timeZone)
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
