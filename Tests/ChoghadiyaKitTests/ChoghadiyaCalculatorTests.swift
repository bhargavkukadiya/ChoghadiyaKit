//
//  ChoghadiyaCalculatorTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import XCTest
@testable import ChoghadiyaKit

final class ChoghadiyaCalculatorTests: XCTestCase {

    private let calculator = ChoghadiyaCalculator()
    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!

    /// Helper to create deterministic SunTimes for a specific weekday.
    /// Sunday = 1, Monday = 2, ..., Saturday = 7 in Calendar weekday.
    private func makeSunTimes(forWeekday targetWeekday: Int) -> SunTimes {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var comps = DateComponents()
        comps.year = 2026
        comps.month = 5
        comps.day = 24 // May 24, 2026 is Sunday (weekday 1)
        let sunday = calendar.date(from: comps)!

        let daysToAdd = (targetWeekday - 1)
        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: sunday)!

        let sunrise = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: targetDate)!
        let sunset = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDate)!
        let nextDay = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        let nextSunrise = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay)!

        return SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
    }

    func testSundaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 1)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        XCTAssertEqual(schedule.daySlots.count, 8)
        XCTAssertEqual(schedule.nightSlots.count, 8)

        let expectedDay: [ChoghadiyaType] = [.udveg, .chal, .labh, .amrit, .kaal, .shubh, .rog, .udveg]
        XCTAssertEqual(schedule.daySlots.map(\.type), expectedDay)

        let expectedNight: [ChoghadiyaType] = [.shubh, .amrit, .chal, .rog, .kaal, .labh, .udveg, .shubh]
        XCTAssertEqual(schedule.nightSlots.map(\.type), expectedNight)
    }

    func testMondaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 2)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        let expectedDay: [ChoghadiyaType] = [.amrit, .kaal, .shubh, .rog, .udveg, .chal, .labh, .amrit]
        XCTAssertEqual(schedule.daySlots.map(\.type), expectedDay)

        let expectedNight: [ChoghadiyaType] = [.chal, .rog, .kaal, .labh, .udveg, .shubh, .amrit, .chal]
        XCTAssertEqual(schedule.nightSlots.map(\.type), expectedNight)
    }

    func testTuesdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 3)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        let expectedDay: [ChoghadiyaType] = [.rog, .udveg, .chal, .labh, .amrit, .kaal, .shubh, .rog]
        XCTAssertEqual(schedule.daySlots.map(\.type), expectedDay)

        let expectedNight: [ChoghadiyaType] = [.kaal, .labh, .udveg, .shubh, .amrit, .chal, .rog, .kaal]
        XCTAssertEqual(schedule.nightSlots.map(\.type), expectedNight)
    }

    func testWednesdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 4)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        let expectedDay: [ChoghadiyaType] = [.labh, .amrit, .kaal, .shubh, .rog, .udveg, .chal, .labh]
        XCTAssertEqual(schedule.daySlots.map(\.type), expectedDay)

        let expectedNight: [ChoghadiyaType] = [.udveg, .shubh, .amrit, .chal, .rog, .kaal, .labh, .udveg]
        XCTAssertEqual(schedule.nightSlots.map(\.type), expectedNight)
    }

    func testThursdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 5)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        let expectedDay: [ChoghadiyaType] = [.shubh, .rog, .udveg, .chal, .labh, .amrit, .kaal, .shubh]
        XCTAssertEqual(schedule.daySlots.map(\.type), expectedDay)

        let expectedNight: [ChoghadiyaType] = [.amrit, .chal, .rog, .kaal, .labh, .udveg, .shubh, .amrit]
        XCTAssertEqual(schedule.nightSlots.map(\.type), expectedNight)
    }

    func testFridaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 6)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        let expectedDay: [ChoghadiyaType] = [.chal, .labh, .amrit, .kaal, .shubh, .rog, .udveg, .chal]
        XCTAssertEqual(schedule.daySlots.map(\.type), expectedDay)

        let expectedNight: [ChoghadiyaType] = [.rog, .kaal, .labh, .udveg, .shubh, .amrit, .chal, .rog]
        XCTAssertEqual(schedule.nightSlots.map(\.type), expectedNight)
    }

    func testSaturdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 7)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        let expectedDay: [ChoghadiyaType] = [.kaal, .shubh, .rog, .udveg, .chal, .labh, .amrit, .kaal]
        XCTAssertEqual(schedule.daySlots.map(\.type), expectedDay)

        let expectedNight: [ChoghadiyaType] = [.labh, .udveg, .shubh, .amrit, .chal, .rog, .kaal, .labh]
        XCTAssertEqual(schedule.nightSlots.map(\.type), expectedNight)
    }

    func testSlotBoundaries() {
        let sunTimes = makeSunTimes(forWeekday: 1)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        XCTAssertEqual(schedule.daySlots.first?.startTime, sunTimes.sunrise)
        XCTAssertEqual(schedule.daySlots.last?.endTime, sunTimes.sunset)

        for i in 0..<7 {
            XCTAssertEqual(schedule.daySlots[i].endTime, schedule.daySlots[i + 1].startTime)
        }

        XCTAssertEqual(schedule.nightSlots.first?.startTime, sunTimes.sunset)
        XCTAssertEqual(schedule.nightSlots.last?.endTime, sunTimes.nextSunrise)

        for i in 0..<7 {
            XCTAssertEqual(schedule.nightSlots[i].endTime, schedule.nightSlots[i + 1].startTime)
        }
    }
}
