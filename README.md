# Scuba Log

A native iOS app for logging and tracking scuba dives, built with SwiftUI and SwiftData.

## Features

**Dive Logging**
- Log dives with detailed information across a multi-tab form: general info, equipment, conditions, and experience
- Required fields: title, location, maximum depth, bottom time
- Optional fields: start/end times, dive type, gas mixture, suit type, water conditions, temperatures, visibility, notes, and more
- Edit or delete existing entries
- Track total dives and cumulative dive time

**Location & Maps**
- Location autocomplete powered by MapKit
- World map view showing all dive sites with smart clustering
- Map preview on individual entries with option to open in Apple Maps

**Photos**
- Attach up to 5 photos per dive
- Full-screen photo viewer
- Inline photo previews in entry details

**Data Management**
- CSV export with share sheet (AirDrop, email, Files, etc.)
- CSV import with duplicate detection and auto-renaming
- iCloud backup and sync via CloudKit
- Metric and imperial unit support

**Customization**
- Toggle between metric (m, kg, Bar, °C) and imperial (ft, lb, PSI, °F)
- Light mode, dark mode, or system default

## Tech Stack

- **SwiftUI** — Declarative UI
- **SwiftData** — Local persistence
- **CloudKit** — iCloud sync 
- **MapKit** — Maps, geocoding, location autocomplete
- **PhotosUI** — Photo picker

## Requirements

- iOS 17.4+
- Xcode 15+

## Project Structure

```
Scuba Log/
├── Scuba_LogApp.swift          # App entry point, SwiftData container setup
├── ContentView.swift           # Main dive log list and tab navigation
├── Entry.swift                 # Data model and enums
├── NewEntryView.swift          # Multi-tab form for creating/editing dives
├── EntryView.swift             # Dive detail view
├── SettingsView.swift          # Settings, CSV export/import
└── TimeInterval+Constants.swift
```

## Getting Started

1. Clone the repository
2. Open `Scuba Log.xcodeproj` in Xcode
3. Select a simulator or device (iOS 17.4+)
4. Build and run

For iCloud sync, ensure you are signed into an iCloud account on the device/simulator and have the CloudKit capability configured with your own container.
