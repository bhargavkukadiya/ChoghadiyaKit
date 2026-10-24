//
//  VedicPeriodCalculator.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Calculation engine for Rahu Kaal, Yamagandam, and Gulika Kaal.
///
/// Daylight (sunrise to sunset) is divided into eight equal parts, and each period occupies the part fixed
/// for the Vedic weekday, which is determined by sunrise. These are the daytime periods published in most
/// panchangs; night-time variants are not computed.
public struct VedicPeriodCalculator: Sendable {

    // MARK: - Init

    public init() {}

    // MARK: - Calculation

    /// Computes the day's Rahu Kaal, Yamagandam, and Gulika Kaal.
    /// - Parameter sunTimes: Astronomical solar times.
    /// - Returns: The three periods in chronological order, or an empty array if solar boundaries are invalid.
    public func calculatePeriods(for sunTimes: SunTimes) -> [VedicPeriod] {
        guard sunTimes.isValid else { return [] }

        let weekday = sunTimes.vedicWeekdayIndex
        let segmentDuration = sunTimes.daylightDuration / 8.0

        return VedicPeriodType.allCases
            .map { type in
                let segment = type.daytimeSegments[weekday]
                let start = sunTimes.sunrise.addingTimeInterval(segmentDuration * Double(segment - 1))
                // Pin the 8th part's end exactly to sunset to eliminate floating-point drift
                let end = segment == 8 ? sunTimes.sunset : sunTimes.sunrise.addingTimeInterval(segmentDuration * Double(segment))
                return VedicPeriod(type: type, startTime: start, endTime: end)
            }
            .sorted { $0.startTime < $1.startTime }
    }
}
