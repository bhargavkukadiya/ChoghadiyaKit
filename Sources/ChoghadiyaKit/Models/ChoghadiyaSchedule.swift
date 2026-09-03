//
//  ChoghadiyaSchedule.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// The complete computed Choghadiya schedule for a 24-hour astronomical period (sunrise to next sunrise).
public struct ChoghadiyaSchedule: Equatable, Hashable, Codable, Sendable {
    /// The eight daytime Choghadiya slots (sunrise to sunset).
    public let daySlots: [ChoghadiyaSlot]

    /// The eight nighttime Choghadiya slots (sunset to next sunrise).
    public let nightSlots: [ChoghadiyaSlot]

    /// The local time zone used for this schedule.
    public let timeZone: TimeZone

    /// All 16 slots of the Vedic day in chronological order.
    public var allSlots: [ChoghadiyaSlot] {
        daySlots + nightSlots
    }

    /// Initializes a `ChoghadiyaSchedule`.
    public init(daySlots: [ChoghadiyaSlot], nightSlots: [ChoghadiyaSlot], timeZone: TimeZone) {
        self.daySlots = daySlots
        self.nightSlots = nightSlots
        self.timeZone = timeZone
    }

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
}
