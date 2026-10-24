//
//  VedicPeriodCalculatorTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import XCTest
@testable import ChoghadiyaKit

final class VedicPeriodCalculatorTests: XCTestCase {

    private let calculator = VedicPeriodCalculator()
    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// 06:00 sunrise and 18:00 sunset, so each eighth of daylight is exactly 90 minutes.
    /// Sunday = 1, Monday = 2, ..., Saturday = 7 in Calendar weekday.
    private func makeSunTimes(forWeekday targetWeekday: Int) -> SunTimes {
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 5, day: 24))! // Sunday
        let day = calendar.date(byAdding: .day, value: targetWeekday - 1, to: sunday)!
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        return SunTimes(
            sunrise: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: day)!,
            sunset: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day)!,
            nextSunrise: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay)!,
            timeZone: timeZone
        )
    }

    private func startTime(_ period: VedicPeriod?) -> String? {
        guard let period else { return nil }
        let components = calendar.dateComponents([.hour, .minute], from: period.startTime)
        return String(format: "%02d:%02d", components.hour!, components.minute!)
    }

    // MARK: - Weekday Tables

    func testStartTimesForEveryWeekdayMatchTraditionalTables() {
        // Standard panchang tables for a 06:00–18:00 day.
        let expected: [(weekday: String, rahu: String, yamagandam: String, gulika: String)] = [
            ("Sunday", "16:30", "12:00", "15:00"),
            ("Monday", "07:30", "10:30", "13:30"),
            ("Tuesday", "15:00", "09:00", "12:00"),
            ("Wednesday", "12:00", "07:30", "10:30"),
            ("Thursday", "13:30", "06:00", "09:00"),
            ("Friday", "10:30", "15:00", "07:30"),
            ("Saturday", "09:00", "13:30", "06:00")
        ]

        for (index, row) in expected.enumerated() {
            let periods = calculator.calculatePeriods(for: makeSunTimes(forWeekday: index + 1))
            let byType = Dictionary(uniqueKeysWithValues: periods.map { ($0.type, $0) })
            XCTAssertEqual(startTime(byType[.rahuKaal]), row.rahu, "\(row.weekday) Rahu Kaal")
            XCTAssertEqual(startTime(byType[.yamagandam]), row.yamagandam, "\(row.weekday) Yamagandam")
            XCTAssertEqual(startTime(byType[.gulikaKaal]), row.gulika, "\(row.weekday) Gulika Kaal")
        }
    }

    // MARK: - Interval Properties

    func testPeriodsAreChronologicalEighthsOfDaylight() {
        for weekday in 1...7 {
            let sunTimes = makeSunTimes(forWeekday: weekday)
            let periods = calculator.calculatePeriods(for: sunTimes)

            XCTAssertEqual(periods.count, 3)
            XCTAssertEqual(Set(periods.map(\.type)), Set(VedicPeriodType.allCases))
            XCTAssertEqual(periods.map(\.startTime), periods.map(\.startTime).sorted())
            for period in periods {
                XCTAssertEqual(period.duration, sunTimes.daylightDuration / 8, accuracy: 0.001)
                XCTAssertGreaterThanOrEqual(period.startTime, sunTimes.sunrise)
                XCTAssertLessThanOrEqual(period.endTime, sunTimes.sunset)
            }
        }
    }

    func testFinalEighthEndsExactlyAtSunset() {
        // Sunday's Rahu Kaal is the last eighth of daylight.
        let sunTimes = makeSunTimes(forWeekday: 1)
        let rahu = calculator.calculatePeriods(for: sunTimes).first { $0.type == .rahuKaal }
        XCTAssertEqual(rahu?.endTime, sunTimes.sunset)
    }

    func testInvalidSolarBoundariesReturnNoPeriods() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let invalid = SunTimes(sunrise: base, sunset: base, nextSunrise: base.addingTimeInterval(86_400), timeZone: timeZone)
        XCTAssertTrue(calculator.calculatePeriods(for: invalid).isEmpty)
    }

    // MARK: - Schedule Integration

    func testScheduleExposesTheSamePeriods() throws {
        let sunTimes = makeSunTimes(forWeekday: 2)
        let schedule = ChoghadiyaCalculator().calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        XCTAssertEqual(schedule.vedicPeriods, calculator.calculatePeriods(for: sunTimes))
        let rahu = try XCTUnwrap(schedule.vedicPeriod(.rahuKaal))
        XCTAssertEqual(startTime(rahu), "07:30")
        XCTAssertTrue(rahu.contains(date: rahu.startTime))
        XCTAssertFalse(rahu.contains(date: rahu.endTime))

        let empty = ChoghadiyaSchedule(daySlots: [], nightSlots: [], timeZone: timeZone)
        XCTAssertTrue(empty.vedicPeriods.isEmpty)
        XCTAssertNil(empty.vedicPeriod(.gulikaKaal))
    }

    func testPeriodCodableRoundTrip() throws {
        let period = try XCTUnwrap(calculator.calculatePeriods(for: makeSunTimes(forWeekday: 3)).first)
        let decoded = try JSONDecoder().decode(VedicPeriod.self, from: JSONEncoder().encode(period))
        XCTAssertEqual(decoded, period)
    }
}
