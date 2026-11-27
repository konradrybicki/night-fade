# Features

Scope of the first release. Technical background lives in [architecture.md](architecture.md).

## Core features

### 1. Music service connection
- **Spotify:** "Log in with Spotify" (OAuth PKCE, tokens owned by the backend).
  - **Premium check**, with a clear message if the user doesn't have it. Pausing and playback control require Premium.
  - Disconnecting the account deletes the backend data (see 6).
- **Apple Music:** "Connect Apple Music" (the MusicKit permission; no account, no logout).
  - If access is denied, a hint pointing to iOS Settings.

### 2. Onboarding
- Choosing the music service (see 1).
- **Mode selection:** AirPods / Apple Watch / Timer, each with a short explanation.
  - **AirPods:** lists the AirPods models that support sleep detection, then waits for AirPods to connect (detected from the audio route). The model can't be read reliably, so the app doesn't guess it.
  - **Apple Watch:** checks that a Watch is paired and that the NightFade Watch app is installed (WatchConnectivity), and continues on its own once both are true.
- **Permissions**, asked only when needed: MusicKit, HealthKit heart rate (Watch mode only).
- The analytics opt-out shown or explained (see 6).

### 3. Music player
- **Apple Music:** playback through our own `ApplicationMusicPlayer` (required for the timer). Play/pause, skip, artwork, title.
- **Spotify:** controls through the backend (Web API). Shows what's playing, play/pause, skip.
- **Tapping the player** opens the source app (`spotify:` / `music://`).
- Empty state: nothing playing.

### 4. Mode screen (main screen)
- Shows the current mode, and lets the user change it.
- **AirPods:** an information screen with step-by-step instructions to turn on *Pause media when falling asleep*.
- **Apple Watch:** instructions for the Watch app, a **"Start session"** button and a live status (monitoring / paused at 23:41 / iPhone unreachable).
- **Timer:** pick a duration, start/cancel, countdown.
- All modes share one **session state**: idle → armed → monitoring → sleep detected → pausing → paused / failed / cancelled.

### 5. Analytics (charts)
- **The main chart:** a timeline of the night with when the music started, when the user fell asleep and when the music paused. Only moments NightFade records itself, no HealthKit sleep stages.
- **Stats:** time listened before falling asleep, fall-asleep time, pause time, delay between sleep and pause, and 7-night averages.
- A **session history** list, each session with its details.
- **AirPods mode:** a locked state ("Available in Watch or Timer mode"), because iOS gives apps no signal when AirPods pause playback.
- Sessions stored in SwiftData, synced through iCloud later (needs the paid developer account).

### 6. Profile and settings
- The connected service and account status.
- Settings: default timer length, detection sensitivity (Watch).
- **Analytics opt-out** toggle.
- **"Disconnect Spotify & delete data"** (required by App Review guideline 5.1.1(v)).
- Links to the privacy policy and app info (version).

### 7. Live Activity
- On the lock screen and in the Dynamic Island during an active session.
- **Timer:** the countdown. **Watch:** "Monitoring…", and then "Paused at 23:41".
- Ends automatically when playback is paused or the session is cancelled.

### 8. Apple Watch app
- Start/stop a session, a status display.
- **Sleep detection:** heart rate and motion during an `HKWorkoutSession`.
- Sends "sleep detected" to the iPhone; retries when the iPhone is unreachable, and records the session as failed if it still can't reach it.
- Receives settings from the iPhone.

### 9. Backend (Spotify only)
- Token exchange and refresh after the PKCE login.
- `POST /pause` (used by the Watch flow through the iPhone and by the player).
- **Scheduled pause** for Spotify timers (a cloud scheduler).
- Account deletion.
- Python; framework and hosting decided at setup.

## Across all features
- **Languages:** English (base) and Polish. String Catalogs from the first screen; locale-aware date, time and duration formatting.
- **Crash reporting:** Sentry (PII off, EU region, dSYM upload).
- **Product analytics:** TelemetryDeck with a fixed list of allowed events. **No health values or sleep times.**
- Both behind protocols, with no-op implementations for Debug builds, tests, previews and CI. Their keys stay in `Local.xcconfig`, out of the public repo.
- **Privacy:** a privacy policy page, and the App Store label "Crash Data" and "Product Interaction" (not linked to identity).
  - To do before release: write the policy in the repo (English and Polish, e.g. `docs/privacy-policy.md`) and publish it with GitHub Pages. The app links to that URL from Account and onboarding, opening it in an in-app Safari sheet. It should cover on-device data, the Spotify backend data and how to delete it, HealthKit heart rate, third parties (Spotify, TelemetryDeck, Sentry, backend host), retention, GDPR rights and a contact email. Get it reviewed before publishing.
- **Error states** in each feature: no Premium, permission denied, nothing playing, iPhone unreachable, no network.
- **Design:** dark mode first, Dynamic Type, VoiceOver labels, layouts that handle longer text.

## Later (not in the first release)
- iCloud sync of sessions (needs the paid developer account).
- Fade-out before pausing (Apple Music only).
- More languages, based on demand.
- Sleep stages from HealthKit drawn under the night's timeline (read live, never stored).
