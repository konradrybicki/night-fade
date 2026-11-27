# Architecture

Decisions made so far, before implementation. Update this file when a decision changes.

## Modes

The user picks one of three modes:

| Mode | Who pauses playback | Analytics |
|---|---|---|
| **AirPods** | The system (AirPods sleep detection) | Locked: iOS gives apps no signal when this happens |
| **Apple Watch** | Our watchOS app detects sleep, the iPhone pauses | Exact moment of sleep detection and pause |
| **Timer** | Our app (Apple Music) or our backend (Spotify) | Exact stop time |

### AirPods
- iOS doesn't expose the AirPods "fell asleep" signal to third-party apps.
- There's no supported deep link to the AirPods settings page (`App-prefs:` URLs are rejected in review), so the app shows a step-by-step guide.
- Device detection: `AVAudioSession.currentRoute` shows that Bluetooth headphones are connected and their user-given name, but not the model. Guess from the name, then let the user confirm the model.

### Apple Watch
- The Watch app runs an `HKWorkoutSession`, which keeps it running all night, and detects sleep from heart rate and wrist motion. Thresholds need tuning on real nights.
- The Watch is a **sensor only**. It holds no tokens and never calls the backend.

### Timer
- **Apple Music:** works only if playback runs through our own `ApplicationMusicPlayer`. Owning the audio session keeps the app alive in the background, so the timer fires.
- **Spotify:** our app is suspended in the background, so the backend schedules the `pause` call.

## Components

1. **iOS app (main):** onboarding, mode selection, player, timer, analytics, Spotify login. Acts as the **coordinator**.
2. **watchOS app:** sleep detection and the pause trigger.
3. **Python backend (Spotify only, built last):** stores Spotify tokens, refreshes them, schedules pauses, and makes every Spotify Web API call.
4. **Local Swift packages:** shared code for both apps, starting with `Domain`. Other packages are added together with the features that need them.

## Watch mode flow

1. The user starts a session on the iPhone. The phone sends the config to the Watch, and the Watch starts the workout session.
2. The Watch detects sleep and calls `sendMessage("sleepDetected", time)`, which wakes the iPhone app in the background.
3. The iPhone pauses playback:
   - Apple Music: `MPMusicPlayerController.systemMusicPlayer.pause()`
   - Spotify: `POST /pause` to the backend, which calls the Spotify Web API
4. The iPhone replies to the Watch, and the Watch ends its workout session.
5. The iPhone saves the `SleepSession`.

If the iPhone isn't reachable, the Watch retries for a few minutes. If it still fails, the session is recorded as failed and sent later with `transferUserInfo`.

**App lifecycle rule:** users leave the app in the background on both devices. Force-quitting is out of scope.

### WatchConnectivity channels

| Direction | Channel | Used for |
|---|---|---|
| Phone → Watch | `updateApplicationContext` | Preferences and the session config |
| Phone → Watch | `sendMessage` | "Start session now" |
| Watch → Phone | `sendMessage` | Real-time "sleep detected" trigger |
| Watch → Phone | `transferUserInfo` | Session summary, queued with guaranteed delivery |
| Watch → Phone | `transferFile` | Optional raw sensor dumps, in development builds only |

## Accounts

- **Spotify users:** "Log in with Spotify" (OAuth PKCE). The backend is keyed by the Spotify user ID and owns token refresh, since Spotify rotates refresh tokens.
- **Apple Music users:** only the MusicKit permission. No account, and they never touch the backend.
- No Sign in with Apple, no email, no passwords.

## Data

The iPhone is the only writer. The Watch never writes to CloudKit.

| Data | Storage |
|---|---|
| Sleep sessions (analytics) | SwiftData, synced via CloudKit (survives reinstall) |
| Preferences | SwiftData, synced via CloudKit |
| Backend session token | Keychain |
| Raw heart-rate and motion samples | Local only, short retention, or not stored at all |
| HealthKit sleep stages | Not used in the first release. If added later: **never stored**, read live from HealthKit (guideline 5.1.3) |
| Spotify ID, refresh token, pending timers | Backend |

SwiftData models must follow CloudKit's rules from day one: no `@Attribute(.unique)`, every property has a default or is optional, all relationships are optional.

## iOS stack

- SwiftUI, Swift 6 with strict concurrency. Combine only where it fits naturally (NotificationCenter, debouncing). Delegate APIs are bridged to `AsyncStream`.
- MVVM with `@Observable` view models, Coordinators for navigation.
- Protocol-based services (for example `MusicController` with Apple Music and Spotify implementations). No DI framework.
- A session state machine at the core: `idle → armed → monitoring → sleepDetected → pausing → paused / failed / cancelled`.
- SPM local packages, Swift Testing. Snapshot testing is still to be decided.

## App Store notes

- An in-app "Disconnect Spotify & delete data" option is required (guideline 5.1.1(v)).
- Mention the Sign in with Apple exemption in the review notes (guideline 4.8): the Spotify login is only used to control the user's Spotify playback.

## Open risks

- Spotify developer quota rules may limit a public release.
- Spotify pausing requires Premium.
- Waking the iPhone app from the Watch needs testing on a device.
