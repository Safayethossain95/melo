# Melo — Offline Music Player

> **Melo** is a fully **offline**, high-fidelity music player with an instant playback engine, unique teal aesthetics, crate-based folder organization, and zero network calls.

---

## 1. Product Overview

Melo is designed with a singular focus: **Instant, private, and distraction-free listening**.
- **100% Offline**: Zero accounts, zero telemetry, no tracking, and strict sandbox enforcement.
- **Instant Playback**: Sound begins with no perceptible delay (<100ms budget).
- **Supported Formats**: `.mp3`, `.flac`, `.wav`, `.ogg`, `.opus`, `.m4a`, `.aac`, `.wma`, `.aiff`.
- **Target Platforms**: Android, iOS, Web (CanvasKit/HTML), and Windows Desktop.

---

## 2. Architecture

```
melo/
├── assets/
│   └── audio/            # Seeded offline audio tracks (WAV 44.1kHz 16-bit PCM)
├── sample-music/         # Standalone royalty-free / generated sample music folder
├── lib/
│   ├── main.dart         # Entry point, pre-warming, and theme bootstrap
│   ├── app_scaffold.dart # Responsive layout (Sidebar, Top Search, Player, Now Playing)
│   ├── core/
│   │   └── theme/        # Curated Teal design tokens, Dark & Light themes
│   ├── models/           # Track, FolderCrate, Album, Artist, Playlist models
│   ├── services/
│   │   ├── audio_engine.dart       # High-performance dual-deck audio engine
│   │   ├── library_repository.dart # Local caching, folder indexing, sample seeding
│   │   └── latency_probe.dart      # Real-time click-to-sound budget telemetry
│   ├── widgets/          # Signature UI components:
│   │   ├── melo_logo.dart          # Vector sound-wave glyph wordmark
│   │   ├── floating_player_bar.dart# Floating frosted glass capsule
│   │   ├── wave_progress_bar.dart  # Interactive Canvas waveform seek bar
│   │   ├── folder_crate_tile.dart  # Stacked-sleeves crate visualization
│   │   ├── ambient_glow.dart       # Dynamic radial gradient ambient background
│   │   ├── live_visualizer.dart    # 60fps reactive animated frequency bars
│   │   ├── now_playing_panel.dart  # Full desktop side panel / mobile sheet
│   │   ├── track_row.dart          # Fast track item with hover play and equalizer
│   │   └── latency_probe_overlay.dart # In-app debug performance monitor (Ctrl+Shift+L)
│   └── pages/            # Home, Folders, FolderDetail, Songs, Albums, Artists, Playlists, Settings
└── test/
    └── widget_test.dart  # Unit tests for audio engine, latency probe, and models
```

---

## 3. How Instant Playback is Achieved (<100ms)

Playback responsiveness is a hard engineering requirement:
1. **Never Block on I/O or Rendering**: Audio playback initiates from the in-memory track index immediately. Metadata parsing, database writes, and visualizer setup occur asynchronously *after* sound starts.
2. **Optimistic UI (<5ms)**: On any tap or click, the play button, active track row, and player capsule flip immediately.
3. **Pre-Warmed Audio Pipeline**: Audio players are created and warmed at app start.
4. **Dual-Deck Engine (A/B Players)**: While Deck A plays the active track, Deck B asynchronously preloads the next queue item. Track transitions take <30ms (gapless).
5. **Decoupled Position Streams**: The Waveform seek bar is driven by a lightweight `ValueNotifier<Duration>` that repaints only the canvas at 60fps without triggering full page widget rebuilds.
6. **Rapid-Input Safety**: A monotonically increasing request token discards stale requests when skipping rapidly.
7. **Fast Failure Recovery**: Missing or corrupt files trigger a toast and automatically skip to the next track within 100ms.

---

## 4. How Folder Scanning & Crates Work

- **First Launch Onboarding**: Displays an animated teal radar wave scan screen with a live counter of discovered tracks and current directory paths.
- **Crate Representation**: Folders containing music are grouped into "Crates" styled as stacked sleeves illustrations (up to 3 offset colored sleeves with vinyl groove watermarks, track counts, and durations).
- **View Modes**: Switch between Grid view, List view, and a hierarchical expandable Tree view.
- **Importing**:
  - Web: Native browser file selector or drag-and-drop.
  - Mobile & Desktop: Pick audio files or select entire music directories.
- **Offline Persistence**: Libraries and playlists are cached in local storage for instant cold startup under 1 second.

---

## 5. Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Space` | Play / Pause |
| `←` / `→` | Seek -/+ 5 seconds |
| `Shift + ←` / `Shift + →` | Previous / Next track |
| `↑` / `↓` | Volume +/- 5% |
| `M` | Toggle Mute |
| `S` | Toggle Shuffle |
| `R` | Cycle Repeat Mode (Off → All → One) |
| `L` | Like / Favorite current track |
| `Ctrl + K` or `/` | Focus global search bar |
| `Ctrl + ,` | Open Settings |
| `Ctrl + Shift + L` | Toggle Instant Playback Latency Probe |

---

## 6. Getting Started & Running Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/) (3.24+ / 3.47+ recommended)
- Google Chrome or Edge (for Web) or Windows C++ build tools (for Desktop)

### Running on Web
```bash
cd melo
flutter run -d chrome
```

### Running on Windows Desktop
```bash
cd melo
flutter run -d windows
```

### Building for Web (Production)
```bash
flutter build web --release
```

### Running Tests & Static Analysis
```bash
flutter analyze
flutter test
```
