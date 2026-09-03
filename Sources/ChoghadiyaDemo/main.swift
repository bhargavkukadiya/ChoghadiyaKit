//
//  main.swift
//  ChoghadiyaDemo
//
//  Created by Bhargav Kukadiya.
//

import Foundation
import ChoghadiyaKit

enum InputMode {
    case coordinates(latitude: Double, longitude: Double, timeZone: TimeZone)
    case address(String)
}

@main
struct ChoghadiyaDemo {
    static func main() async {
        let input = parseArguments()

        print("=======================================================")
        print("   🕉️  Vedic Choghadiya Schedule Demo")
        print("=======================================================")

        let manager = ChoghadiyaManager()

        do {
            let schedule: ChoghadiyaSchedule

            switch input {
            case .coordinates(let lat, let lon, let tz):
                print("📍 Coordinates: \(lat), \(lon)")
                print("🌐 Time Zone:   \(tz.identifier)")
                print("⏳ Computing directly from coordinates (no geocoding)...\n")
                schedule = try await manager.getSchedule(latitude: lat, longitude: lon, timeZone: tz)

            case .address(let address):
                print("📍 Location:    \(address)")
                print("⏳ Geocoding address and calculating...\n")
                schedule = try await manager.getSchedule(for: address)
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
                print("🌐 Time Zone:   \(timeZone.identifier)\n")
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
            print("💡 Usage examples:")
            print("   swift run ChoghadiyaDemo \"London, UK\"")
            print("   swift run ChoghadiyaDemo 23.0225 72.5714")
            print("   swift run ChoghadiyaDemo 23.0225 72.5714 Asia/Kolkata")
            print("   swift run ChoghadiyaDemo --lat 23.0225 --lon 72.5714")
            print("=======================================================")

        } catch {
            print("❌ Error computing Choghadiya: \(error.localizedDescription)")
        }
    }

    private static func parseArguments() -> InputMode {
        let args = Array(CommandLine.arguments.dropFirst())

        guard !args.isEmpty else {
            return .address("Ahmedabad, India")
        }

        // Check for --lat and --lon flags
        if let latIndex = args.firstIndex(of: "--lat"), latIndex + 1 < args.count,
           let lonIndex = args.firstIndex(of: "--lon"), lonIndex + 1 < args.count,
           let lat = Double(args[latIndex + 1]),
           let lon = Double(args[lonIndex + 1]) {
            let tz: TimeZone
            if let tzIndex = args.firstIndex(of: "--tz"), tzIndex + 1 < args.count,
               let customTz = TimeZone(identifier: args[tzIndex + 1]) {
                tz = customTz
            } else {
                tz = .current
            }
            return .coordinates(latitude: lat, longitude: lon, timeZone: tz)
        }

        // Check for comma-separated coordinates: e.g. "23.0225,72.5714"
        if args.count == 1 && args[0].contains(",") {
            let parts = args[0].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let lat = Double(parts[0]), let lon = Double(parts[1]) {
                return .coordinates(latitude: lat, longitude: lon, timeZone: .current)
            }
        }

        // Check for space-separated numbers: e.g. "23.0225" "72.5714" ["Asia/Kolkata"]
        if args.count >= 2, let lat = Double(args[0]), let lon = Double(args[1]) {
            let tz = args.count > 2 ? (TimeZone(identifier: args[2]) ?? .current) : .current
            return .coordinates(latitude: lat, longitude: lon, timeZone: tz)
        }

        // Default: treat as location string
        return .address(args.joined(separator: " "))
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
