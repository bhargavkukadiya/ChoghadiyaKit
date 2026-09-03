//
//  ChoghadiyaManagerTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import XCTest
@testable import ChoghadiyaKit

/// Thread-safe mock implementation of SunTimesFetching for deterministic testing.
private final class MockSunTimesFetcher: SunTimesFetching, @unchecked Sendable {
    var stubbedSunTimes: SunTimes?
    var stubbedError: Error?

    var capturedLocation: String?
    var capturedCoordinates: (latitude: Double, longitude: Double, timeZone: TimeZone)?

    func fetchSunTimes(for location: String, date: Date) async throws -> SunTimes {
        capturedLocation = location
        if let error = stubbedError { throw error }
        if let sunTimes = stubbedSunTimes { return sunTimes }
        throw ChoghadiyaError.locationNotFound
    }

    func fetchSunTimes(latitude: Double, longitude: Double, timeZone: TimeZone, date: Date) async throws -> SunTimes {
        capturedCoordinates = (latitude, longitude, timeZone)
        if let error = stubbedError { throw error }
        if let sunTimes = stubbedSunTimes { return sunTimes }
        throw ChoghadiyaError.invalidResponse
    }
}

final class ChoghadiyaManagerTests: XCTestCase {

    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!

    private func makeStubSunTimes() -> SunTimes {
        let baseDate = Date(timeIntervalSince1970: 1700000000)
        let sunrise = baseDate
        let sunset = baseDate.addingTimeInterval(43200)
        let nextSunrise = baseDate.addingTimeInterval(86400)
        return SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
    }

    func testGetScheduleForLocation() async throws {
        let mockFetcher = MockSunTimesFetcher()
        mockFetcher.stubbedSunTimes = makeStubSunTimes()

        let manager = ChoghadiyaManager(fetcher: mockFetcher)
        let schedule = try await manager.getSchedule(for: "Ahmedabad, India")

        XCTAssertEqual(mockFetcher.capturedLocation, "Ahmedabad, India")
        XCTAssertEqual(schedule.daySlots.count, 8)
        XCTAssertEqual(schedule.nightSlots.count, 8)
    }

    func testGetScheduleForCoordinates() async throws {
        let mockFetcher = MockSunTimesFetcher()
        mockFetcher.stubbedSunTimes = makeStubSunTimes()

        let manager = ChoghadiyaManager(fetcher: mockFetcher)
        let schedule = try await manager.getSchedule(
            latitude: 23.0225,
            longitude: 72.5714,
            timeZone: timeZone
        )

        XCTAssertEqual(mockFetcher.capturedCoordinates?.latitude, 23.0225)
        XCTAssertEqual(mockFetcher.capturedCoordinates?.longitude, 72.5714)
        XCTAssertEqual(schedule.daySlots.count, 8)
        XCTAssertEqual(schedule.nightSlots.count, 8)
    }

    func testErrorPropagation() async {
        let mockFetcher = MockSunTimesFetcher()
        mockFetcher.stubbedError = ChoghadiyaError.locationNotFound

        let manager = ChoghadiyaManager(fetcher: mockFetcher)

        do {
            _ = try await manager.getSchedule(for: "NonExistentCityXYZ")
            XCTFail("Expected locationNotFound error to be thrown")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .locationNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
