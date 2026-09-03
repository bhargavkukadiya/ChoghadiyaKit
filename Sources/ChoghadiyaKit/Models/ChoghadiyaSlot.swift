//
//  ChoghadiyaSlot.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Represents a single computed planetary time slot in the Choghadiya calendar.
public struct ChoghadiyaSlot: Identifiable, Equatable, Hashable, Codable, Sendable {
    /// Stable identifier for SwiftUI collection bindings (e.g. `ForEach`).
    public let id: String

    /// The planetary period type.
    public let type: ChoghadiyaType

    /// Start timestamp of this slot (inclusive).
    public let startTime: Date

    /// End timestamp of this slot (exclusive).
    public let endTime: Date

    /// Total duration of this slot in seconds.
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// Initializes a `ChoghadiyaSlot`.
    /// - Parameters:
    ///   - id: Optional explicit identifier; defaults to a deterministic string based on start time and type.
    ///   - type: Planetary period type.
    ///   - startTime: Start timestamp.
    ///   - endTime: End timestamp.
    public init(id: String? = nil, type: ChoghadiyaType, startTime: Date, endTime: Date) {
        self.id = id ?? "\(type.rawValue)-\(startTime.timeIntervalSince1970)"
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
    }

    /// Checks whether the given date falls within this slot's interval.
    /// - Parameter date: Timestamp to evaluate.
    /// - Returns: `true` if `date >= startTime` and `date < endTime`.
    public func contains(date: Date) -> Bool {
        date >= startTime && date < endTime
    }

    /// Returns `true` if this slot is active at the specified timestamp.
    /// - Parameter date: Timestamp to check, defaults to current time.
    public func isActive(at date: Date = Date()) -> Bool {
        contains(date: date)
    }
}
