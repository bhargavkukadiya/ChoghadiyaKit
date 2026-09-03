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
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let dateFormatter = Self.makeDateFormatter(timeZone: timeZone)
        let dateString = dateFormatter.string(from: date)

        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
            throw ChoghadiyaError.parsingError
        }
        let nextDateString = dateFormatter.string(from: nextDate)

        // Concurrent requests for today and next day
        let currentSession = self.session
        async let todayResponse = Self.fetchSunriseData(session: currentSession, lat: latitude, lon: longitude, dateString: dateString, timeZone: timeZone)
        async let nextResponse = Self.fetchSunriseData(session: currentSession, lat: latitude, lon: longitude, dateString: nextDateString, timeZone: timeZone)

        let (todayData, nextData) = try await (todayResponse, nextResponse)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        guard let sunrise = isoFormatter.date(from: todayData.results.sunrise),
              let sunset = isoFormatter.date(from: todayData.results.sunset),
              let nextSunrise = isoFormatter.date(from: nextData.results.sunrise) else {
            throw ChoghadiyaError.parsingError
        }

        guard sunrise < sunset && sunset < nextSunrise else {
            throw ChoghadiyaError.invalidSunTimes
        }

        return SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
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

    private static func makeDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter
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
