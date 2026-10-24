//
//  NOAASunTimesCalculatorTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import XCTest
@testable import ChoghadiyaKit

final class NOAASunTimesCalculatorTests: XCTestCase {

    private let calculator = NOAASunTimesCalculator(geocoder: { _ in nil })
    private let iso = ISO8601DateFormatter()

    private func noon(_ year: Int, _ month: Int, _ day: Int, in timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // MARK: - Accuracy

    func testMatchesSunriseSunsetAPIReferenceTimes() throws {
        // Reference values from api.sunrise-sunset.org (formatted=0) for each location's own calendar day.
        let references: [(name: String, latitude: Double, longitude: Double, zone: String, day: (Int, Int, Int), sunrise: String, sunset: String, tolerance: TimeInterval)] = [
            ("Ahmedabad", 23.0225, 72.5714, "Asia/Kolkata", (2026, 10, 24), "2026-10-24T06:40:28+05:30", "2026-10-24T18:07:22+05:30", 60),
            ("London", 51.5074, -0.1278, "Europe/London", (2026, 6, 21), "2026-06-21T04:43:04+01:00", "2026-06-21T21:21:36+01:00", 60),
            ("New York", 40.7128, -74.0060, "America/New_York", (2026, 12, 21), "2026-12-21T07:16:31-05:00", "2026-12-21T16:31:51-05:00", 60),
            ("Sydney", -33.8688, 151.2093, "Australia/Sydney", (2026, 3, 15), "2026-03-15T06:54:12+11:00", "2026-03-15T19:14:09+11:00", 60),
            ("Quito", -0.1807, -78.4678, "America/Guayaquil", (2026, 9, 23), "2026-09-23T06:02:45-05:00", "2026-09-23T18:09:33-05:00", 60),
            ("Honolulu", 21.3069, -157.8583, "Pacific/Honolulu", (2026, 10, 24), "2026-10-24T06:30:51-10:00", "2026-10-24T18:00:17-10:00", 60),
            ("Kiritimati", 1.8721, -157.4278, "Pacific/Kiritimati", (2026, 9, 3), "2026-09-03T06:24:49+14:00", "2026-09-03T18:33:40+14:00", 60),
            ("Reykjavik", 64.1466, -21.9426, "Atlantic/Reykjavik", (2026, 3, 29), "2026-03-29T06:55:27+00:00", "2026-03-29T20:09:33+00:00", 90),
            // The sun barely clears the horizon, so small declination differences move the times by minutes.
            ("Tromsø", 69.6492, 18.9553, "Europe/Oslo", (2026, 11, 26), "2026-11-26T10:55:47+01:00", "2026-11-26T12:07:05+01:00", 180)
        ]

        for reference in references {
            let zone = try XCTUnwrap(TimeZone(identifier: reference.zone))
            let date = noon(reference.day.0, reference.day.1, reference.day.2, in: zone)
            let sunTimes = try calculator.sunTimes(latitude: reference.latitude, longitude: reference.longitude, timeZone: zone, date: date)

            let expectedSunrise = try XCTUnwrap(iso.date(from: reference.sunrise))
            let expectedSunset = try XCTUnwrap(iso.date(from: reference.sunset))
            XCTAssertEqual(sunTimes.sunrise.timeIntervalSince1970, expectedSunrise.timeIntervalSince1970, accuracy: reference.tolerance, "\(reference.name) sunrise")
            XCTAssertEqual(sunTimes.sunset.timeIntervalSince1970, expectedSunset.timeIntervalSince1970, accuracy: reference.tolerance, "\(reference.name) sunset")
            XCTAssertTrue(sunTimes.isValid, reference.name)
        }
    }

    func testNextSunriseIsTheFollowingDaysSunrise() throws {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        let today = try calculator.sunTimes(latitude: 23.0225, longitude: 72.5714, timeZone: zone, date: noon(2026, 10, 24, in: zone))
        let tomorrow = try calculator.sunTimes(latitude: 23.0225, longitude: 72.5714, timeZone: zone, date: noon(2026, 10, 25, in: zone))

        XCTAssertEqual(today.nextSunrise, tomorrow.sunrise)
        XCTAssertEqual(today.nighttimeDuration + today.daylightDuration, 86_400, accuracy: 120)
    }

    func testTargetDayFollowsTheSuppliedTimeZoneNotTheInstant() throws {
        // 23:30 IST on 2026-10-24 is 18:00 UTC: the schedule must still be for the 24th in Kolkata.
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let lateEvening = calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 23, minute: 30))!

        let sunTimes = try calculator.sunTimes(latitude: 23.0225, longitude: 72.5714, timeZone: zone, date: lateEvening)

