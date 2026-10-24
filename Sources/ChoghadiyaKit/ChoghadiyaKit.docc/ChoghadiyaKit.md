# ``ChoghadiyaKit``

Astronomical Vedic Choghadiya and auspicious timing engine for Apple platforms.

## Overview

**ChoghadiyaKit** computes the 16 planetary divisions of the Vedic Choghadiya system based on astronomical sunrise and sunset times.

The default ``APISunTimesFetcher`` retrieves solar times from [Sunrise-Sunset.org](https://sunrise-sunset.org). The API is free for reasonable request volumes and requires a visible link wherever its data is displayed. Apps that display these solar times or schedules derived from them must include the attribution in their UI. For custom ``SunTimesFetching`` implementations, follow the configured data provider's attribution terms.

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

## Topics

### Core Facade & Orchestration
- ``ChoghadiyaManager``

### Schedule & Domain Models
- ``ChoghadiyaSchedule``
- ``ChoghadiyaSlot``
- ``ChoghadiyaType``
- ``Auspiciousness``
- ``SunTimes``

### Protocols & Extensibility
- ``ChoghadiyaCalculating``
- ``SunTimesFetching``

### Services & Errors
- ``APISunTimesFetcher``
- ``ChoghadiyaError``
- ``ChoghadiyaCalculator``
