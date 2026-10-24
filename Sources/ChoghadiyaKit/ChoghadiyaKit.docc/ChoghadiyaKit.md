# ``ChoghadiyaKit``

Astronomical Vedic Choghadiya and auspicious timing engine for Apple platforms.

## Overview

**ChoghadiyaKit** computes the 16 planetary divisions of the Vedic Choghadiya system based on astronomical sunrise and sunset times, along with the day's Rahu Kaal, Yamagandam, and Gulika Kaal.

The default ``APISunTimesFetcher`` retrieves solar times from [Sunrise-Sunset.org](https://sunrise-sunset.org). The API is free for reasonable request volumes and requires a visible link wherever its data is displayed. Apps that display these solar times or schedules derived from them must include the attribution in their UI. For custom ``SunTimesFetching`` implementations, follow the configured data provider's attribution terms. The offline ``NOAASunTimesCalculator`` computes solar times on the device and needs no attribution.

### Quick Start
To compute today's Choghadiya schedule:

```swift
import ChoghadiyaKit

let manager = ChoghadiyaManager()
let schedule = try await manager.getSchedule(for: "Ahmedabad, India")

if let current = schedule.currentSlot() {
    print("Currently active: \(current.type.rawValue)")
}
```

A schedule covers its date's sunrise to the next sunrise. Between midnight and sunrise, ``ChoghadiyaSchedule/currentSlot(at:)`` on today's schedule returns `nil`; the active slot belongs to the previous date's schedule.

### Time Zones
When computing by coordinates, pass the location's own time zone: it decides the calendar day and the Vedic weekday. ``APISunTimesFetcher`` throws ``ChoghadiyaError/timeZoneMismatch`` for a time zone that would put sunrise on a different weekday, and ``ChoghadiyaError/polarDayOrNight`` where the sun does not rise or set on the requested date.

### Rahu Kaal, Yamagandam & Gulika Kaal
``ChoghadiyaSchedule/vedicPeriods`` returns the day's three inauspicious periods in chronological order, and ``ChoghadiyaSchedule/vedicPeriod(_:)`` returns one by type. Each occupies the eighth of daylight fixed for the Vedic weekday. Use ``VedicPeriodCalculator`` to compute them directly from ``SunTimes``.

### Offline Calculation
``NOAASunTimesCalculator`` computes sunrise and sunset with the NOAA solar position algorithm, with no network access for coordinate-based calls:

```swift
let manager = ChoghadiyaManager(fetcher: NOAASunTimesCalculator())
let schedule = try await manager.getSchedule(
    latitude: 23.0225,
    longitude: 72.5714,
    timeZone: TimeZone(identifier: "Asia/Kolkata")!
)
```

## Topics

### Core Facade & Orchestration
- ``ChoghadiyaManager``

### Schedule & Domain Models
- ``ChoghadiyaSchedule``
- ``ChoghadiyaSlot``
- ``ChoghadiyaType``
- ``Auspiciousness``
- ``SunTimes``
- ``VedicPeriod``
- ``VedicPeriodType``

### Protocols & Extensibility
- ``ChoghadiyaCalculating``
- ``SunTimesFetching``

### Services & Errors
- ``APISunTimesFetcher``
- ``NOAASunTimesCalculator``
- ``ChoghadiyaError``
- ``ChoghadiyaCalculator``
- ``VedicPeriodCalculator``
