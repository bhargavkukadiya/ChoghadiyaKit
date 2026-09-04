# Changelog

All notable changes to **ChoghadiyaKit** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-03

### Added
- **Core Calculation Engine (`ChoghadiyaCalculator`):**
  - Astronomical schedule calculation for all 16 Vedic Choghadiya periods (8 day, 8 night).
  - Accurate Chaldean planetary hour sequence indexing across all 7 weekdays.
  - $O(1)$ static array indexing and nanosecond boundary clamping against sunset and next sunrise.
- **Domain Modeling:**
  - `ChoghadiyaType`: Represents the 7 planetary rulers (*Udveg*, *Chal*, *Labh*, *Amrit*, *Kaal*, *Shubh*, *Rog*) with ruling graha metadata and `isAuspicious` quality.
  - `Auspiciousness`: Type-safe tiering (`.highlyAuspicious`, `.auspicious`, `.neutral`, `.inauspicious`, `.avoid`).
  - `ChoghadiyaSlot`: Fully conformant to `Identifiable`, `Equatable`, `Hashable`, `Codable`, and `Sendable`.
  - `SunTimes`: Boundary-validated solar data container.
  - `ChoghadiyaSchedule`: High-level schedule queries (`currentSlot(at:)`, `nextSlot(after:)`, `isDaytime(at:)`).
- **Networking & Services:**
  - `APISunTimesFetcher`: Thread-safe `URLSession` client with query-parameter escaping and local timezone (`tzid`) preservation.
  - Dual fetching: by human-readable address string or geographic coordinates.
  - Coordinate range bounds (-90...90 lat, -180...180 lon) and finiteness validation.
  - Solar day normalization accounting for solar longitude offsets and Daylight Saving Time (e.g. Auckland NZDT, Kiritimati) with self-correcting returned date verification.
  - Graceful CoreLocation fallback handling.
- **Architectural Facade & Coordinates:**
  - `ChoghadiyaManager`: High-level facade with full Dependency Inversion Principle (DIP) compliance.
  - Native `CLLocationCoordinate2D` support for seamless CoreLocation and WidgetKit integration.
- **Runnable CLI Demo (`ChoghadiyaDemo`):**
  - Interactive terminal executable target to test live astronomical calculations for any city or coordinates worldwide (`swift run ChoghadiyaDemo`).
  - Supports `--date YYYY-MM-DD` for querying any historical or future calendar date with timezone preservation.
  - Strict date and timezone validation, writing errors to `stderr` with non-zero exit codes.
  - Built-in `--help` / `-h` manual and interactive argument parser.
- **Concurrency & Memory Safety:**
  - Complete Swift 6 strict concurrency readiness (`Sendable` throughout).
  - Zero data races under `-strict-concurrency=complete`.
  - Full toolchain compatibility spanning Swift 5.9 through Swift 6.0.
- **Automated Test Suite:**
  - 31 comprehensive unit tests using universal `XCTest` covering all 7 weekdays, slot continuity, boundary precision, query methods, coordinate bounds validation, local calendar day matching across extreme timezones and DST, `CLLocationCoordinate2D`, and mock dependency injection.
- **Open-Source Infrastructure:**
  - GitHub Actions CI workflow for macOS and Swift 5.9/6.0 testing with automatic Xcode 16 selection.
  - Issue templates for bug reports and feature requests.
  - Pull request template, contributing guidelines, security policy, and Contributor Covenant Code of Conduct.
