//
//  ChoghadiyaSchedule.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// The complete computed Choghadiya schedule for a 24-hour astronomical period (sunrise to next sunrise).
public struct ChoghadiyaSchedule: Equatable, Hashable, Codable, Sendable {
    // MARK: - Properties

    /// The eight daytime Choghadiya slots (sunrise to sunset).
    public let daySlots: [ChoghadiyaSlot]

    /// The eight nighttime Choghadiya slots (sunset to next sunrise).
    public let nightSlots: [ChoghadiyaSlot]

    /// The local time zone used for this schedule.
    public let timeZone: TimeZone

    // MARK: - Solar Boundaries

    /// The astronomical sunrise timestamp (start time of the first daytime slot).
    public var sunrise: Date? {
        daySlots.first?.startTime
    }

    /// The astronomical sunset timestamp (end time of the last daytime slot / start of nighttime slots).
    public var sunset: Date? {
        daySlots.last?.endTime
    }

    /// The astronomical sunrise timestamp on the following calendar day (end time of the last nighttime slot).
    public var nextSunrise: Date? {
        nightSlots.last?.endTime
    }

    /// All 16 slots of the Vedic day in chronological order.
    public var allSlots: [ChoghadiyaSlot] {
        daySlots + nightSlots
    }

    // MARK: - Init

    /// Initializes a `ChoghadiyaSchedule`.
    public init(daySlots: [ChoghadiyaSlot], nightSlots: [ChoghadiyaSlot], timeZone: TimeZone) {
        self.daySlots = daySlots
        self.nightSlots = nightSlots
        self.timeZone = timeZone
    }

    // MARK: - Slot Queries

    /// Finds the active slot at the given timestamp.
    /// - Parameter date: Timestamp to check; defaults to `Date()`.
    /// - Returns: The active `ChoghadiyaSlot`, or `nil` if outside the schedule range.
    public func currentSlot(at date: Date = Date()) -> ChoghadiyaSlot? {
        allSlots.first { $0.contains(date: date) }
    }

    /// Finds the immediate next slot occurring after the given timestamp.
    /// - Parameter date: Reference timestamp; defaults to `Date()`.
    /// - Returns: The next chronological `ChoghadiyaSlot`, or `nil` if past all slots.
    public func nextSlot(after date: Date = Date()) -> ChoghadiyaSlot? {
        allSlots.first { $0.startTime > date }
    }

    /// Checks whether the given timestamp falls within daytime Choghadiya (between first day slot and last day slot).
    /// - Parameter date: Timestamp to check; defaults to `Date()`.
    /// - Returns: `true` if within daytime slots.
    public func isDaytime(at date: Date = Date()) -> Bool {
        guard let firstDaySlot = daySlots.first, let lastDaySlot = daySlots.last else { return false }
        return date >= firstDaySlot.startTime && date < lastDaySlot.endTime
    }

    // MARK: - Rahu Kaal, Yamagandam & Gulika Kaal

    /// The day's Rahu Kaal, Yamagandam, and Gulika Kaal in chronological order, computed from this
    /// schedule's sunrise and sunset; empty if the schedule has no slots.
    public var vedicPeriods: [VedicPeriod] {
        guard let sunrise, let sunset, let nextSunrise else { return [] }
        let sunTimes = SunTimes(sunrise: sunrise, sunset: sunset, nextSunrise: nextSunrise, timeZone: timeZone)
        return VedicPeriodCalculator().calculatePeriods(for: sunTimes)
    }

    /// The day's period of the given type (e.g. `.rahuKaal`), or `nil` if the schedule has no slots.
    public func vedicPeriod(_ type: VedicPeriodType) -> VedicPeriod? {
        vedicPeriods.first { $0.type == type }
    }
}
