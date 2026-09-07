//
//  main.swift
//  ChoghadiyaDemo
//
//  Created by Bhargav Kukadiya.
//

import Foundation
import CoreLocation
import ChoghadiyaKit

// MARK: - Supporting Types

struct DateComponentsInput {
    let year: Int
    let month: Int
    let day: Int
}

enum InputMode {
    case coordinates(latitude: Double, longitude: Double, timeZone: TimeZone, dateComponents: DateComponentsInput?)
    case address(String, dateComponents: DateComponentsInput?)
    case help
}

enum CLIError: LocalizedError {
    case argumentError(String)

    var errorDescription: String? {
        switch self {
        case .argumentError(let message):
            return message
        }
    }
}

// MARK: - Application Entry Point

@main
struct ChoghadiyaDemo {
    static func main() async {
        let input: InputMode
        do {
            input = try parseArguments()
        } catch {
            exitWithDiagnostic(error.localizedDescription, code: 2)
        }

        if case .help = input {
            printHelp()
            return
        }

        print("=======================================================")
        print("   🕉️  Vedic Choghadiya Schedule Demo")
        print("=======================================================")

        let manager = ChoghadiyaManager()

        do {
            let schedule: ChoghadiyaSchedule

            switch input {
            case .coordinates(let lat, let lon, let tz, let dateComps):
                print("📍 Coordinates: \(lat), \(lon)")
                print("🌐 Time Zone:   \(tz.identifier)")
                print("⏳ Computing directly from coordinates (no geocoding)...\n")

                let targetDate = resolveDate(components: dateComps, in: tz)
                schedule = try await manager.getSchedule(latitude: lat, longitude: lon, timeZone: tz, date: targetDate)

            case .address(let address, let dateComps):
                print("📍 Location:    \(address)")
                print("⏳ Geocoding address and calculating...\n")

                if let dateComps {
                    // Resolve destination timezone first to ensure date components are constructed in target timezone
                    let geocoder = CLGeocoder()
                    let placemarks: [CLPlacemark]
                    do {
                        placemarks = try await geocoder.geocodeAddressString(address)
                    } catch {
                        throw ChoghadiyaError.geocodingFailed(error.localizedDescription)
                    }
                    guard let placemark = placemarks.first, let loc = placemark.location else {
                        throw ChoghadiyaError.locationNotFound
                    }
                    let tz = placemark.timeZone ?? .current
                    let targetDate = resolveDate(components: dateComps, in: tz)
                    schedule = try await manager.getSchedule(
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude,
                        timeZone: tz,
                        date: targetDate
                    )
                } else {
                    schedule = try await manager.getSchedule(for: address, date: Date())
                }

            case .help:
                return
            }

            let timeZone = schedule.timeZone

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm a"
            timeFormatter.timeZone = timeZone

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
            dateFormatter.timeZone = timeZone

            if let firstSlot = schedule.daySlots.first {
                print("📅 Vedic Date:  \(dateFormatter.string(from: firstSlot.startTime))")
                print("🌐 Time Zone:   \(timeZone.identifier)")
            }

            if let sunrise = schedule.sunrise, let sunset = schedule.sunset {
                print("🌅 Sunrise:     \(timeFormatter.string(from: sunrise))")
                print("🌇 Sunset:      \(timeFormatter.string(from: sunset))\n")
            } else {
                print("")
            }

            // Highlight Currently Active Slot
            if let active = schedule.currentSlot() {
                let badge = indicator(for: active.type)
                print("-------------------------------------------------------")
                print("⭐ CURRENTLY ACTIVE CHOGHADIYA:")
                print("   \(badge) \(active.type.rawValue.uppercased()) (\(active.type.auspiciousness.rawValue))")
                print("   Ruling Graha: \(active.type.rulingPlanet)")
                print("   Window:       \(timeFormatter.string(from: active.startTime)) – \(timeFormatter.string(from: active.endTime))")
                print("-------------------------------------------------------\n")
            }

            // Print Day Slots
            print("☀️ DAY CHOGHADIYA (Sunrise to Sunset):")
            print("-------------------------------------------------------")
            for (index, slot) in schedule.daySlots.enumerated() {
                let badge = indicator(for: slot.type)
                let start = timeFormatter.string(from: slot.startTime)
                let end = timeFormatter.string(from: slot.endTime)
                let name = slot.type.rawValue.padding(toLength: 7, withPad: " ", startingAt: 0)
                let quality = slot.type.auspiciousness.rawValue.padding(toLength: 17, withPad: " ", startingAt: 0)
                print(" \(index + 1). [\(start) - \(end)]  \(badge) \(name)  \(quality) (\(slot.type.rulingPlanet))")
            }
            print("")

            // Print Night Slots
            print("🌙 NIGHT CHOGHADIYA (Sunset to Next Sunrise):")
            print("-------------------------------------------------------")
            for (index, slot) in schedule.nightSlots.enumerated() {
                let badge = indicator(for: slot.type)
                let start = timeFormatter.string(from: slot.startTime)
                let end = timeFormatter.string(from: slot.endTime)
                let name = slot.type.rawValue.padding(toLength: 7, withPad: " ", startingAt: 0)
                let quality = slot.type.auspiciousness.rawValue.padding(toLength: 17, withPad: " ", startingAt: 0)
                print(" \(index + 1). [\(start) - \(end)]  \(badge) \(name)  \(quality) (\(slot.type.rulingPlanet))")
            }

            print("\n=======================================================")
            print("💡 For help & options run: swift run ChoghadiyaDemo --help")
            print("=======================================================")

        } catch {
            exitWithDiagnostic("Failed to compute Choghadiya: \(error.localizedDescription)", code: 1)
        }
    }

