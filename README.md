<p align="center">
  <h1 align="center">🕉️ ChoghadiyaKit</h1>
  <p align="center">
    <strong>Astronomical Vedic Choghadiya & Auspicious Timing Engine for Apple Platforms</strong>
  </p>
  <p align="center">
    <a href="https://github.com/bhargavkukadiya/ChoghadiyaKit/releases"><img src="https://img.shields.io/github/v/release/bhargavkukadiya/ChoghadiyaKit?style=flat-square&color=007AFF" alt="Latest Release"></a>
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9%20%7C%206.0-F05138.svg?style=flat-square&logo=swift" alt="Swift 5.9 | 6.0"></a>
    <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/Platforms-iOS%2015+%20%7C%20macOS%2012+%20%7C%20watchOS%208+%20%7C%20tvOS%2015+-007AFF.svg?style=flat-square&logo=apple" alt="Platforms"></a>
    <a href="https://docs.swift.org/compiler/documentation/diagnostics/sending-risks-data-race/"><img src="https://img.shields.io/badge/Swift%206-Strict%20Concurrency%20Safe-34C759.svg?style=flat-square" alt="Swift 6 Strict Concurrency"></a>
    <a href="https://github.com/bhargavkukadiya/ChoghadiyaKit/actions"><img src="https://img.shields.io/badge/CI-Passing-brightgreen.svg?style=flat-square" alt="CI Status"></a>
    <a href="https://github.com/bhargavkukadiya/ChoghadiyaKit/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-black.svg?style=flat-square" alt="License: MIT"></a>
  </p>
</p>

---

## Overview

**ChoghadiyaKit** is a lightweight, zero-dependency, production-grade Swift Package designed to compute Vedic **Choghadiya** (auspicious and inauspicious planetary hours) with astronomical precision.

Whether you are developing an iOS companion app, macOS menu bar utility, watchOS complication, or WidgetKit timeline, ChoghadiyaKit provides a clean, protocol-oriented API with full `Sendable` concurrency guarantees and first-class SwiftUI bindings.

---

## Table of Contents

