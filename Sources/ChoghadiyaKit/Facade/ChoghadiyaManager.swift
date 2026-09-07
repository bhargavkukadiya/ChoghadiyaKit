//
//  ChoghadiyaManager.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// High-level facade coordinating astronomical data retrieval and Vedic Choghadiya schedule computation.
public final class ChoghadiyaManager: Sendable {

    // MARK: - Properties

    private let fetcher: SunTimesFetching
    private let calculator: ChoghadiyaCalculating

    // MARK: - Init

    /// Initializes the manager with injected fetcher and calculator abstractions.
    /// - Parameters:
    ///   - fetcher: Implementation conforming to `SunTimesFetching`. Defaults to `APISunTimesFetcher`.
    ///   - calculator: Implementation conforming to `ChoghadiyaCalculating`. Defaults to `ChoghadiyaCalculator`.
    public init(
        fetcher: SunTimesFetching = APISunTimesFetcher(),
        calculator: ChoghadiyaCalculating = ChoghadiyaCalculator()
    ) {
        self.fetcher = fetcher
        self.calculator = calculator
    }

    // MARK: - Public Methods

    /// Computes the Choghadiya schedule for a given location address string.
    /// - Parameters:
    ///   - location: Location address string (e.g., "Ahmedabad, India").
    ///   - date: Target date; defaults to current date.
    /// - Returns: `ChoghadiyaSchedule` with day and night slots.
    /// - Throws: `ChoghadiyaError.invalidSunTimes` for invalid solar boundaries; otherwise propagates errors from the configured fetcher.
    public func getSchedule(for location: String, date: Date = Date()) async throws -> ChoghadiyaSchedule {
        let sunTimes = try await fetcher.fetchSunTimes(for: location, date: date)
        guard sunTimes.isValid else { throw ChoghadiyaError.invalidSunTimes }
        return calculator.calculateSchedule(for: date, sunTimes: sunTimes)
    }

    /// Computes the Choghadiya schedule using pre-resolved geographic coordinates and time zone.
    /// Bypasses forward geocoding, making it ideal for Widget extensions and location services.
    /// - Parameters:
    ///   - latitude: Geographic latitude.
    ///   - longitude: Geographic longitude.
    ///   - timeZone: Target time zone.
    ///   - date: Target date; defaults to current date.
    /// - Returns: `ChoghadiyaSchedule` with day and night slots.
    /// - Throws: `ChoghadiyaError.invalidSunTimes` for invalid solar boundaries; otherwise propagates errors from the configured fetcher.
    public func getSchedule(
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone,
        date: Date = Date()
    ) async throws -> ChoghadiyaSchedule {
        let sunTimes = try await fetcher.fetchSunTimes(
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            date: date
        )
        guard sunTimes.isValid else { throw ChoghadiyaError.invalidSunTimes }
        return calculator.calculateSchedule(for: date, sunTimes: sunTimes)
    }
}

#if canImport(CoreLocation)
import CoreLocation

extension ChoghadiyaManager {
    /// Computes the Choghadiya schedule using a `CLLocationCoordinate2D` coordinate and time zone.
    /// - Parameters:
    ///   - coordinate: Geographic coordinate (`CLLocationCoordinate2D`).
    ///   - timeZone: Target time zone; defaults to `TimeZone.current`.
    ///   - date: Target date; defaults to current date.
    /// - Returns: `ChoghadiyaSchedule` with day and night slots.
    /// - Throws: `ChoghadiyaError.invalidSunTimes` for invalid solar boundaries; otherwise propagates errors from the configured fetcher.
    public func getSchedule(
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone = .current,
        date: Date = Date()
    ) async throws -> ChoghadiyaSchedule {
        try await getSchedule(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZone: timeZone,
            date: date
        )
    }
}
#endif
