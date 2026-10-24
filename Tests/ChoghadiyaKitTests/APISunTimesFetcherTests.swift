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

    // MARK: - Time Zone / Location Consistency Tests

    func testTimeZoneValidationRejectsZonesThatShiftTheWeekday() throws {
        let iso = ISO8601DateFormatter()
        let cases: [(sunrise: String, latitude: Double, longitude: Double, zone: String, accepted: Bool)] = [
            ("2026-10-24T06:30:00-10:00", 21.3069, -157.8583, "Pacific/Honolulu", true),
            ("2026-10-24T06:30:00-10:00", 21.3069, -157.8583, "Asia/Tokyo", false),
            // Same longitude band as the Line Islands, but Honolulu is not Kiribati territory.
            ("2026-10-24T06:30:00-10:00", 21.3069, -157.8583, "Pacific/Kiritimati", false),
            ("2026-09-03T06:23:48+14:00", 1.8721, -157.4278, "Pacific/Kiritimati", true),
            ("2026-09-03T06:23:48+14:00", 1.8721, -157.4278, "Etc/GMT-14", false),
            ("2026-09-04T06:01:00+14:00", -9.9500, -150.2100, "Pacific/Kiritimati", true),
            // Jarvis Island (US) lies between Kiribati's Line Island groups.
            ("2026-09-04T06:40:00+14:00", -0.3744, -160.0071, "Pacific/Kiritimati", false),
            ("2026-10-25T07:33:00+12:00", 64.3800, -173.2300, "Asia/Anadyr", true),
            // Gambell, St. Lawrence Island, Alaska, lies just south of Chukotka at the same longitude.
            ("2026-10-24T11:27:00-08:00", 63.7770, -171.7150, "Asia/Anadyr", false),
            ("2026-10-24T11:27:00-08:00", 63.7770, -171.7150, "America/Nome", true),
            ("2026-10-24T06:10:00+13:00", -13.8333, -171.7600, "Pacific/Apia", true),
            ("2026-10-24T05:50:00+13:00", -21.1394, -175.2018, "Pacific/Tongatapu", true),
            ("2026-06-21T08:27:00-09:00", 52.9300, 173.2000, "America/Adak", true),
            ("2026-10-24T06:40:00+05:30", 23.0225, 72.5714, "UTC", true),
            ("2026-10-24T06:40:00+05:30", 23.0225, 72.5714, "America/New_York", false),
            ("2026-10-24T05:55:00+09:00", 35.6762, 139.6917, "UTC", false)
        ]
        for testCase in cases {
            let sunrise = try XCTUnwrap(iso.date(from: testCase.sunrise))
            let zone = try XCTUnwrap(TimeZone(identifier: testCase.zone))
            let label = "\(testCase.zone) at \(testCase.latitude), \(testCase.longitude)"
            let validate = {
                try SolarLocationValidation.validateTimeZone(zone, latitude: testCase.latitude, longitude: testCase.longitude, sunrise: sunrise)
            }
            if testCase.accepted {
                XCTAssertNoThrow(try validate(), label)
            } else {
                XCTAssertThrowsError(try validate(), label) {
                    XCTAssertEqual($0 as? ChoghadiyaError, .timeZoneMismatch, label)
                }
            }
        }
    }

    func testHonoluluWithTokyoTimeZoneThrowsTimeZoneMismatch() async throws {
        // Mirrors the live API: with tzid=Asia/Tokyo, querying date D returns Honolulu's sunrise of D,
        // which falls at 01:30 JST on D+1.
        MockURLProtocol.requestHandler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
            let dateString = query?.first(where: { $0.name == "date" })?.value ?? ""
            let parser = DateFormatter()
            parser.dateFormat = "yyyy-MM-dd"
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.timeZone = TimeZone(identifier: "Asia/Tokyo")
            let next = parser.string(from: parser.date(from: dateString)!.addingTimeInterval(86_400))
            let json = """
            {"results": {"sunrise": "\(next)T01:30:00+09:00", "sunset": "\(next)T13:00:00+09:00"}, "status": "OK"}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tokyo
        let targetDate = cal.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 12))!

        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: 21.3069, longitude: -157.8583, timeZone: tokyo, date: targetDate)
            XCTFail("Expected timeZoneMismatch: Honolulu's Saturday sunrise would be labelled Sunday")
        } catch {
            XCTAssertEqual(error as? ChoghadiyaError, .timeZoneMismatch)
        }
    }

    // MARK: - Geocoding Tests

    func testGeocodedLocationWithoutTimeZoneThrowsTimeZoneUnavailable() async {
        MockURLProtocol.requestHandler = { _ in
            XCTFail("No solar request should be made without a time zone")
            throw URLError(.cancelled)
        }
        let fetcher = APISunTimesFetcher(session: session) { _ in
            GeocodedLocation(latitude: 23.0225, longitude: 72.5714, timeZone: nil)
        }
        do {
            _ = try await fetcher.fetchSunTimes(for: "Ahmedabad, India", date: testDate)
            XCTFail("Expected timeZoneUnavailable")
        } catch {
            XCTAssertEqual(error as? ChoghadiyaError, .timeZoneUnavailable)
        }
    }

    func testGeocoderWithoutMatchThrowsLocationNotFound() async {
        let fetcher = APISunTimesFetcher(session: session) { _ in nil }
        do {
            _ = try await fetcher.fetchSunTimes(for: "NonExistentCityXYZ", date: testDate)
            XCTFail("Expected locationNotFound")
        } catch {
            XCTAssertEqual(error as? ChoghadiyaError, .locationNotFound)
        }
    }

    func testGeocodedTimeZoneIsSentToAPI() async throws {
        let requestLog = RequestLog()
        MockURLProtocol.requestHandler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
            requestLog.append(query?.first(where: { $0.name == "tzid" })?.value ?? "")
            let day = query?.first(where: { $0.name == "date" })?.value ?? ""
            let json = """
            {"results": {"sunrise": "\(day)T06:21:00+05:30", "sunset": "\(day)T18:56:00+05:30"}, "status": "OK"}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }
        let fetcher = APISunTimesFetcher(session: session) { _ in
            GeocodedLocation(latitude: 23.0225, longitude: 72.5714, timeZone: TimeZone(identifier: "Asia/Kolkata"))
        }

        let sunTimes = try await fetcher.fetchSunTimes(for: "Ahmedabad, India", date: testDate)

        XCTAssertEqual(sunTimes.timeZone.identifier, "Asia/Kolkata")
        XCTAssertEqual(requestLog.entries, ["Asia/Kolkata", "Asia/Kolkata"])
    }

    // MARK: - Polar Day / Night Tests

    func testGenuineSolarTimesOnEpochDayAreAccepted() async throws {
        // Ordinary Ahmedabad sunrise and sunset on 1970-01-01 lie within a day of the Unix epoch
        // but are not the API's polar placeholders.
        MockURLProtocol.requestHandler = { request in
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
            let day = query?.first(where: { $0.name == "date" })?.value ?? ""
            let json = """
            {"results": {"sunrise": "\(day)T07:20:00+05:30", "sunset": "\(day)T18:05:00+05:30"}, "status": "OK"}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let targetDate = cal.date(from: DateComponents(year: 1970, month: 1, day: 1, hour: 12))!

        let fetcher = APISunTimesFetcher(session: session)
        let sunTimes = try await fetcher.fetchSunTimes(latitude: 23.0225, longitude: 72.5714, timeZone: timeZone, date: targetDate)

        XCTAssertTrue(cal.isDate(sunTimes.sunrise, inSameDayAs: targetDate))
        XCTAssertTrue(sunTimes.isValid)
    }

    func testPolarDayAndPartialPlaceholdersThrowPolarDayOrNight() async {
        let oslo = TimeZone(identifier: "Europe/Oslo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = oslo
        let targetDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 21, hour: 12))!
        let fetcher = APISunTimesFetcher(session: session)

        // Polar day (live API response for Tromsø on 2026-06-21), then a lone placeholder sunset.
        let placeholderPairs = [
            ("1970-01-01T01:00:01+01:00", "1970-01-01T01:00:01+01:00"),
            ("2026-06-21T01:30:00+02:00", "1970-01-01T00:00:00+00:00")
        ]
        for (sunrise, sunset) in placeholderPairs {
            MockURLProtocol.requestHandler = { request in
                let json = """
                {"results": {"sunrise": "\(sunrise)", "sunset": "\(sunset)"}, "status": "OK"}
                """
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, Data(json.utf8))
            }
            do {
                _ = try await fetcher.fetchSunTimes(latitude: 69.6492, longitude: 18.9553, timeZone: oslo, date: targetDate)
                XCTFail("Expected polarDayOrNight for \(sunrise) / \(sunset)")
            } catch {
                XCTAssertEqual(error as? ChoghadiyaError, .polarDayOrNight, "\(sunrise) / \(sunset)")
            }
        }
    }

    func testPolarNightPlaceholderTimesThrowPolarDayOrNight() async {
        // Live API response for Tromsø on 2026-12-15: status OK with Unix-epoch placeholders.
        let requestLog = RequestLog()
        MockURLProtocol.requestHandler = { request in
            requestLog.append(request.url?.absoluteString ?? "")
            let json = """
            {"results": {"sunrise": "1970-01-01T01:00:00+01:00", "sunset": "1970-01-01T01:00:00+01:00"}, "status": "OK"}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let oslo = TimeZone(identifier: "Europe/Oslo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = oslo
        let targetDate = cal.date(from: DateComponents(year: 2026, month: 12, day: 15, hour: 12))!

        let fetcher = APISunTimesFetcher(session: session)
        do {
            _ = try await fetcher.fetchSunTimes(latitude: 69.6492, longitude: 18.9553, timeZone: oslo, date: targetDate)
            XCTFail("Expected polarDayOrNight")
        } catch {
            XCTAssertEqual(error as? ChoghadiyaError, .polarDayOrNight)
        }
        // One request per day: no re-query toward the placeholder date.
        XCTAssertLessThanOrEqual(requestLog.entries.count, 2)
        XCTAssertFalse(requestLog.entries.contains { !$0.contains("date=2026-12-1") })
    }
}

/// Thread-safe record of values observed by MockURLProtocol handlers.
final class RequestLog: @unchecked Sendable {
    private let lock = NSLock()
    private var _entries: [String] = []

    var entries: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _entries
    }

    func append(_ entry: String) {
        lock.lock()
        defer { lock.unlock() }
        _entries.append(entry)
    }
}
