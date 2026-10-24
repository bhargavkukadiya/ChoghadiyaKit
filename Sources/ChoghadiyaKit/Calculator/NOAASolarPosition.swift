//
//  NOAASolarPosition.swift
//  ChoghadiyaKit
//
//  Created by Bhargav Kukadiya.
//

import Foundation

/// NOAA solar position equations (after Jean Meeus, *Astronomical Algorithms*), as used by the
/// NOAA Solar Calculator. Accurate to about a minute for sunrise and sunset between latitudes ±72°;
/// near the poles, where the sun grazes the horizon, small position errors move the times by minutes.
enum NOAASolarPosition {

    // MARK: - Constants

    /// Solar zenith angle at sunrise and sunset: 90° plus 50′ for atmospheric refraction and the solar disc's radius.
    private static let sunriseZenithDegrees = 90.833

    private static let secondsPerDay = 86_400.0

    /// Bisection steps narrowing a half-day search window to well under a millisecond.
    private static let bisectionIterations = 40

    // MARK: - Types

    enum Event {
        case sunrise
        case sunset
    }

    struct Parameters {
        /// Apparent minus mean solar time, in minutes.
        let equationOfTimeMinutes: Double
        /// Solar declination, in degrees.
        let declinationDegrees: Double
    }

    // MARK: - Solar Position

    /// Computes the equation of time and solar declination at an instant.
    static func parameters(at date: Date) -> Parameters {
        let julianDay = date.timeIntervalSince1970 / secondsPerDay + 2_440_587.5
        let t = (julianDay - 2_451_545.0) / 36_525.0

        let meanLongitude = (280.46646 + t * (36_000.76983 + t * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let meanAnomaly = 357.52911 + t * (35_999.05029 - 0.0001537 * t)
        let eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        let equationOfCenter = sin(radians(meanAnomaly)) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(radians(2 * meanAnomaly)) * (0.019993 - 0.000101 * t)
            + sin(radians(3 * meanAnomaly)) * 0.000289
        let trueLongitude = meanLongitude + equationOfCenter

        let omega = 125.04 - 1_934.136 * t
        let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * sin(radians(omega))

        let meanObliquity = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let obliquity = meanObliquity + 0.00256 * cos(radians(omega))

        let declination = degrees(asin(sin(radians(obliquity)) * sin(radians(apparentLongitude))))

        let y = pow(tan(radians(obliquity / 2)), 2)
        let l0 = radians(meanLongitude)
        let m = radians(meanAnomaly)
        let equationOfTime = 4 * degrees(
            y * sin(2 * l0)
                - 2 * eccentricity * sin(m)
                + 4 * eccentricity * y * sin(m) * cos(2 * l0)
                - 0.5 * y * y * sin(4 * l0)
                - 1.25 * eccentricity * eccentricity * sin(2 * m)
        )

        return Parameters(equationOfTimeMinutes: equationOfTime, declinationDegrees: declination)
    }

    /// How far the sun is above the sunrise/sunset threshold, as cos(zenith) − cos(90.833°):
    /// positive while the sun is up, negative while it is down.
    static func horizonMargin(at date: Date, latitude: Double, longitude: Double) -> Double {
        let position = parameters(at: date)
        let utcMinutes = (date.timeIntervalSince1970 / 60).truncatingRemainder(dividingBy: 1_440)
        let trueSolarMinutes = utcMinutes + position.equationOfTimeMinutes + 4 * longitude
        let hourAngle = radians(trueSolarMinutes / 4 - 180)

        let phi = radians(latitude)
        let delta = radians(position.declinationDegrees)
        let cosZenith = sin(phi) * sin(delta) + cos(phi) * cos(delta) * cos(hourAngle)
        return cosZenith - cos(radians(sunriseZenithDegrees))
    }

    // MARK: - Events

    /// The local apparent solar noon nearest to `date` at `longitude`.
    static func solarNoon(near date: Date, longitude: Double) -> Date {
        var noon = date
        // Re-evaluate the equation of time at the noon estimate until it settles.
        for _ in 0..<3 {
            let equationOfTime = parameters(at: noon).equationOfTimeMinutes
            let utcMidnight = (noon.timeIntervalSince1970 / secondsPerDay).rounded(.down) * secondsPerDay
            var candidate = utcMidnight + (720 - 4 * longitude - equationOfTime) * 60
            candidate += ((date.timeIntervalSince1970 - candidate) / secondsPerDay).rounded() * secondsPerDay
            noon = Date(timeIntervalSince1970: candidate)
        }
        return noon
    }

    /// The sunrise before, or sunset after, the given solar noon.
    ///
    /// Sunrise lies between the preceding solar midnight and noon, sunset between noon and the following
    /// solar midnight. The crossing is located by bisection on the sun's actual position, so near a polar
    /// transition a sunrise or sunset close to midnight is still found even though the declination at
    /// noon alone would rule it out.
    /// - Throws: `ChoghadiyaError.polarDayOrNight` if the sun does not cross the horizon in that half day.
    static func time(of event: Event, solarNoon noon: Date, latitude: Double, longitude: Double) throws -> Date {
        let midnight = noon.addingTimeInterval(event == .sunrise ? -secondsPerDay / 2 : secondsPerDay / 2)
        guard horizonMargin(at: noon, latitude: latitude, longitude: longitude) > 0,
              horizonMargin(at: midnight, latitude: latitude, longitude: longitude) <= 0 else {
            throw ChoghadiyaError.polarDayOrNight
        }

        var sunUp = noon.timeIntervalSince1970
        var sunDown = midnight.timeIntervalSince1970
        for _ in 0..<bisectionIterations {
            let middle = (sunUp + sunDown) / 2
            if horizonMargin(at: Date(timeIntervalSince1970: middle), latitude: latitude, longitude: longitude) > 0 {
                sunUp = middle
            } else {
                sunDown = middle
            }
        }
        return Date(timeIntervalSince1970: (sunUp + sunDown) / 2)
    }

    // MARK: - Helpers

    private static func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static func degrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
}
