//
//  ChoghadiyaCalculator.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Mathematical calculation engine for Vedic Choghadiya planetary hours.
public final class ChoghadiyaCalculator: ChoghadiyaCalculating, Sendable {

    // MARK: - Constants

    /// Base cycle of planetary hours in classical order.
    private static let baseCycle: [ChoghadiyaType] = [
        .udveg, .chal, .labh, .amrit, .kaal, .shubh, .rog
    ]

    /// Starting base-cycle index for day Choghadiya for each weekday (Sunday = 0, Monday = 1, ... Saturday = 6).
    private static let dayStartIndices: [Int] = [0, 3, 6, 2, 5, 1, 4]

    /// Starting base-cycle index for night Choghadiya for each weekday (Sunday = 0, Monday = 1, ... Saturday = 6).
    private static let nightStartIndices: [Int] = [5, 1, 4, 0, 3, 6, 2]

    // MARK: - Init

    public init() {}

    // MARK: - ChoghadiyaCalculating

    /// Computes the complete 16-slot Choghadiya schedule for the given reference date and astronomical solar times.
    /// - Parameters:
    ///   - date: The reference date (used as fallback or for reference).
    ///   - sunTimes: Validated astronomical solar times.
    /// - Returns: Computed `ChoghadiyaSchedule`.
    public func calculateSchedule(for date: Date, sunTimes: SunTimes) -> ChoghadiyaSchedule {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = sunTimes.timeZone

        // Vedic day (Vāra) is determined strictly by sunrise
        let rawWeekday = calendar.component(.weekday, from: sunTimes.sunrise) - 1
        let weekday = max(0, min(6, rawWeekday))

        let dayTotalDuration = max(0, sunTimes.sunset.timeIntervalSince(sunTimes.sunrise))
        let nightTotalDuration = max(0, sunTimes.nextSunrise.timeIntervalSince(sunTimes.sunset))

        let daySlotDuration = dayTotalDuration / 8.0
        let nightSlotDuration = nightTotalDuration / 8.0

        let daySlots = buildSlots(
            startTime: sunTimes.sunrise,
            targetEndTime: sunTimes.sunset,
            slotDuration: daySlotDuration,
            startIndex: Self.dayStartIndices[weekday],
            step: 1
        )

        let nightSlots = buildSlots(
            startTime: sunTimes.sunset,
            targetEndTime: sunTimes.nextSunrise,
            slotDuration: nightSlotDuration,
            startIndex: Self.nightStartIndices[weekday],
            step: 5 // Traditional night sequence steps by 5
        )

        return ChoghadiyaSchedule(daySlots: daySlots, nightSlots: nightSlots, timeZone: sunTimes.timeZone)
    }

    // MARK: - Private Helpers

    private func buildSlots(
        startTime: Date,
        targetEndTime: Date,
        slotDuration: TimeInterval,
        startIndex: Int,
        step: Int
    ) -> [ChoghadiyaSlot] {
        var slots: [ChoghadiyaSlot] = []
        slots.reserveCapacity(8)

        for i in 0..<8 {
            let typeIndex = (startIndex + i * step) % 7
            let type = Self.baseCycle[typeIndex]
            let slotStart = startTime.addingTimeInterval(slotDuration * Double(i))
            // Pin the 8th slot's end time exactly to target boundary to eliminate sub-millisecond floating-point drift
            let slotEnd = (i == 7) ? targetEndTime : startTime.addingTimeInterval(slotDuration * Double(i + 1))

            slots.append(ChoghadiyaSlot(type: type, startTime: slotStart, endTime: slotEnd))
        }

        return slots
    }
}