        XCTAssertTrue(calendar.isDate(sunTimes.sunrise, inSameDayAs: lateEvening))
    }

    func testAsyncFetchMatchesSynchronousCalculation() async throws {
        let zone = TimeZone(identifier: "Europe/London")!
        let date = noon(2026, 6, 21, in: zone)
        let synchronous = try calculator.sunTimes(latitude: 51.5074, longitude: -0.1278, timeZone: zone, date: date)
        let asynchronous = try await calculator.fetchSunTimes(latitude: 51.5074, longitude: -0.1278, timeZone: zone, date: date)
        XCTAssertEqual(synchronous, asynchronous)
    }

    // MARK: - Failure Cases

    func testPolarDayAndNightThrowPolarDayOrNight() {
        let oslo = TimeZone(identifier: "Europe/Oslo")!
        for date in [noon(2026, 12, 15, in: oslo), noon(2026, 6, 21, in: oslo)] {
            XCTAssertThrowsError(try calculator.sunTimes(latitude: 69.6492, longitude: 18.9553, timeZone: oslo, date: date)) {
                XCTAssertEqual($0 as? ChoghadiyaError, .polarDayOrNight)
            }
        }
    }

    // MARK: - Polar Transitions

    private func localTime(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    func testSunriseShortlyAfterMidnightBeforeMidnightSunIsFound() throws {
        // Tromsø, 2026-05-17: the sun sets after midnight and rises again at about 00:51 on the 18th,
        // the last sunrise before the midnight sun. Declination at the 18th's solar noon alone says the sun never sets.
        let oslo = TimeZone(identifier: "Europe/Oslo")!
        let sunTimes = try calculator.sunTimes(latitude: 69.6492, longitude: 18.9553, timeZone: oslo, date: noon(2026, 5, 17, in: oslo))

        XCTAssertTrue(sunTimes.isValid)
        XCTAssertTrue(localTime(sunTimes.sunset, in: oslo).hasPrefix("2026-05-18 00:"), localTime(sunTimes.sunset, in: oslo))
        XCTAssertTrue(localTime(sunTimes.nextSunrise, in: oslo).hasPrefix("2026-05-18 00:"), localTime(sunTimes.nextSunrise, in: oslo))
    }

    func testNextDayWithoutSunsetDoesNotBlockSchedule() throws {
        // Longyearbyen, 2026-04-17: sunrise 02:07, sunset 00:12 on the 18th, next sunrise 01:38.
        // The 18th itself has no sunset, which this schedule does not need.
        let longyearbyen = TimeZone(identifier: "Arctic/Longyearbyen")!
        let sunTimes = try calculator.sunTimes(latitude: 78.2232, longitude: 15.6267, timeZone: longyearbyen, date: noon(2026, 4, 17, in: longyearbyen))

        XCTAssertTrue(sunTimes.isValid)
        XCTAssertTrue(localTime(sunTimes.sunrise, in: longyearbyen).hasPrefix("2026-04-17 02:"), localTime(sunTimes.sunrise, in: longyearbyen))
        XCTAssertTrue(localTime(sunTimes.sunset, in: longyearbyen).hasPrefix("2026-04-18 00:"), localTime(sunTimes.sunset, in: longyearbyen))
        XCTAssertTrue(localTime(sunTimes.nextSunrise, in: longyearbyen).hasPrefix("2026-04-18 01:"), localTime(sunTimes.nextSunrise, in: longyearbyen))
    }

    /// Every horizon crossing in `range`, found by sampling the sun's position every two minutes and
    /// bisecting each sign change. Independent of the engine's noon-based search windows.
    private func bruteForceCrossings(latitude: Double, longitude: Double, in range: ClosedRange<Date>) -> [(time: Date, rising: Bool)] {
        func margin(_ t: TimeInterval) -> Double {
            NOAASolarPosition.horizonMargin(at: Date(timeIntervalSince1970: t), latitude: latitude, longitude: longitude)
        }
        var crossings: [(time: Date, rising: Bool)] = []
        var previous = range.lowerBound.timeIntervalSince1970
        var previousUp = margin(previous) > 0
        while previous < range.upperBound.timeIntervalSince1970 {
            let next = previous + 120
            let nextUp = margin(next) > 0
            if nextUp != previousUp {
                var low = previous, high = next
                for _ in 0..<30 {
                    let middle = (low + high) / 2
                    if (margin(middle) > 0) == previousUp { low = middle } else { high = middle }
                }
                crossings.append((Date(timeIntervalSince1970: (low + high) / 2), nextUp))
            }
            previous = next
            previousUp = nextUp
        }
        return crossings
    }

    func testAgreesWithBruteForceHorizonScanThroughoutTheYear() throws {
        // Sites with polar day and night, where noon-based estimates break down around the transitions.
        let sites: [(name: String, latitude: Double, longitude: Double, zone: String)] = [
            ("Tromsø", 69.6492, 18.9553, "Europe/Oslo"),
            ("Longyearbyen", 78.2232, 15.6267, "Arctic/Longyearbyen"),
            ("McMurdo", -77.8419, 166.6863, "Antarctica/McMurdo")
        ]

        for site in sites {
            let zone = try XCTUnwrap(TimeZone(identifier: site.zone))
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            let firstDay = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
            let crossings = bruteForceCrossings(
                latitude: site.latitude,
                longitude: site.longitude,
                in: firstDay.addingTimeInterval(-86_400)...firstDay.addingTimeInterval(368 * 86_400)
            )

            var schedules = 0, polar = 0
            for dayIndex in 0..<365 {
                let day = calendar.date(byAdding: .day, value: dayIndex, to: firstDay)!
                let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
                let date = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day)!
                let label = "\(site.name) \(localTime(date, in: zone).prefix(10))"

                let sunrise = crossings.first { $0.rising && calendar.isDate($0.time, inSameDayAs: day) }?.time
                let sunset = sunrise.flatMap { rise in crossings.first { !$0.rising && $0.time > rise }?.time }
                let nextSunrise = crossings.first { $0.rising && calendar.isDate($0.time, inSameDayAs: nextDay) }?.time

                if let sunrise, let sunset, let nextSunrise, sunset < nextSunrise {
                    let sunTimes = try calculator.sunTimes(latitude: site.latitude, longitude: site.longitude, timeZone: zone, date: date)
                    XCTAssertEqual(sunTimes.sunrise.timeIntervalSince1970, sunrise.timeIntervalSince1970, accuracy: 1, "\(label) sunrise")
                    XCTAssertEqual(sunTimes.sunset.timeIntervalSince1970, sunset.timeIntervalSince1970, accuracy: 1, "\(label) sunset")
                    XCTAssertEqual(sunTimes.nextSunrise.timeIntervalSince1970, nextSunrise.timeIntervalSince1970, accuracy: 1, "\(label) next sunrise")
                    schedules += 1
                } else {
                    XCTAssertThrowsError(try calculator.sunTimes(latitude: site.latitude, longitude: site.longitude, timeZone: zone, date: date), label) {
                        XCTAssertEqual($0 as? ChoghadiyaError, .polarDayOrNight, label)
                    }
                    polar += 1
                }
            }
            // Both regimes must actually be exercised at every site.
            XCTAssertGreaterThan(schedules, 100, site.name)
            XCTAssertGreaterThan(polar, 30, site.name)
        }
    }

    func testMismatchedTimeZoneThrowsTimeZoneMismatch() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        XCTAssertThrowsError(try calculator.sunTimes(latitude: 21.3069, longitude: -157.8583, timeZone: tokyo, date: noon(2026, 10, 25, in: tokyo))) {
            XCTAssertEqual($0 as? ChoghadiyaError, .timeZoneMismatch)
        }
    }

    func testInvalidCoordinatesThrow() {
        let utc = TimeZone(identifier: "UTC")!
        for (latitude, longitude) in [(90.5, 0.0), (0.0, -180.5), (.nan, 0.0), (0.0, .infinity)] {
            XCTAssertThrowsError(try calculator.sunTimes(latitude: latitude, longitude: longitude, timeZone: utc)) {
                XCTAssertEqual($0 as? ChoghadiyaError, .invalidCoordinates)
            }
        }
    }

    // MARK: - Address Lookup

    func testAddressLookupUsesGeocodedTimeZone() async throws {
        let kolkata = TimeZone(identifier: "Asia/Kolkata")!
        let calculator = NOAASunTimesCalculator { _ in
            GeocodedLocation(latitude: 23.0225, longitude: 72.5714, timeZone: kolkata)
        }
        let sunTimes = try await calculator.fetchSunTimes(for: "Ahmedabad, India", date: noon(2026, 10, 24, in: kolkata))
        XCTAssertEqual(sunTimes.timeZone, kolkata)
    }

    func testAddressWithoutTimeZoneThrowsTimeZoneUnavailable() async {
        let calculator = NOAASunTimesCalculator { _ in
            GeocodedLocation(latitude: 23.0225, longitude: 72.5714, timeZone: nil)
        }
        do {
            _ = try await calculator.fetchSunTimes(for: "Ahmedabad, India", date: Date())
            XCTFail("Expected timeZoneUnavailable")
        } catch {
            XCTAssertEqual(error as? ChoghadiyaError, .timeZoneUnavailable)
        }
    }

    func testManagerComputesScheduleOffline() async throws {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        let manager = ChoghadiyaManager(fetcher: calculator)
        let schedule = try await manager.getSchedule(latitude: 23.0225, longitude: 72.5714, timeZone: zone, date: noon(2026, 10, 24, in: zone))

        // 2026-10-24 is a Saturday: the day sequence starts with Kaal.
        XCTAssertEqual(schedule.daySlots.first?.type, .kaal)
        XCTAssertEqual(schedule.allSlots.count, 16)
    }
}
