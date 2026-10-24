//
//  VedicPeriod.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// The daily inauspicious periods traditionally avoided for new undertakings.
public enum VedicPeriodType: String, CaseIterable, Codable, Sendable, Hashable {
    /// Period ruled by Rahu; widely avoided for starting new work, travel, or purchases.
    case rahuKaal = "Rahu Kaal"

    /// Period associated with Yama; avoided for auspicious beginnings.
    case yamagandam = "Yamagandam"

    /// Period ruled by Gulika (Mandi); events begun now are said to recur.
    case gulikaKaal = "Gulika Kaal"

    /// The 1-based eighth of daylight (sunrise to sunset) the period occupies for each weekday,
    /// indexed Sunday = 0, Monday = 1, ... Saturday = 6.
    var daytimeSegments: [Int] {
        switch self {
        case .rahuKaal:   return [8, 2, 7, 5, 6, 4, 3]
        case .yamagandam: return [5, 4, 3, 2, 1, 7, 6]
        case .gulikaKaal: return [7, 6, 5, 4, 3, 2, 1]
        }
    }
}

/// A computed Rahu Kaal, Yamagandam, or Gulika Kaal interval.
public struct VedicPeriod: Identifiable, Equatable, Hashable, Codable, Sendable {
    /// Stable identifier for SwiftUI collection bindings (e.g. `ForEach`).
    public let id: String

    /// The period type.
    public let type: VedicPeriodType

    /// Start timestamp of this period (inclusive).
    public let startTime: Date

    /// End timestamp of this period (exclusive).
    public let endTime: Date

    /// Total duration of this period in seconds.
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// Initializes a `VedicPeriod`.
    /// - Parameters:
    ///   - id: Optional explicit identifier; defaults to a deterministic string based on start time and type.
    ///   - type: Period type.
    ///   - startTime: Start timestamp.
    ///   - endTime: End timestamp.
    public init(id: String? = nil, type: VedicPeriodType, startTime: Date, endTime: Date) {
        self.id = id ?? "\(type.rawValue)-\(startTime.timeIntervalSince1970)"
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
    }

    /// Checks whether the given date falls within this period's interval.
    /// - Parameter date: Timestamp to evaluate.
    /// - Returns: `true` if `date >= startTime` and `date < endTime`.
    public func contains(date: Date) -> Bool {
        date >= startTime && date < endTime
    }

    /// Returns `true` if this period is active at the specified timestamp.
    /// - Parameter date: Timestamp to check, defaults to current time.
    public func isActive(at date: Date = Date()) -> Bool {
        contains(date: date)
    }
}
