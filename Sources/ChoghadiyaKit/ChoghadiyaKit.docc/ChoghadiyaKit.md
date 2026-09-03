# ``ChoghadiyaKit``

Astronomical Vedic Choghadiya and auspicious timing engine for Apple platforms.

## Overview

**ChoghadiyaKit** computes the 16 planetary divisions of the Vedic Choghadiya system based on astronomical sunrise and sunset times.

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
