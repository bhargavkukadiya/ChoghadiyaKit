//
//  ChoghadiyaCalculating.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Protocol defining the mathematical schedule computation for Choghadiya slots.
public protocol ChoghadiyaCalculating: Sendable {
    /// Computes the complete 16-slot Choghadiya schedule for the given reference date and astronomical solar times.
    /// - Parameters:
    ///   - date: The reference calendar date.
    ///   - sunTimes: Astronomical sunrise and sunset data.
    /// - Returns: Computed `ChoghadiyaSchedule`.
    func calculateSchedule(for date: Date, sunTimes: SunTimes) -> ChoghadiyaSchedule
}
