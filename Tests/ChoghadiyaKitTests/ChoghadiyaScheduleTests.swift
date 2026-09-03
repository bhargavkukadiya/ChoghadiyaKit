//
//  ChoghadiyaScheduleTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import Testing
import Foundation
@testable import ChoghadiyaKit

@Suite("Choghadiya Schedule Tests")
struct ChoghadiyaScheduleTests {

    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!

    private func makeSampleSchedule() -> (schedule: ChoghadiyaSchedule, sunrise: Date, sunset: Date, nextSunrise: Date) {
        let calendar = Calendar.current
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

    @Test("allSlots Property Contains 16 Total Slots")
    func testAllSlots() {
        let (schedule, _, _, _) = makeSampleSchedule()
        #expect(schedule.allSlots.count == 16)
        #expect(schedule.daySlots.count == 8)
        #expect(schedule.nightSlots.count == 8)
    }

    @Test("currentSlot and nextSlot Behavior")
    func testSlotQueries() {
        let (schedule, sunrise, _, nextSunrise) = makeSampleSchedule()

        // At exact sunrise: first day slot is active
        let atSunriseSlot = schedule.currentSlot(at: sunrise)
        #expect(atSunriseSlot != nil)
        #expect(atSunriseSlot?.startTime == sunrise)

        // Next slot after sunrise is slot 1
        let next = schedule.nextSlot(after: sunrise)
        #expect(next?.startTime == schedule.daySlots[1].startTime)

        // Mid-day query (e.g. sunrise + 2 hours)
        let midDay = sunrise.addingTimeInterval(7200)
        let midSlot = schedule.currentSlot(at: midDay)
        #expect(midSlot != nil)
        #expect(midSlot?.contains(date: midDay) == true)

        // Before schedule begins
        let beforeSunrise = sunrise.addingTimeInterval(-60)
        #expect(schedule.currentSlot(at: beforeSunrise) == nil)
        #expect(schedule.nextSlot(after: beforeSunrise)?.startTime == sunrise)

        // After schedule ends
        let afterNextSunrise = nextSunrise.addingTimeInterval(60)
        #expect(schedule.currentSlot(at: afterNextSunrise) == nil)
        #expect(schedule.nextSlot(after: afterNextSunrise) == nil)
    }

    @Test("isDaytime Query Accuracy")
    func testIsDaytime() {
        let (schedule, sunrise, sunset, _) = makeSampleSchedule()

        // Exactly at sunrise
        #expect(schedule.isDaytime(at: sunrise) == true)

        // 1 second before sunset
        #expect(schedule.isDaytime(at: sunset.addingTimeInterval(-1)) == true)

        // Exactly at sunset (start of night)
        #expect(schedule.isDaytime(at: sunset) == false)

        // Nighttime
        #expect(schedule.isDaytime(at: sunset.addingTimeInterval(3600)) == false)
    }

    @Test("Codable Serialization Roundtrip")
    func testCodable() throws {
        let (schedule, _, _, _) = makeSampleSchedule()

        let encoder = JSONEncoder()
        let data = try encoder.encode(schedule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChoghadiyaSchedule.self, from: data)

        #expect(decoded == schedule)
        #expect(decoded.daySlots.count == 8)
        #expect(decoded.nightSlots.count == 8)
    }

    @Test("ChoghadiyaSlot Identifiable Uniqueness")
    func testSlotIdentity() {
        let (schedule, _, _, _) = makeSampleSchedule()
        let ids = Set(schedule.allSlots.map(\.id))
        #expect(ids.count == 16)
    }
}
