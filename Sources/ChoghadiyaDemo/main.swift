//
//  main.swift
//  ChoghadiyaDemo
//
//  Created by Bhargav Kukadiya.
//

import Foundation
import ChoghadiyaKit

@main
struct ChoghadiyaDemo {
    static func main() async {
        let location = CommandLine.arguments.count > 1
            ? CommandLine.arguments.dropFirst().joined(separator: " ")
            : "Ahmedabad, India"

        print("=======================================================")
        print("   🕉️  Vedic Choghadiya Schedule Demo")
        print("=======================================================")
        print("📍 Location: \(location)")
        print("⏳ Fetching astronomical sun times and calculating...\n")

        let manager = ChoghadiyaManager()

        do {
            let schedule = try await manager.getSchedule(for: location)
            let timeZone = schedule.timeZone

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm a"
            timeFormatter.timeZone = timeZone

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
            dateFormatter.timeZone = timeZone

            if let firstSlot = schedule.daySlots.first {
                print("📅 Vedic Date: \(dateFormatter.string(from: firstSlot.startTime))")
                print("🌐 Time Zone:  \(timeZone.identifier)\n")
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
            print("💡 Tip: You can query any city: swift run ChoghadiyaDemo \"London, UK\"")
            print("=======================================================")

        } catch {
            print("❌ Error computing Choghadiya for '\(location)': \(error.localizedDescription)")
        }
    }

    private static func indicator(for type: ChoghadiyaType) -> String {
        switch type.auspiciousness {
        case .highlyAuspicious:
            return "🟢"
        case .auspicious:
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
