//
//  ChoghadiyaCalculatorTests.swift
//  ChoghadiyaKitTests
//
//  Created by Bhargav Kukadiya.
//

import Testing
import Foundation
@testable import ChoghadiyaKit

@Suite("Choghadiya Calculator Tests")
struct ChoghadiyaCalculatorTests {

    private let calculator = ChoghadiyaCalculator()
    private let timeZone = TimeZone(identifier: "Asia/Kolkata")!

    /// Helper to create deterministic SunTimes for a specific weekday.
    /// Sunday = 1, Monday = 2, ..., Saturday = 7 in Calendar weekday.
    private func makeSunTimes(forWeekday targetWeekday: Int) -> SunTimes {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        // Find a date with target weekday
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 5
        comps.day = 24 // May 24, 2026 is a Sunday (weekday 1)
        let sunday = calendar.date(from: comps)!

        let daysToAdd = (targetWeekday - 1)
        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: sunday)!

        // Sunrise at 06:00, Sunset at 18:00 (12h daylight), next Sunrise next day 06:00 (12h night)
        let sunrise = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: targetDate)!
        let sunset = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDate)!
        let nextDay = calendar.date(byAdding: .day, value: 1, to: targetDate)!
        let nextSunrise = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay)!

        return SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
    }

    @Test("Sunday Day and Night Sequences")
    func testSundaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 1) // Sunday
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        #expect(schedule.daySlots.count == 8)
        #expect(schedule.nightSlots.count == 8)

        // Sunday Day: Udveg, Chal, Labh, Amrit, Kaal, Shubh, Rog, Udveg
        let expectedDay: [ChoghadiyaType] = [.udveg, .chal, .labh, .amrit, .kaal, .shubh, .rog, .udveg]
        #expect(schedule.daySlots.map(\.type) == expectedDay)

        // Sunday Night: Shubh, Amrit, Chal, Rog, Kaal, Labh, Udveg, Shubh
        let expectedNight: [ChoghadiyaType] = [.shubh, .amrit, .chal, .rog, .kaal, .labh, .udveg, .shubh]
        #expect(schedule.nightSlots.map(\.type) == expectedNight)
    }

    @Test("Monday Day and Night Sequences")
    func testMondaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 2) // Monday
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        // Monday Day: Amrit, Kaal, Shubh, Rog, Udveg, Chal, Labh, Amrit
        let expectedDay: [ChoghadiyaType] = [.amrit, .kaal, .shubh, .rog, .udveg, .chal, .labh, .amrit]
        #expect(schedule.daySlots.map(\.type) == expectedDay)

        // Monday Night: Chal, Rog, Kaal, Labh, Udveg, Shubh, Amrit, Chal
        let expectedNight: [ChoghadiyaType] = [.chal, .rog, .kaal, .labh, .udveg, .shubh, .amrit, .chal]
        #expect(schedule.nightSlots.map(\.type) == expectedNight)
    }

    @Test("Tuesday Day and Night Sequences")
    func testTuesdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 3) // Tuesday
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        // Tuesday Day: Rog, Udveg, Chal, Labh, Amrit, Kaal, Shubh, Rog
        let expectedDay: [ChoghadiyaType] = [.rog, .udveg, .chal, .labh, .amrit, .kaal, .shubh, .rog]
        #expect(schedule.daySlots.map(\.type) == expectedDay)

        // Tuesday Night: Kaal, Labh, Udveg, Shubh, Amrit, Chal, Rog, Kaal
        let expectedNight: [ChoghadiyaType] = [.kaal, .labh, .udveg, .shubh, .amrit, .chal, .rog, .kaal]
        #expect(schedule.nightSlots.map(\.type) == expectedNight)
    }

    @Test("Wednesday Day and Night Sequences")
    func testWednesdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 4) // Wednesday
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        // Wednesday Day: Labh, Amrit, Kaal, Shubh, Rog, Udveg, Chal, Labh
        let expectedDay: [ChoghadiyaType] = [.labh, .amrit, .kaal, .shubh, .rog, .udveg, .chal, .labh]
        #expect(schedule.daySlots.map(\.type) == expectedDay)

        // Wednesday Night: Udveg, Shubh, Amrit, Chal, Rog, Kaal, Labh, Udveg
        let expectedNight: [ChoghadiyaType] = [.udveg, .shubh, .amrit, .chal, .rog, .kaal, .labh, .udveg]
        #expect(schedule.nightSlots.map(\.type) == expectedNight)
    }

    @Test("Thursday Day and Night Sequences")
    func testThursdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 5) // Thursday
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        // Thursday Day: Shubh, Rog, Udveg, Chal, Labh, Amrit, Kaal, Shubh
        let expectedDay: [ChoghadiyaType] = [.shubh, .rog, .udveg, .chal, .labh, .amrit, .kaal, .shubh]
        #expect(schedule.daySlots.map(\.type) == expectedDay)

        // Thursday Night: Amrit, Chal, Rog, Kaal, Labh, Udveg, Shubh, Amrit
        let expectedNight: [ChoghadiyaType] = [.amrit, .chal, .rog, .kaal, .labh, .udveg, .shubh, .amrit]
        #expect(schedule.nightSlots.map(\.type) == expectedNight)
    }

    @Test("Friday Day and Night Sequences")
    func testFridaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 6) // Friday
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        // Friday Day: Chal, Labh, Amrit, Kaal, Shubh, Rog, Udveg, Chal
        let expectedDay: [ChoghadiyaType] = [.chal, .labh, .amrit, .kaal, .shubh, .rog, .udveg, .chal]
        #expect(schedule.daySlots.map(\.type) == expectedDay)

        // Friday Night: Rog, Kaal, Labh, Udveg, Shubh, Amrit, Chal, Rog
        let expectedNight: [ChoghadiyaType] = [.rog, .kaal, .labh, .udveg, .shubh, .amrit, .chal, .rog]
        #expect(schedule.nightSlots.map(\.type) == expectedNight)
    }

    @Test("Saturday Day and Night Sequences")
    func testSaturdaySequences() {
        let sunTimes = makeSunTimes(forWeekday: 7) // Saturday
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        // Saturday Day: Kaal, Shubh, Rog, Udveg, Chal, Labh, Amrit, Kaal
        let expectedDay: [ChoghadiyaType] = [.kaal, .shubh, .rog, .udveg, .chal, .labh, .amrit, .kaal]
        #expect(schedule.daySlots.map(\.type) == expectedDay)

        // Saturday Night: Labh, Udveg, Shubh, Amrit, Chal, Rog, Kaal, Labh
        let expectedNight: [ChoghadiyaType] = [.labh, .udveg, .shubh, .amrit, .chal, .rog, .kaal, .labh]
        #expect(schedule.nightSlots.map(\.type) == expectedNight)
    }

    @Test("Slot Continuity and Boundary Accuracy")
    func testSlotBoundaries() {
        let sunTimes = makeSunTimes(forWeekday: 1)
        let schedule = calculator.calculateSchedule(for: sunTimes.sunrise, sunTimes: sunTimes)

        // Day boundaries
        #expect(schedule.daySlots.first?.startTime == sunTimes.sunrise)
        #expect(schedule.daySlots.last?.endTime == sunTimes.sunset)

        for i in 0..<7 {
            #expect(schedule.daySlots[i].endTime == schedule.daySlots[i + 1].startTime)
        }

        // Night boundaries
        #expect(schedule.nightSlots.first?.startTime == sunTimes.sunset)
        #expect(schedule.nightSlots.last?.endTime == sunTimes.nextSunrise)

        for i in 0..<7 {
            #expect(schedule.nightSlots[i].endTime == schedule.nightSlots[i + 1].startTime)
        }
    }
}