- [The Science of Choghadiya](#the-science-of-choghadiya)
- [Key Features](#key-features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [1. Schedule by Location Name](#1-schedule-by-location-name)
  - [2. Schedule by Coordinates (Widgets & CoreLocation)](#2-schedule-by-coordinates-widgets--corelocation)
  - [3. Schedule for a Specific Calendar Date](#3-schedule-for-a-specific-calendar-date)
  - [4. Querying Active, Upcoming Slots & Solar Times](#4-querying-active-upcoming-slots--solar-times)
  - [5. Complete SwiftUI Integration](#5-complete-swiftui-integration)
- [Architecture & Testing](#architecture--testing)
  - [Dependency Injection & Mocking](#dependency-injection--mocking)
  - [Verifying Strict Concurrency](#verifying-strict-concurrency)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## The Science of Choghadiya

In Vedic timekeeping (*Panchang*), a solar day is measured from **local astronomical sunrise to the subsequent local sunrise**. The daytime and nighttime are each partitioned into **8 equal divisions** (16 divisions total per 24-hour cycle).

Each division is ruled by a celestial body (*Graha*) in a cyclic sequence based on the Chaldean planetary order. Each period carries an intrinsic nature:

| Choghadiya | Vedic Meaning | Auspiciousness Tier | Ruling Planet (Graha) | Recommended Action |
| :--- | :--- | :--- | :--- | :--- |
| **Amrit** | *Nectar* | `highlyAuspicious` | Moon (*Chandra*) | Highest auspiciousness. Best for ceremonies, healthcare, and vital beginnings. |
| **Shubh** | *Good / Auspicious* | `auspicious` | Jupiter (*Guru*) | Highly favorable. Ideal for weddings, education, and sacred events. |
| **Labh** | *Gain / Profit* | `auspicious` | Mercury (*Budha*) | Profitable. Perfect for commercial trade, investments, and acquiring new assets. |
| **Chal** | *Mobile / Neutral* | `neutral` | Venus (*Shukra*) | Moderate. Suitable for routine activities, journeys, and commutes. |
| **Udveg** | *Anxiety / Stress* | `inauspicious` | Sun (*Surya*) | High friction. Avoid legal settlements, financial agreements, and conflict. |
| **Kaal** | *Destruction / Loss* | `inauspicious` | Saturn (*Shani*) | Inauspicious. Avoid commencing money-making projects or celebratory occasions. |
| **Rog** | *Disease / Harm* | `avoid` | Mars (*Mangal*) | Detrimental. Strongly advised against starting critical tasks. |

---

## Key Features

* ☀️ **Astronomical Solar Derivation:** Computes exact slot boundaries dynamically adjusted to local sunrise, sunset, and twilight parameters.
* 🛡️ **Swift 6 Strict Concurrency:** Every model, protocol, and facade strictly conforms to `Sendable`. Zero compiler warnings with `-strict-concurrency=complete`.
* 📱 **Native SwiftUI Integration:** `ChoghadiyaSlot` conforms to `Identifiable`, `Hashable`, and `Codable` for seamless use in `ForEach`, `Table`, and `TimelineView`.
* ⚡ **Zero External Dependencies:** Built entirely with standard Apple frameworks (`Foundation`, `CoreLocation`).
* 🧩 **Clean Architecture:** Fully decoupled protocols (`ChoghadiyaCalculating`, `SunTimesFetching`) allowing easy mock injection for unit and UI testing.
* 🧪 **100% Tested:** 32 comprehensive unit tests covering all 7 weekdays, slot continuity, coordinate validation, solar day normalization, and boundary edge cases.

---

## System Requirements

| Platform | Minimum Deployment Target |
| :--- | :--- |
| **iOS** | 15.0+ |
| **macOS** | 12.0+ (Monterey) |
| **watchOS** | 8.0+ |
| **tvOS** | 15.0+ |
| **Swift Toolchain** | Swift 5.9+ / Swift 6.0+ |
| **Xcode** | Xcode 15.0+ |

---

## Installation

### Swift Package Manager (SPM)

#### Inside Xcode
1. Open your project in Xcode.
2. Select **File** → **Add Package Dependencies...**
3. In the search bar, enter:
   ```
   https://github.com/bhargavkukadiya/ChoghadiyaKit.git
   ```
4. Set the dependency rule to **Up to Next Major Version** starting at `1.0.1`.
5. Click **Add Package**.

#### Via `Package.swift`
Add the dependency to your `Package.swift` manifest:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApplication",
    platforms: [.iOS(.v15), .macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/bhargavkukadiya/ChoghadiyaKit.git", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "MyApplication",
            dependencies: [
                .product(name: "ChoghadiyaKit", package: "ChoghadiyaKit")
            ]
        )
    ]
)
```

---

## Quick Start

### 🚀 Try the Live Terminal Demo

You can immediately calculate the live Choghadiya schedule for any city directly in your terminal:

```bash
# Calculate today's schedule for Ahmedabad, India (default):
swift run ChoghadiyaDemo

# Query by city name:
swift run ChoghadiyaDemo "London, UK"
swift run ChoghadiyaDemo "New York, USA"

# Query directly by coordinates (lat, lon, and optional timezone):
swift run ChoghadiyaDemo 23.0225 72.5714 Asia/Kolkata
swift run ChoghadiyaDemo --lat 40.7128 --lon -74.0060 --tz America/New_York

# Query specific dates (past, present, or future):
swift run ChoghadiyaDemo "Ahmedabad, India" --date 2026-10-24
swift run ChoghadiyaDemo 21.1702 72.8311 --date 2026-09-04

# View full CLI help and available options:
swift run ChoghadiyaDemo --help
```

---

### 1. Schedule by Location Name

```swift
import Foundation
import ChoghadiyaKit

let manager = ChoghadiyaManager()

do {
    let schedule = try await manager.getSchedule(for: "Ahmedabad, India")

    print("Computed \(schedule.daySlots.count) day slots & \(schedule.nightSlots.count) night slots.")

    for slot in schedule.daySlots {
        print("☀️ \(slot.type.rawValue) (\(slot.type.auspiciousness.rawValue)): \(slot.startTime) - \(slot.endTime)")
    }
} catch {
    print("Failed to compute schedule: \(error.localizedDescription)")
}
```

---

### 2. Schedule by Coordinates (Widgets & CoreLocation)

For **WidgetKit extensions**, **watchOS Complications**, or background tasks where `CLGeocoder` may be rate-limited, supply pre-resolved coordinates directly:

```swift
import Foundation
import CoreLocation
import ChoghadiyaKit

let manager = ChoghadiyaManager()

// Option A: Using CLLocationCoordinate2D directly
let coordinate = location.coordinate // CLLocationCoordinate2D
let schedule = try await manager.getSchedule(coordinate: coordinate, timeZone: .current)

// Option B: Using explicit latitude and longitude values
let latitude = 23.0225
let longitude = 72.5714
let timeZone = TimeZone(identifier: "Asia/Kolkata")!

let schedule = try await manager.getSchedule(
    latitude: latitude,
    longitude: longitude,
    timeZone: timeZone,
    date: Date()
)
```

---

### 3. Schedule for a Specific Calendar Date

Compute historical or future Choghadiya schedules with dynamic solar sunrise and sunset adjustments:

```swift
import Foundation
import ChoghadiyaKit

let manager = ChoghadiyaManager()

// Any past, present, or future Date (e.g., Diwali — October 24, 2026):
var components = DateComponents()
components.year = 2026
components.month = 10
components.day = 24
let targetDate = Calendar.current.date(from: components)!

// By location name:
let schedule = try await manager.getSchedule(
    for: "Ahmedabad, India",
    date: targetDate
)

// Or by coordinates:
let scheduleWithCoords = try await manager.getSchedule(
    coordinate: location.coordinate,
    date: targetDate
)
```

---

### 4. Querying Active, Upcoming Slots & Solar Times

`ChoghadiyaSchedule` provides high-level convenience query APIs:

```swift
// Inspect astronomical solar boundaries
if let sunrise = schedule.sunrise, let sunset = schedule.sunset {
    print("Sunrise: \(sunrise)")
    print("Sunset:  \(sunset)")
}

// Get the slot active right now
if let current = schedule.currentSlot() {
    print("Now Active: \(current.type.rawValue)")
    print("Is Auspicious: \(current.type.isAuspicious)")
    print("Ruling Graha: \(current.type.rulingPlanet)")
    print("Ends at: \(current.endTime)")
}

// Get the immediate next slot
if let next = schedule.nextSlot() {
    print("Next Up: \(next.type.rawValue) starting at \(next.startTime)")
}

// Check if currently daytime
let isDay = schedule.isDaytime()
print("Currently in daytime Choghadiya: \(isDay)")
```

---

### 5. Complete SwiftUI Integration

Because `ChoghadiyaSlot` conforms to `Identifiable`, you can pass slots directly to SwiftUI lists and grids without manual `id:` keypaths:

```swift
import SwiftUI
import ChoghadiyaKit

struct ChoghadiyaDashboardView: View {
    let schedule: ChoghadiyaSchedule

    var body: some View {
        List {
            Section {
                if let current = schedule.currentSlot() {
                    CurrentSlotCard(slot: current)
                }
            } header: {
                Text("Currently Active")
            }

            Section("Day Choghadiya (Sunrise to Sunset)") {
                ForEach(schedule.daySlots) { slot in
                    SlotRowView(slot: slot)
                }
            }

            Section("Night Choghadiya (Sunset to Sunrise)") {
                ForEach(schedule.nightSlots) { slot in
                    SlotRowView(slot: slot)
                }
            }
        }
        .navigationTitle("Choghadiya")
    }
}

struct SlotRowView: View {
    let slot: ChoghadiyaSlot

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(slot.type.isAuspicious ? Color.green : Color.orange)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.type.rawValue)
                    .font(.headline)
                Text(slot.type.rulingPlanet)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(slot.startTime, style: .time) – \(slot.endTime, style: .time)")
                    .font(.subheadline)
                    .monospacedDigit()

                Text(slot.type.auspiciousness.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(slot.type.isAuspicious ? .green : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CurrentSlotCard: View {
    let slot: ChoghadiyaSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active Now: \(slot.type.rawValue)")
                    .font(.title2.bold())
                Spacer()
                Text(slot.type.auspiciousness.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(slot.type.isAuspicious ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .foregroundColor(slot.type.isAuspicious ? .green : .orange)
                    .clipShape(Capsule())
            }
            Text("Ends at \(slot.endTime, style: .time)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
```

---

## Architecture & Testing

ChoghadiyaKit adheres to SOLID principles and Clean Architecture:

```
Sources/ChoghadiyaKit/
├── Models/
│   ├── Auspiciousness.swift      # Typed auspiciousness tiers (.highlyAuspicious, .auspicious, etc.)
│   ├── ChoghadiyaType.swift       # 7 Planetary rulers, graha deities, and qualities
│   ├── ChoghadiyaSlot.swift       # Identifiable slot representation
│   ├── SunTimes.swift             # Astronomical solar container with boundary validation
│   └── ChoghadiyaSchedule.swift   # Schedule representation with query methods
├── Protocols/
│   ├── ChoghadiyaCalculating.swift # Sendable protocol for schedule calculations
│   └── SunTimesFetching.swift     # Sendable protocol for astronomical retrieval
├── Calculator/
│   └── ChoghadiyaCalculator.swift # O(1) static indexing & sub-millisecond boundary clamping
├── Services/
│   ├── ChoghadiyaError.swift      # Domain errors conforming to LocalizedError & Sendable
│   └── APISunTimesFetcher.swift   # URLSession-backed client with tzid timezone escaping
└── Facade/
    └── ChoghadiyaManager.swift    # High-level coordinator adhering to Dependency Inversion

Sources/ChoghadiyaDemo/
└── main.swift                     # Interactive runnable terminal CLI demo

Tests/ChoghadiyaKitTests/
├── APISunTimesFetcherTests.swift   # Coordinate validation, URLProtocol stubbing & local day checks
├── ChoghadiyaCalculatorTests.swift # Verification across all 7 weekdays & boundaries
├── ChoghadiyaScheduleTests.swift   # Active/next slot queries, Codable & Identifiable
├── ChoghadiyaManagerTests.swift    # Mock injection, DIP & coordinate tests
└── ChoghadiyaTypeTests.swift       # Auspiciousness qualities & ruling Grahas
```

### Dependency Injection & Mocking

`ChoghadiyaManager` accepts protocols for both astronomical retrieval and schedule calculations, making unit testing completely deterministic with zero network activity:

```swift
final class MockSunTimesFetcher: SunTimesFetching, @unchecked Sendable {
    func fetchSunTimes(for location: String, date: Date) async throws -> SunTimes {
        return SunTimes(
            sunrise: Date(),
            sunset: Date().addingTimeInterval(43200),
            nextSunrise: Date().addingTimeInterval(86400),
            timeZone: .current
        )
    }

    func fetchSunTimes(latitude: Double, longitude: Double, timeZone: TimeZone, date: Date) async throws -> SunTimes {
        return try await fetchSunTimes(for: "", date: date)
    }
}

// Inject in your test:
let manager = ChoghadiyaManager(fetcher: MockSunTimesFetcher())
```

### Verifying Strict Concurrency

Run tests locally with complete Swift 6 strict concurrency checks:

```bash
swift test -Xswiftc -strict-concurrency=complete
```

---

## Roadmap

- [ ] **Offline Solar Engine:** Add a pure Swift implementation of the NOAA Astronomical Solar Algorithm for 100% offline, zero-network calculation.
- [ ] **Rahu Kaal, Yamagandam & Gulika Kaal:** Add complementary Vedic period calculators.
- [ ] **Abhijit Muhurat:** Calculation of the midday auspicious 8th Muhurat.
- [ ] **DocC Documentation:** Hosted interactive documentation on GitHub Pages.

---

## Contributing

We welcome community contributions, bug fixes, and feature proposals. Please review our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before opening a Pull Request.

---

## License

ChoghadiyaKit is released under the **MIT License**. See the [LICENSE](LICENSE) file for complete details.

Copyright © 2026 **Bhargav Kukadiya**. All rights reserved.
