//
//  ChoghadiyaType.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Represents the seven traditional planetary periods in Vedic Choghadiya.
public enum ChoghadiyaType: String, CaseIterable, Codable, Sendable, Hashable {
    case udveg = "Udveg"
    case chal = "Chal"
    case labh = "Labh"
    case amrit = "Amrit"
    case kaal = "Kaal"
    case shubh = "Shubh"
    case rog = "Rog"

    /// Descriptive nature / label for backward compatibility.
    public var label: String {
        switch self {
        case .udveg: return "Anxiety"
        case .chal: return "Neutral"
        case .labh: return "Beneficial"
        case .amrit: return "Highly Auspicious"
        case .kaal: return "Inauspicious"
        case .shubh: return "Auspicious"
        case .rog: return "Avoid"
        }
    }

    /// The qualitative astrological auspiciousness tier.
    public var auspiciousness: Auspiciousness {
        switch self {
        case .amrit:
            return .highlyAuspicious
        case .shubh, .labh:
            return .auspicious
        case .chal:
            return .neutral
        case .udveg, .kaal:
            return .inauspicious
        case .rog:
            return .avoid
        }
    }

    /// Returns `true` if this period is auspicious or beneficial.
    public var isAuspicious: Bool {
        auspiciousness.isFavorable
    }

    /// The Vedic astrological ruling celestial body (Graha) for this Choghadiya period.
    public var rulingPlanet: String {
        switch self {
        case .udveg: return "Sun (Surya)"
        case .chal:  return "Venus (Shukra)"
        case .labh:  return "Mercury (Budha)"
        case .amrit: return "Moon (Chandra)"
        case .kaal:  return "Saturn (Shani)"
        case .shubh: return "Jupiter (Guru)"
        case .rog:   return "Mars (Mangal)"
        }
    }
}
