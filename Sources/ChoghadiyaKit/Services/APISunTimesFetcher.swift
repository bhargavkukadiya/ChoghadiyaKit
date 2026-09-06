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

    // MARK: - Properties

    private let session: URLSession

    // MARK: - Init

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - SunTimesFetching

    /// Fetches astronomical solar times for a human-readable location address.
    /// - Parameters:
    ///   - location: Location string (e.g. "Ahmedabad, India").
    ///   - date: Target date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
    public func fetchSunTimes(for location: String, date: Date) async throws -> SunTimes {
        let (lat, lon, timeZone) = try await geocode(location: location)
        return try await fetchSunTimes(latitude: lat, longitude: lon, timeZone: timeZone, date: date)
    }

    /// Fetches astronomical solar times using geographic coordinates and time zone.
    /// - Parameters:
    ///   - latitude: Geographic latitude.
    ///   - longitude: Geographic longitude.
    ///   - timeZone: Target time zone.
    ///   - date: Target date.
    /// - Returns: `SunTimes` containing sunrise, sunset, and next sunrise.
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

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        guard var sunrise = isoFormatter.date(from: data.results.sunrise),
              var sunset = isoFormatter.date(from: data.results.sunset) else {
            throw ChoghadiyaError.parsingError
        }

        // If returned sunrise does not match targetDate in timeZone, perform a self-correcting re-query
        if !calendar.isDate(sunrise, inSameDayAs: targetDate) {
            let startOfTarget = calendar.startOfDay(for: targetDate)
            let startOfReturned = calendar.startOfDay(for: sunrise)
            let dayDiff = calendar.dateComponents([.day], from: startOfTarget, to: startOfReturned).day ?? 0

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

                guard let reSunrise = isoFormatter.date(from: data.results.sunrise),
                      let reSunset = isoFormatter.date(from: data.results.sunset) else {
                    throw ChoghadiyaError.parsingError
                }

                sunrise = reSunrise
                sunset = reSunset
            }
        }

        // Final verification that the returned local solar day strictly matches targetDate
        guard calendar.isDate(sunrise, inSameDayAs: targetDate) else {
            throw ChoghadiyaError.invalidSunTimes
        }

        return (sunrise, sunset)
    }

    // MARK: - Geocoding

    private func geocode(location: String) async throws -> (lat: Double, lon: Double, timeZone: TimeZone) {
        let geocoder = CLGeocoder()
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.geocodeAddressString(location)
        } catch {
            throw ChoghadiyaError.geocodingFailed(error.localizedDescription)
        }

        guard let placemark = placemarks.first,
              let loc = placemark.location else {
            throw ChoghadiyaError.locationNotFound
        }

        let timeZone = placemark.timeZone ?? .current
        return (loc.coordinate.latitude, loc.coordinate.longitude, timeZone)
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
