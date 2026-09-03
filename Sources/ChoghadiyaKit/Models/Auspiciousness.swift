//
//  Auspiciousness.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Represents the qualitative nature or auspiciousness tier of a Choghadiya period.
public enum Auspiciousness: String, Sendable, Codable, CaseIterable {
    /// Highly auspicious period suitable for major milestones and auspicious beginnings (e.g. Amrit).
    case highlyAuspicious = "Highly Auspicious"

    /// Auspicious and beneficial period suitable for productive work and ceremonies (e.g. Shubh, Labh).
    case auspicious = "Auspicious"

    /// Neutral / moderate period suitable for routine or mobile activities (e.g. Chal).
    case neutral = "Neutral"

    /// Inauspicious period prone to anxiety, delays, or obstacles (e.g. Udveg, Kaal).
    case inauspicious = "Inauspicious"

    /// Harmful / avoid period advised against initiating important work (e.g. Rog).
    case avoid = "Avoid"

    /// Indicates whether the period is considered positive (favorable) for initiating actions.
    public var isFavorable: Bool {
        switch self {
        case .highlyAuspicious, .auspicious:
            return true
        case .neutral, .inauspicious, .avoid:
            return false
        }
    }
}
