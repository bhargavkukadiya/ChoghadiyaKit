//
//  ChoghadiyaScheduleTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import XCTest
@testable import ChoghadiyaKit

final class ChoghadiyaScheduleTests: XCTestCase {

    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!

    private func makeSampleSchedule() -> (schedule: ChoghadiyaSchedule, sunrise: Date, sunset: Date, nextSunrise: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let baseDate = Date(timeIntervalSince1970: 1700000000)
        let sunrise = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: baseDate)!
        let sunset = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: baseDate)!
        let nextDay = calendar.date(byAdding: .day, value: 1, to: baseDate)!
        let nextSunrise = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay)!

        let sunTimes = SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
        let calculator = ChoghadiyaCalculator()
        let schedule = calculator.calculateSchedule(for: sunrise, sunTimes: sunTimes)
        return (schedule, sunrise, sunset, nextSunrise)
    }

    func testAllSlots() {
        let (schedule, _, _, _) = makeSampleSchedule()
        XCTAssertEqual(schedule.allSlots.count, 16)
        XCTAssertEqual(schedule.daySlots.count, 8)
        XCTAssertEqual(schedule.nightSlots.count, 8)
    }

    func testSlotQueries() {
        let (schedule, sunrise, _, nextSunrise) = makeSampleSchedule()

        // At exact sunrise: first day slot is active
        let atSunriseSlot = schedule.currentSlot(at: sunrise)
        XCTAssertNotNil(atSunriseSlot)
        XCTAssertEqual(atSunriseSlot?.startTime, sunrise)

        // Next slot after sunrise is slot 1
        let next = schedule.nextSlot(after: sunrise)
        XCTAssertEqual(next?.startTime, schedule.daySlots[1].startTime)

        // Mid-day query (e.g. sunrise + 2 hours)
        let midDay = sunrise.addingTimeInterval(7200)
        let midSlot = schedule.currentSlot(at: midDay)
        XCTAssertNotNil(midSlot)
        XCTAssertTrue(midSlot?.contains(date: midDay) == true)

        // Before schedule begins
        let beforeSunrise = sunrise.addingTimeInterval(-60)
        XCTAssertNil(schedule.currentSlot(at: beforeSunrise))
        XCTAssertEqual(schedule.nextSlot(after: beforeSunrise)?.startTime, sunrise)

        // After schedule ends
        let afterNextSunrise = nextSunrise.addingTimeInterval(60)
        XCTAssertNil(schedule.currentSlot(at: afterNextSunrise))
        XCTAssertNil(schedule.nextSlot(after: afterNextSunrise))
    }

    func testIsDaytime() {
        let (schedule, sunrise, sunset, _) = makeSampleSchedule()

        // Exactly at sunrise
        XCTAssertTrue(schedule.isDaytime(at: sunrise))

        // 1 second before sunset
        XCTAssertTrue(schedule.isDaytime(at: sunset.addingTimeInterval(-1)))

        // Exactly at sunset (start of night)
        XCTAssertFalse(schedule.isDaytime(at: sunset))

        // Nighttime
        XCTAssertFalse(schedule.isDaytime(at: sunset.addingTimeInterval(3600)))
    }

    func testCodable() throws {
        let (schedule, _, _, _) = makeSampleSchedule()

        let encoder = JSONEncoder()
        let data = try encoder.encode(schedule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChoghadiyaSchedule.self, from: data)

        XCTAssertEqual(decoded, schedule)
        XCTAssertEqual(decoded.daySlots.count, 8)
        XCTAssertEqual(decoded.nightSlots.count, 8)
    }

    func testSlotIdentity() {
        let (schedule, _, _, _) = makeSampleSchedule()
        let ids = Set(schedule.allSlots.map(\.id))
        XCTAssertEqual(ids.count, 16)
    }

    func testSolarBoundaries() {
        let (schedule, sunrise, sunset, nextSunrise) = makeSampleSchedule()
        XCTAssertEqual(schedule.sunrise, sunrise)
        XCTAssertEqual(schedule.sunset, sunset)
        XCTAssertEqual(schedule.nextSunrise, nextSunrise)

        let emptySchedule = ChoghadiyaSchedule(daySlots: [], nightSlots: [], timeZone: timeZone)
        XCTAssertNil(emptySchedule.sunrise)
        XCTAssertNil(emptySchedule.sunset)
        XCTAssertNil(emptySchedule.nextSunrise)
    }
}
