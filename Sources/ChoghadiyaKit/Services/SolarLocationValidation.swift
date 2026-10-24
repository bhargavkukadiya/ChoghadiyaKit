//
//  SolarLocationValidation.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// Coordinate and time zone checks shared by the solar time providers.
enum SolarLocationValidation {

    // MARK: - Constants

    /// Largest accepted gap, in hours, between a time zone's UTC offset and local mean solar time
    /// when the zone places sunrise on a different calendar day than local solar time does.
    /// Real-world zones stay within about 3 hours.
    private static let maxSolarOffsetDeviationHours = 4.0

    /// Territory lying across the date line from its time zone's calendar day. Inside these regions the civil
    /// weekday is a full day away from the solar one by local convention, so the gap check does not apply.
    /// Regions are drawn tightly around the territory's own land so that neighbouring land under another
    /// calendar day (St. Lawrence Island, Alaska, beside Chukotka; Jarvis Island beside the Line Islands;
    /// American Samoa beside Samoa) is excluded.
    private struct DateLineTerritory {
        struct Region {
            let latitudes: ClosedRange<Double>
            let longitudes: ClosedRange<Double>
        }

        let timeZoneIdentifiers: Set<String>
        let regions: [Region]

        func contains(timeZone: TimeZone, latitude: Double, longitude: Double) -> Bool {
            timeZoneIdentifiers.contains(timeZone.identifier)
                && regions.contains { $0.latitudes.contains(latitude) && $0.longitudes.contains(longitude) }
        }
    }

    private static let dateLineTerritories: [DateLineTerritory] = [
        // Line Islands, Kiribati (UTC+14): Teraina, Tabuaeran, and Kiritimati; Malden and Starbuck;
        // Caroline, Vostok, and Flint
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Kiritimati"], regions: [
            .init(latitudes: 1.5...5.0, longitudes: -160.6...(-157.0)),
            .init(latitudes: -5.8...(-3.8), longitudes: -156.1...(-154.7)),
            .init(latitudes: -11.6...(-9.8), longitudes: -152.6...(-150.0))
        ]),
        // Phoenix Islands, Kiribati (UTC+13)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Kanton", "Pacific/Enderbury"], regions: [
            .init(latitudes: -5.5...(-2.0), longitudes: -175.5...(-170.0))
        ]),
        // Samoa (UTC+13), west of American Samoa's Tutuila
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Apia"], regions: [
            .init(latitudes: -14.3...(-13.2), longitudes: -173.0...(-171.2))
        ]),
        // Tokelau (UTC+13), north of Swains Island
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Fakaofo"], regions: [
            .init(latitudes: -9.7...(-8.3), longitudes: -172.8...(-170.9))
        ]),
        // Tonga (UTC+13)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Tongatapu"], regions: [
            .init(latitudes: -23.0...(-15.0), longitudes: -176.5...(-173.0))
        ]),
        // Wallis and Futuna (UTC+12)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Wallis"], regions: [
            .init(latitudes: -14.6...(-13.0), longitudes: -178.5...(-175.9))
        ]),
        // Fiji's Lau group (UTC+12)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Fiji"], regions: [
            .init(latitudes: -21.5...(-15.0), longitudes: -180.0...(-178.0))
        ]),
        // Chatham Islands, New Zealand (UTC+12:45)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Chatham", "NZ-CHAT"], regions: [
            .init(latitudes: -44.7...(-43.3), longitudes: -177.2...(-175.5))
        ]),
        // Kermadec Islands, New Zealand (UTC+12)
        DateLineTerritory(timeZoneIdentifiers: ["Pacific/Auckland", "NZ"], regions: [
            .init(latitudes: -31.8...(-29.0), longitudes: -179.2...(-177.5))
        ]),
        // Ross Dependency, Antarctica (New Zealand time)
        DateLineTerritory(timeZoneIdentifiers: ["Antarctica/McMurdo", "Antarctica/South_Pole"], regions: [
            .init(latitudes: -90.0...(-60.0), longitudes: -180.0...(-150.0))
        ]),
        // Chukotka east of 180° (UTC+12): Cape Chukotsky (64.2° N) northward to Wrangel Island, west of the
        // Diomede border. St. Lawrence Island, Alaska, ends at 63.8° N.
        DateLineTerritory(timeZoneIdentifiers: ["Asia/Anadyr"], regions: [
            .init(latitudes: 64.0...72.0, longitudes: -180.0...(-169.0))
        ]),
        // Western Aleutians west of 180° (UTC−10)
        DateLineTerritory(timeZoneIdentifiers: ["America/Adak", "America/Atka", "US/Aleutian"], regions: [
            .init(latitudes: 50.5...54.0, longitudes: 172.0...180.0)
        ])
    ]

    // MARK: - Coordinates

    /// Rejects non-finite coordinates and those outside -90...90 latitude or -180...180 longitude.
    static func validateCoordinates(latitude: Double, longitude: Double) throws {
        guard latitude.isFinite, (-90.0...90.0).contains(latitude),
              longitude.isFinite, (-180.0...180.0).contains(longitude) else {
            throw ChoghadiyaError.invalidCoordinates
        }
    }

    // MARK: - Time Zone

    /// Rejects a time zone that assigns sunrise to a different calendar day (and so a different Vedic weekday)
    /// than local mean solar time does, unless the coordinates lie in that zone's territory across the date line.
    static func validateTimeZone(_ timeZone: TimeZone, latitude: Double, longitude: Double, sunrise: Date) throws {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var civilCalendar = Calendar(identifier: .gregorian)
        civilCalendar.timeZone = timeZone

        let solarOffsetHours = longitude / 15.0
        let solarDay = utcCalendar.dateComponents([.year, .month, .day], from: sunrise.addingTimeInterval(solarOffsetHours * 3600))
        let civilDay = civilCalendar.dateComponents([.year, .month, .day], from: sunrise)

        guard solarDay.year != civilDay.year || solarDay.month != civilDay.month || solarDay.day != civilDay.day else {
            return
        }

        let deviation = abs(Double(timeZone.secondsFromGMT(for: sunrise)) / 3600.0 - solarOffsetHours)
        if deviation <= maxSolarOffsetDeviationHours {
            return
        }

        let isDateLineTerritory = dateLineTerritories.contains {
            $0.contains(timeZone: timeZone, latitude: latitude, longitude: longitude)
        }
        guard isDateLineTerritory else {
            throw ChoghadiyaError.timeZoneMismatch
        }
    }
}
