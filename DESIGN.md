# Melo — Design System & Aesthetics

> **Design Direction**: Accent: Teal. Clean and modern like Spotify, but distinctly unique with physical-crate folder tiles, wave seek bars, floating glass capsules, and ambient glows.

---

## 1. Design Tokens

### Color Palette

| Token | Hex Value | Usage |
|---|---|---|
| `bgBase` | `#081012` | Deep ink-teal black backdrop |
| `surface1` | `#0E1A1D` | Card backgrounds, sidebar, and base surfaces |
| `surface2` | `#142529` | Hover states, elevated chips, and inputs |
| `surface3` | `#1B3237` | Active borders and dialog headers |
| `primaryTeal` | `#14B8A6` | Brand accent, active play buttons, highlights |
| `tealLight` | `#5EEAD4` | Wave progress fills, indicators, hover accents |
| `tealDeep` | `#0F766E` | Secondary gradients and shadows |
| `textPrimary` | `#EAF6F5` | High-contrast headings and active titles |
| `textSecondary` | `#8FA9AB` | Artists, subheadings, and secondary labels |
| `textMuted` | `#5B7476` | Timestamps, durations, column headers |
| `borderLight` | `0x14FFFFFF` | Subtle 1px borders at ~8% opacity |

### Light Theme Tokens
- Soft off-white base (`#F3F7F7`)
- Clean slate surfaces (`#E5EDED`, `#D6E2E2`)
- Deep Teal accent (`#0F766E`)
- High contrast dark text (`#0A1719`, `#436063`)

---

## 2. Signature UI Elements

### 1. Wave Progress Bar (`WaveProgressBar`)
- Built using an interactive Flutter `CustomPainter`.
- Renders 48+ normalized waveform peaks that fill with a vibrant two-stop gradient (`#5EEAD4` → `#14B8A6`) as audio plays.
- Supports smooth drag scrubbing and instantaneous seeking.

### 2. Ambient Glow (`AmbientGlow`)
- Uses dual radial gradient orbs (`opacity: 0.22 - 0.28`) anchored behind the Now Playing panel and view headers.
- Blends the track's dominant hue toward deep teal (`#14B8A6`) so the app maintains brand cohesion regardless of artwork color.

### 3. Folder Tiles as "Crates" (`FolderCrateTile`)
- Multi-layered stacked-sleeves illustration:
  - 3 offset rounded sleeves (tilted at -0.12 rad, +0.10 rad, and 0 rad) displaying disc groove rings and folder icons.
  - Generates cohesive harmonic sleeve color sets per folder based on path hashes.
  - Displays folder name, track count, total duration, and hover play shortcut.

### 4. Floating Glass Player Bar (`FloatingPlayerBar`)
- A floating capsule with 16px margins, detached from window edges.
- Backdrop blur (`ImageFilter.blur(sigmaX: 24, sigmaY: 24)`), 24px border radius, and a subtle 1px border (`0x14FFFFFF`).
- Integrated track art, title, like button, transport controls, waveform progress bar, elapsed/remaining time, and volume slider.

### 5. Melo Wordmark (`MeloLogo`)
- Custom inline vector logo rendering a teal circular glyph containing a 4-bar sound-wave graphic alongside lowercase `melo.` typography.
- 100% vector-rendered without external image dependencies.

### 6. Live Reactive Visualizer (`LiveVisualizer`)
- 16 to 20 animated frequency bars driven by harmonic sine and cosine wave equations.
- Automatically synchronizes with audio engine playing/paused state.

---

## 3. Responsive Layout Guidelines

- **Desktop (>= 900px)**:
  - Collapsible left sidebar (navigation, collection, playlists, settings).
  - Main scrollable content view with top search bar.
  - Toggleable right Now Playing sidebar with visualizer, queue, and lyrics.
  - Floating bottom player capsule with full controls and volume slider.
- **Mobile (< 900px)**:
  - Bottom navigation bar.
  - Bottom-anchored floating player bar.
  - Full-screen modal bottom sheet for Now Playing, visualizer, and queue.