    // MARK: - Argument Parsing

    static func parseArguments(_ arguments: [String] = Array(CommandLine.arguments.dropFirst())) throws -> InputMode {
        var args = arguments

        if args.contains("-h") || args.contains("--help") || args.contains("help") {
            return .help
        }

        let supportedOptions: Set<String> = ["--date", "--tz", "--lat", "--lon"]
        var seenOptions: Set<String> = []
        for argument in args where argument.hasPrefix("-") && Double(argument) == nil {
            let coordinateParts = argument.split(separator: ",", omittingEmptySubsequences: false)
            if coordinateParts.count == 2,
               coordinateParts.allSatisfy({ Double($0.trimmingCharacters(in: .whitespaces)) != nil }) {
                continue
            }
            guard supportedOptions.contains(argument) else {
                throw CLIError.argumentError("Unknown option '\(argument)'.")
            }
            guard seenOptions.insert(argument).inserted else {
                throw CLIError.argumentError("Duplicate option '\(argument)'.")
            }
        }
        guard seenOptions.contains("--lat") == seenOptions.contains("--lon") else {
            throw CLIError.argumentError("--lat and --lon must be supplied together.")
        }

        // Extract optional --date YYYY-MM-DD
        var parsedDateComps: DateComponentsInput?
        if let dateIdx = args.firstIndex(of: "--date") {
            guard dateIdx + 1 < args.count else {
                throw CLIError.argumentError("Missing value for --date option. Expected format: YYYY-MM-DD")
            }
            let dateStr = args[dateIdx + 1]
            guard let comps = parseStrictDateString(dateStr) else {
                throw CLIError.argumentError("Invalid date '\(dateStr)'. Expected a valid calendar date in YYYY-MM-DD format.")
            }
            parsedDateComps = comps
            args.remove(at: dateIdx + 1)
            args.remove(at: dateIdx)
        }

        // Extract optional --tz <identifier>
        var flagTimeZone: TimeZone?
        if let tzIdx = args.firstIndex(of: "--tz") {
            guard tzIdx + 1 < args.count else {
                throw CLIError.argumentError("Missing value for --tz option.")
            }
            let tzStr = args[tzIdx + 1]
            guard let tz = TimeZone(identifier: tzStr) else {
                throw CLIError.argumentError("Invalid time zone identifier '\(tzStr)'. Expected a valid IANA time zone identifier (e.g. 'America/New_York', 'Asia/Kolkata').")
            }
            flagTimeZone = tz
            args.remove(at: tzIdx + 1)
            args.remove(at: tzIdx)
        }

        guard !args.isEmpty else {
            guard flagTimeZone == nil else {
                throw CLIError.argumentError("--tz requires coordinates.")
            }
            return .address("Ahmedabad, India", dateComponents: parsedDateComps)
        }

        // Check for explicit --lat and --lon flags
        if let latIndex = args.firstIndex(of: "--lat"), let lonIndex = args.firstIndex(of: "--lon") {
            guard latIndex + 1 < args.count else {
                throw CLIError.argumentError("Missing value for --lat option.")
            }
            guard lonIndex + 1 < args.count else {
                throw CLIError.argumentError("Missing value for --lon option.")
            }
            guard let lat = Double(args[latIndex + 1]) else {
                throw CLIError.argumentError("Invalid latitude value '\(args[latIndex + 1])'. Expected a decimal number.")
            }
            guard let lon = Double(args[lonIndex + 1]) else {
                throw CLIError.argumentError("Invalid longitude value '\(args[lonIndex + 1])'. Expected a decimal number.")
            }
            guard args.count == 4 else {
                throw CLIError.argumentError("Unexpected arguments alongside --lat and --lon.")
            }
            let tz = flagTimeZone ?? .current
            return .coordinates(latitude: lat, longitude: lon, timeZone: tz, dateComponents: parsedDateComps)
        }

        // Check for comma-separated coordinates: e.g. "23.0225,72.5714" ["Asia/Kolkata"]
        if args[0].contains(",") {
            let parts = args[0].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let lat = Double(parts[0]), let lon = Double(parts[1]) {
                guard args.count <= 2 else {
                    throw CLIError.argumentError("Unexpected arguments after coordinates and time zone.")
                }
                guard args.count != 2 || flagTimeZone == nil else {
                    throw CLIError.argumentError("Supply the time zone either positionally or with --tz, not both.")
                }
                let tz: TimeZone
                if args.count == 2 {
                    let tzStr = args[1]
                    guard let parsedTz = TimeZone(identifier: tzStr) else {
                        throw CLIError.argumentError("Invalid time zone identifier '\(tzStr)'. Expected a valid IANA time zone identifier (e.g. 'America/New_York', 'Asia/Kolkata').")
                    }
                    tz = parsedTz
                } else {
                    tz = flagTimeZone ?? .current
                }
                return .coordinates(latitude: lat, longitude: lon, timeZone: tz, dateComponents: parsedDateComps)
            }
        }

        // Check for space-separated numbers: e.g. "23.0225" "72.5714" ["Asia/Kolkata"]
        if args.count >= 2, let lat = Double(args[0]), let lon = Double(args[1]) {
            guard args.count <= 3 else {
                throw CLIError.argumentError("Unexpected arguments after coordinates and time zone.")
            }
            guard args.count != 3 || flagTimeZone == nil else {
                throw CLIError.argumentError("Supply the time zone either positionally or with --tz, not both.")
            }
            let tz: TimeZone
            if args.count > 2 {
                let tzStr = args[2]
                guard let parsedTz = TimeZone(identifier: tzStr) else {
                    throw CLIError.argumentError("Invalid time zone identifier '\(tzStr)'. Expected a valid IANA time zone identifier (e.g. 'America/New_York', 'Asia/Kolkata').")
                }
                tz = parsedTz
            } else {
                tz = flagTimeZone ?? .current
            }
            return .coordinates(latitude: lat, longitude: lon, timeZone: tz, dateComponents: parsedDateComps)
        }

        // Default: treat remaining args as location string
        guard flagTimeZone == nil else {
            throw CLIError.argumentError("--tz requires coordinates.")
        }
        return .address(args.joined(separator: " "), dateComponents: parsedDateComps)
    }

