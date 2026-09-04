//
//  APISunTimesFetcherTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import XCTest
@testable import ChoghadiyaKit

/// Thread-safe storage for MockURLProtocol request handlers compatible with Swift 5.9+.
final class RequestHandlerStorage: @unchecked Sendable {
    static let shared = RequestHandlerStorage()
    private let lock = NSLock()
    private var _handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _handler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _handler = newValue
        }
    }
}

/// Custom URLProtocol to intercept network requests and return deterministic stubbed responses.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get { RequestHandlerStorage.shared.handler }
        set { RequestHandlerStorage.shared.handler = newValue }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received request without a handler")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class APISunTimesFetcherTests: XCTestCase {

    private var session: URLSession!
    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!
    private let testDate = Date(timeIntervalSince1970: 1788420000)

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        session = nil
        super.tearDown()
    }

    // MARK: - Coordinate Range & Finiteness Tests

    func testLatitudeTooHighThrowsInvalidCoordinates() async {
        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: 100.0, longitude: 72.0, timeZone: timeZone, date: testDate)
            XCTFail("Expected invalidCoordinates error")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .invalidCoordinates)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLatitudeTooLowThrowsInvalidCoordinates() async {
        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: -90.1, longitude: 72.0, timeZone: timeZone, date: testDate)
            XCTFail("Expected invalidCoordinates error")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .invalidCoordinates)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLongitudeTooHighThrowsInvalidCoordinates() async {
        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: 23.0, longitude: 180.1, timeZone: timeZone, date: testDate)
            XCTFail("Expected invalidCoordinates error")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .invalidCoordinates)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLongitudeTooLowThrowsInvalidCoordinates() async {
        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: 23.0, longitude: -180.1, timeZone: timeZone, date: testDate)
            XCTFail("Expected invalidCoordinates error")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .invalidCoordinates)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNaNCoordinatesThrowInvalidCoordinates() async {
        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: .nan, longitude: 72.0, timeZone: timeZone, date: testDate)
            XCTFail("Expected invalidCoordinates error")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .invalidCoordinates)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInfiniteCoordinatesThrowInvalidCoordinates() async {
        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: 23.0, longitude: .infinity, timeZone: timeZone, date: testDate)
            XCTFail("Expected invalidCoordinates error")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .invalidCoordinates)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Local Calendar Day Verification Tests

    func testReturnedWrongCalendarDayThrowsInvalidSunTimes() async throws {
        // Request for 2026-09-03, but stub API response always returns sunrise for 2026-09-04
        MockURLProtocol.requestHandler = { request in
            let json = """
            {
                "results": {
                    "sunrise": "2026-09-04T06:23:00+05:30",
                    "sunset": "2026-09-04T18:34:00+05:30"
                },
                "status": "OK"
            }
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 9
        comps.day = 3
        comps.hour = 12
        let targetDate = cal.date(from: comps)!

        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: 23.0, longitude: 72.0, timeZone: timeZone, date: targetDate)
            XCTFail("Expected invalidSunTimes error because returned local date did not match target date")
        } catch let error as ChoghadiyaError {
            XCTAssertEqual(error, .invalidSunTimes)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidReturnedDataConstructsSunTimes() async throws {
        // Stub API responses: today (2026-09-03) and tomorrow (2026-09-04)
        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            let json: String
            if urlString.contains("date=2026-09-03") {
                json = """
                {
                    "results": {
                        "sunrise": "2026-09-03T06:21:00+05:30",
                        "sunset": "2026-09-03T18:56:00+05:30"
                    },
                    "status": "OK"
                }
                """
            } else {
                json = """
                {
                    "results": {
                        "sunrise": "2026-09-04T06:22:00+05:30",
                        "sunset": "2026-09-04T18:55:00+05:30"
                    },
                    "status": "OK"
                }
                """
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 9
        comps.day = 3
        comps.hour = 12
        let targetDate = cal.date(from: comps)!

        let fetcher = APISunTimesFetcher(session: session)
        let sunTimes = try await fetcher.fetchSunTimes(latitude: 23.0225, longitude: 72.5714, timeZone: timeZone, date: targetDate)

        XCTAssertTrue(cal.isDate(sunTimes.sunrise, inSameDayAs: targetDate))
        XCTAssertTrue(sunTimes.sunrise < sunTimes.sunset)
        XCTAssertTrue(sunTimes.sunset < sunTimes.nextSunrise)
    }

    func testAucklandDaylightSavingQueriesCorrectDate() async throws {
        let aucklandTZ = TimeZone(identifier: "Pacific/Auckland")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = aucklandTZ
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 1
        comps.day = 15
        comps.hour = 12
        let targetDate = cal.date(from: comps)!

        var queriedDates: [String] = []

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            if let query = URLComponents(string: urlString)?.queryItems?.first(where: { $0.name == "date" })?.value {
                queriedDates.append(query)
            }
            let json: String
            if urlString.contains("date=2026-01-15") {
                json = """
                {
                    "results": {
                        "sunrise": "2026-01-15T06:16:32+13:00",
                        "sunset": "2026-01-15T20:43:49+13:00"
                    },
                    "status": "OK"
                }
                """
            } else {
                json = """
                {
                    "results": {
                        "sunrise": "2026-01-16T06:17:34+13:00",
                        "sunset": "2026-01-16T20:43:24+13:00"
                    },
                    "status": "OK"
                }
                """
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let fetcher = APISunTimesFetcher(session: session)
        let sunTimes = try await fetcher.fetchSunTimes(
            latitude: -36.8485,
            longitude: 174.7633,
            timeZone: aucklandTZ,
            date: targetDate
        )

        XCTAssertTrue(cal.isDate(sunTimes.sunrise, inSameDayAs: targetDate))
        XCTAssertTrue(queriedDates.contains("2026-01-15"))
    }

    func testKiritimatiExtremeTimezoneQueriesCorrectShiftedDate() async throws {
        let kiritimatiTZ = TimeZone(identifier: "Pacific/Kiritimati")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kiritimatiTZ
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 9
        comps.day = 3
        comps.hour = 12
        let targetDate = cal.date(from: comps)!

        var queriedDates: [String] = []

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            if let query = URLComponents(string: urlString)?.queryItems?.first(where: { $0.name == "date" })?.value {
                queriedDates.append(query)
            }
            let json: String
            if urlString.contains("date=2026-09-02") {
                json = """
                {
                    "results": {
                        "sunrise": "2026-09-03T06:23:48+14:00",
                        "sunset": "2026-09-03T18:34:41+14:00"
                    },
                    "status": "OK"
                }
                """
            } else {
                json = """
                {
                    "results": {
                        "sunrise": "2026-09-04T06:23:32+14:00",
                        "sunset": "2026-09-04T18:34:18+14:00"
                    },
                    "status": "OK"
                }
                """
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let fetcher = APISunTimesFetcher(session: session)
        let sunTimes = try await fetcher.fetchSunTimes(
            latitude: 1.8721,
            longitude: -157.4278,
            timeZone: kiritimatiTZ,
            date: targetDate
        )

        XCTAssertTrue(cal.isDate(sunTimes.sunrise, inSameDayAs: targetDate))
        XCTAssertTrue(queriedDates.contains("2026-09-02"))
    }
}
