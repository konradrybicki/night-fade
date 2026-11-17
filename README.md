# SleepyTune

An iOS and watchOS app that pauses Spotify or Apple Music when you fall asleep.

> Status: early setup. The project skeleton is in place, and features haven't been implemented yet.

## Modes

| Mode | How it works | Sleep analytics |
|---|---|---|
| **AirPods** | Guides you to turn on the AirPods' built-in sleep detection | — |
| **Apple Watch** | The Watch app detects sleep from heart rate and motion, and the iPhone pauses playback | ✓ |
| **Timer** | Playback stops after a set time | ✓ |

Works with **Apple Music** and **Spotify** (Spotify needs Premium).

## Requirements

- Xcode 27.0 or later (CI uses 27.0)
- iOS 26.0+ and watchOS 26.0+

## Getting started

1. To run on a device, create `Config/Local.xcconfig` (gitignored) with your team ID. Simulator builds work without it.
   ```
   DEVELOPMENT_TEAM = <your team ID>
   ```
   Set the team here rather than in Xcode's Signing & Capabilities tab, which would write it into the shared project file. With a free Personal Team, also add `APP_BUNDLE_IDENTIFIER = com.konradrybicki.sleepytune.temp`, so the real bundle ID isn't registered to that team.
2. Enable the project's Git hooks. They only warn, for example about formatting or commit messages:
   ```bash
   git config core.hooksPath .githooks
   ```
3. Open `SleepyTune.xcodeproj` and run the `SleepyTune` scheme. The Watch app is embedded automatically, and the `SleepyTuneWatch` scheme runs it on its own.

Command line:

```bash
swift test --package-path Packages/Domain
```

```bash
xcodebuild build -project SleepyTune.xcodeproj -scheme SleepyTune -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

## Project structure

```
SleepyTune/
├── SleepyTune.xcodeproj
├── SleepyTune/            # iOS app target
├── SleepyTuneWatch/       # watchOS app target
├── Packages/
│   └── Domain/            # Shared domain models and session state machine (empty for now)
├── Config/                # .xcconfig build settings (Local.xcconfig is gitignored)
├── docs/                  # Features, architecture decisions and conventions
├── .githooks/             # Local Git hooks (warn only)
└── .github/workflows/     # CI (pull requests only)
```

App targets use Xcode's folder-synchronized groups: files you add to `SleepyTune/` or `SleepyTuneWatch/` on disk show up in the project automatically.

## Tech stack

- SwiftUI, Swift 6 with strict concurrency, Combine where it fits
- MVVM with `@Observable` view models, and Coordinators for navigation
- SwiftData + CloudKit, MusicKit, HealthKit, WatchConnectivity, Swift Charts
- Swift Package Manager (local packages), Swift Testing, swift-format
- Python backend for Spotify, added later

Details are in [docs/architecture.md](docs/architecture.md). The feature scope and build order are in [docs/features.md](docs/features.md).

## Contributing

Branching, commit messages and code style are described in [docs/conventions.md](docs/conventions.md). In short:

- `develop` is the default branch; `main` holds production code. Both are protected and only change through pull requests: squash-merged for features, merge commits for releases.
- Work branches use the prefixes `feature/`, `bugfix/`, `refactor/`, `chore/` and `docs/`.
- Commits use the Conventional Commits format with the same types, e.g. `feature(onboarding): add mode selection screen`.
