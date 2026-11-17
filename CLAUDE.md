# CLAUDE.md

SleepyTune is an iOS and watchOS app that pauses Spotify or Apple Music when the user falls asleep. It has three modes: AirPods, Apple Watch and Timer. Read `docs/features.md` for the scope and build order, `docs/architecture.md` before designing features and `docs/conventions.md` before branching or committing.

## Layout
- `SleepyTune/`: iOS app target. Folder-synchronized group, so new files on disk are picked up automatically, with no `project.pbxproj` edits.
- `SleepyTuneWatch/`: watchOS app target, embedded in the iOS app. Also a synchronized group.
- `Packages/Domain/`: local SPM package linked by both apps. Add new packages under `Packages/` with the feature that needs them; package names are decided at implementation time.
- `Config/Shared.xcconfig`: bundle IDs, versions, deployment targets and Swift settings. `Config/Local.xcconfig` holds per-developer values and is gitignored. It is not encrypted: never put real secrets in it or anywhere in the app, because the repo is public and the app bundle is readable. Real secrets belong on the backend.

## Commands
- Format: `swift format --in-place --recursive --parallel SleepyTune SleepyTuneWatch Packages`
- Lint (same as CI): `swift format lint --strict --recursive --parallel SleepyTune SleepyTuneWatch Packages`
- Package tests: `swift test --package-path Packages/Domain`
- iOS build: `xcodebuild build -project SleepyTune.xcodeproj -scheme SleepyTune -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`
- watchOS build: same, with `-scheme SleepyTuneWatch -destination 'generic/platform=watchOS Simulator'`

## Conventions
- Swift 6 language mode with complete strict concurrency. Default isolation is `nonisolated` in both apps and packages: mark UI-facing types (view models, coordinators, UI services) `@MainActor` explicitly. Views and `App` types get it from SwiftUI's protocols.
- Packages and apps must behave the same: every local package enables the `swiftSettings` block from `Packages/Domain/Package.swift` (`NonisolatedNonsendingByDefault`, `InferIsolatedConformances`, `MemberImportVisibility`). That makes `nonisolated async` functions run on the caller's actor everywhere; use `@concurrent` for real background work.
- MVVM with `@Observable` view models, Coordinators for navigation (not a Router), protocol-based services, no DI framework.
- Combine only where it fits naturally. Otherwise use async/await, and bridge delegate APIs to `AsyncStream`.
- Swift Testing for tests.
- SwiftData models must be CloudKit-compatible: no unique attributes, defaults or optionals everywhere, optional relationships.
- Never persist HealthKit sleep stages or raw heart-rate data to iCloud.
- Branches: `feature/`, `bugfix/`, `refactor/`, `chore/`, `docs/` off `develop`. Commits and PR titles: `<type>(<scope>): <imperative summary>` with the same types.
- `develop` and `main` are protected: changes only land through pull requests. Feature PRs are squash-merged into `develop`; release PRs are merged into `main` with a merge commit (never squashed), tagged, then brought back into `develop`.
- Code review is local (`/code-review` against `develop`) before a PR is opened. CI runs on pull requests only.
- Git hooks in `.githooks/` only warn and never block. Don't bypass or "fix" them to block.
- Leave changes uncommitted unless the user asks for a commit.