    // MARK: - Date & Calendar Helpers

    private static func resolveDate(components: DateComponentsInput?, in timeZone: TimeZone) -> Date {
        guard let comps = components else { return Date() }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var dc = DateComponents()
        dc.year = comps.year
        dc.month = comps.month
        dc.day = comps.day
        dc.hour = 12
        dc.minute = 0
        dc.second = 0
        return cal.date(from: dc) ?? Date()
    }

    private static func parseStrictDateString(_ str: String) -> DateComponentsInput? {
        let parts = str.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]), parts[0].count == 4,
              let month = Int(parts[1]), parts[1].count == 2, (1...12).contains(month),
              let day = Int(parts[2]), parts[2].count == 2, (1...31).contains(day) else {
            return nil
        }

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = DateComponents(year: year, month: month, day: day)
        guard comps.isValidDate(in: gregorian) else {
            return nil
        }
        return DateComponentsInput(year: year, month: month, day: day)
    }

    // MARK: - Diagnostics & Presentation

    private static func exitWithDiagnostic(_ message: String, code: Int32) -> Never {
        let output = "❌ Error: \(message)\n"
        FileHandle.standardError.write(Data(output.utf8))
        exit(code)
    }

    private static func printHelp() {
        print("""
        OVERVIEW: Astronomical Vedic Choghadiya schedule calculator.

        USAGE:
          swift run ChoghadiyaDemo [<location>] [--date <YYYY-MM-DD>]
          swift run ChoghadiyaDemo <latitude> <longitude> [<timezone>] [--date <YYYY-MM-DD>]
          swift run ChoghadiyaDemo <latitude>,<longitude> [<timezone>] [--date <YYYY-MM-DD>]
          swift run ChoghadiyaDemo --lat <latitude> --lon <longitude> [--tz <timezone>] [--date <YYYY-MM-DD>]

        ARGUMENTS:
          <location>           City or location name (default: "Ahmedabad, India")
          <latitude>           Geographic latitude decimal (e.g. 21.1702)
          <longitude>          Geographic longitude decimal (e.g. 72.8311)
          <timezone>           Optional IANA time zone identifier (e.g. "Asia/Kolkata")

        OPTIONS:
          --date <YYYY-MM-DD>  Compute schedule for a specific date (default: today)
          --lat <latitude>     Geographic latitude decimal
          --lon <longitude>    Geographic longitude decimal
          --tz <timezone>      Target IANA time zone (default: system time zone)
          -h, --help           Show this help information

        EXAMPLES:
          swift run ChoghadiyaDemo
          swift run ChoghadiyaDemo "London, UK"
          swift run ChoghadiyaDemo "Ahmedabad, India" --date 2026-10-24
          swift run ChoghadiyaDemo 21.1702 72.8311
          swift run ChoghadiyaDemo 21.1702 72.8311 Asia/Kolkata --date 2026-09-04
          swift run ChoghadiyaDemo 21.1702,72.8311 Asia/Kolkata
          swift run ChoghadiyaDemo --lat 40.7128 --lon -74.0060 --tz America/New_York
        """)
    }

    private static func indicator(for type: ChoghadiyaType) -> String {
        switch type.auspiciousness {
        case .highlyAuspicious, .auspicious:
            return "🟢"
        case .neutral:
            return "🟡"
        case .inauspicious:
            return "🔴"
        case .avoid:
            return "⛔"
        }
    }
}
