# Headache Detective

Track, understand, and manage your headaches with ease. Headache Detective helps you log symptoms, identify triggers, and discover patterns through beautiful visual insights.

## Features

### Quick Log
One-tap headache logging with pain level selection. Tap any pain level (1–10) to instantly log a headache with current time.

### Detailed Entry
Log comprehensive headache details including:
- Start/end time with quick presets ("Just now", "1h ago", etc.)
- Pain level slider with severity badges (Mild / Moderate / Severe)
- Head pain map – tap where it hurts on an interactive head silhouette
- Before section – what you were doing 2–6 hours before, with quick trigger picks
- Symptoms (Throbbing, Nausea, Light/Sound sensitivity, Aura)
- Relief methods and medications
- Free-form notes

### Widgets (iOS 16+)
- **Home Screen widget** – Quick-add from your home screen (deep-links to Add tab)
- **Lock Screen widget** – Quick-add from the Lock Screen

### Calendar
- Monthly calendar view with color-coded pain severity dots
- Tap a day to browse entries
- Navigate between months with animated controls

### Siri Shortcuts (iOS 16+)
- "Hey Siri, log a headache" – voice-activated logging
- "Hey Siri, log a headache with pain level 8" – specify severity
- App Intent integration for the Shortcuts app

### Insights
- **Frequency** – counts for this month, last 30 days, all time, average pain
- **Weekday patterns** – which days of the week have the most headaches
- **Time of day** – distribution across Morning, Afternoon, Evening, Night
- **Top triggers** – most common triggers ranked by frequency
- **Pain locations** – where on the head you feel pain most often
- **Trigger impact** – how each trigger affects pain severity (with/without comparison)
- Animated bar charts and stat cards

### HealthKit (iOS 16+)
- Writes headache samples to the Health app
- Pain levels mapped to severity (Mild / Moderate / Severe)
- Writes start and end time for each episode

### History
- Searchable, filterable list of all entries
- Severity badges, trigger chips, symptom icons
- Swipe-to-delete with haptic feedback
- Share entries as text

## Requirements

- iOS 16.0+
- Xcode 16.5+
- Swift 5.0+

## Installation

### App Store
*Coming soon*

### Manual Build
1. Clone the repository
2. Open `Headache Detective.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on a device or simulator running iOS 16+

## Architecture

- **SwiftUI** – entire UI built with SwiftUI
- **Core Data** – local persistence with `NSPersistentContainer`
- **App Group** (`group.HeadacheDetective`) – shared Core Data store between app and widget extension
- **WidgetKit** – Home Screen and Lock Screen widgets
- **App Intents** – Siri integration for voice-based logging
- **HealthKit** – writes headache data to Apple Health
- **MVVM** – lightweight pattern with `@EnvironmentObject` for data fetching

## Project Structure

```
Headache Detective/
├── CoreData/
│   ├── HeadacheDetective.xcdatamodeld/   # Core Data model
│   ├── HeadacheEntry+CoreDataClass.swift
│   ├── HeadacheEntry+CoreDataProperties.swift
│   └── PersistenceController.swift       # NSPersistentContainer setup
├── Intents/
│   └── LogHeadacheIntent.swift           # Siri / Shortcuts integration
├── Models/
│   ├── HeadacheEntry+Helpers.swift       # Convenience methods
│   └── HeadacheModels.swift              # Enums, pain regions, symptom types
├── Services/
│   ├── HealthKitService.swift            # HealthKit authorization & writing
│   └── InsightsCalculator.swift          # Analytics & pattern detection
├── Theme/
│   └── AppTheme.swift                    # Colors, animations, CardSection
├── ViewModels/
│   └── EntryFetchController.swift        # Fetches & caches entries
├── Views/
│   ├── Add/
│   │   └── AddEntryView.swift            # Quick log + detailed form
│   ├── Calendar/
│   │   └── CalendarView.swift            # Month grid + day sheet
│   ├── Components/
│   │   └── HeadPainMapView.swift         # Interactive head silhouette
│   ├── History/
│   │   └── HistoryView.swift             # Entry list + detail
│   ├── Insights/
│   │   └── InsightsView.swift            # Charts & analytics
│   └── MainTabView.swift                 # Tab navigation
├── Headache_DetectiveApp.swift           # App entry + deep-link handler
├── ContentView.swift
└── Headache Detective.entitlements       # HealthKit entitlement
Widgets/
├── HeadacheWidgets.swift                 # Widget bundle + provider
└── (WidgetInfo.plist)
```

## Configuration

### App Groups
App Group `group.HeadacheDetective` is configured for shared Core Data access.

### URL Scheme
`headache-detective://add` deep-links to the Add tab from widgets.

### Entitlements
- `com.apple.developer.healthkit` – HealthKit write access

## Build Notes

- Deployment target: iOS 16.0 (required for Lock Screen widgets and App Intents)
- Widget extension uses manual `Info.plist` (`WidgetInfo.plist`)
- Build with Xcode 16.5 or later
- No external dependencies – pure SwiftUI + system frameworks

## License

Copyright © 2026 Headache Detective. All rights reserved.
