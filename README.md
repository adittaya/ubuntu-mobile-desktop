<p align="center">
  <img src="https://img.shields.io/badge/Android-Termux-green?style=for-the-badge" alt="Termux">
  <img src="https://img.shields.io/badge/OS-Ubuntu%2022.04-orange?style=for-the-badge" alt="Ubuntu">
  <img src="https://img.shields.io/badge/Desktop-XFCE-blue?style=for-the-badge" alt="XFCE">
  <img src="https://img.shields.io/badge/GPU-VirGL-accent?style=for-the-badge" alt="VirGL">
  <img src="https://img.shields.io/badge/Audio-PulseAudio-purple?style=for-the-badge" alt="PulseAudio">
  <img src="https://img.shields.io/badge/Scripts-5-brightgreen?style=for-the-badge" alt="Scripts">
  <img src="https://img.shields.io/github/license/adittaya/ubuntu-mobile-desktop?style=for-the-badge" alt="License">
</p>

<h1 align="center">Ubuntu Desktop Environment on Mobile<br>Full XFCE GUI on Android via Termux</h1>

<p align="center">
  <b>Run a full Ubuntu desktop environment on your Android phone or tablet</b><br>
  with XFCE, GPU acceleration (VirGL), audio (PulseAudio), and proot — no root required.
</p>

---

## What This Does

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Display** | Termux X11 | Native X11 display server for Android |
| **GPU** | VirGL (virpipe) | OpenGL hardware acceleration via virtio-GPU |
| **Audio** | PulseAudio + AAudio | System audio routed to Android speakers |
| **Desktop** | XFCE4 | Lightweight, full-featured desktop environment |
| **System** | Ubuntu 22.04 (proot) | Full Linux userspace with apt packages |

---

## Features

- **Fast install** — pre-built Ubuntu+XFCE tarball from GitHub Releases (~5 min)
- **All-in-one installer** — single script sets up everything
- **Modular scripts** — install only what you need, step by step
- **Pre-built desktop** — ready-to-use XFCE with apps, themes, icons
- **GPU acceleration** — VirGL provides OpenGL 4.3 compatibility
- **Audio support** — PulseAudio with AAudio sink for Android audio
- **No root required** — runs entirely in proot
- **8 convenience commands** — `start-audio`, `start-x11`, `ubuntu`, `desktop`, etc.
- **GitHub Actions CI** — automated testing + release builds

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **OS** | Android 7.0+ (API 24+) |
| **Termux** | F-Droid or GitHub release (NOT Play Store) |
| **Termux:X11** | [GitHub Releases](https://github.com/termux/termux-x11/releases) |
| **Storage** | ~3 GB free space |
| **Network** | Required for initial install |

> **Important:** Install Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/) or the [GitHub releases page](https://github.com/termux/termux-x11/releases). The Play Store version is outdated and may not work.

---

## Quick Start

### Option A: Fast Install (Pre-Built Tarball) — Recommended

```bash
# Clone and run (auto-downloads pre-built Ubuntu+XFCE)
git clone https://github.com/adittaya/ubuntu-mobile-desktop.git
cd ubuntu-mobile-desktop
bash setup-all.sh --fast
```

This downloads a pre-built Ubuntu ARM64 rootfs with XFCE, Firefox, VLC, themes, and icons already installed. **~5 minutes vs ~20 minutes.**

### Option B: All-in-One (Fresh Install)

```bash
bash setup-all.sh --full
```

Builds everything from scratch. Slower but doesn't need network for packages.

### Option C: Step-by-Step (Modular)

```bash
# Step 1: Install subsystems (Termux)
bash setup-subsystems.sh

# Step 2: Install Ubuntu (Termux)
bash setup-ubuntu.sh

# Step 3: Start services (Termux)
start-audio
start-x11
# Open Termux X11 app

# Step 4: Enter Ubuntu
ubuntu

# Step 5: Install desktop (Ubuntu) — choose one:
bash setup-desktop.sh          # Minimal XFCE
bash setup-desktop-prebuilt.sh # Full XFCE with apps & themes

# Step 6: Launch
desktop              # or: desktop-prebuilt
```

### Option C: One-Liner Install

```bash
# All-in-one via curl
curl -sL https://raw.githubusercontent.com/adittaya/ubuntu-mobile-desktop/main/setup-all.sh | bash
```

---

## Scripts Overview

| Script | Run In | Description |
|--------|--------|-------------|
| `setup-all.sh` | Termux | **All-in-one** — does everything in one shot |
| `setup-subsystems.sh` | Termux | Installs packages & creates Termux commands |
| `setup-ubuntu.sh` | Termux | Installs Ubuntu & creates login command |
| `setup-desktop.sh` | Ubuntu | **Minimal** XFCE desktop install |
| `setup-desktop-prebuilt.sh` | Ubuntu | **Full** XFCE with apps, themes, icons, shortcuts |

---

## Full Workflow

```
┌──────────────────────────────────────────────────────────┐
│                     TERMUX SHELL                         │
│                                                          │
│  $ bash setup-all.sh          ← OR →                     │
│  $ bash setup-subsystems.sh                              │
│  $ bash setup-ubuntu.sh                                  │
│                                                          │
│  $ start-audio                                           │
│  $ start-x11                                             │
│  ┌────────────────────────────────────────────┐          │
│  │         Open Termux X11 App                │          │
│  └────────────────────────────────────────────┘          │
│                                                          │
│  $ ubuntu                                                │
│  ┌────────────────────────────────────────────┐          │
│  │            UBUNTU SHELL                    │          │
│  │                                            │          │
│  │  $ bash setup-desktop.sh                  │          │
│  │       OR                                  │          │
│  │  $ bash setup-desktop-prebuilt.sh         │          │
│  │                                            │          │
│  │  $ desktop (or desktop-prebuilt)           │          │
│  │  ┌──────────────────────────────────┐     │          │
│  │  │       XFCE DESKTOP               │     │          │
│  │  │       (in Termux X11)            │     │          │
│  │  └──────────────────────────────────┘     │          │
│  └────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────┘
```

---

## Commands Reference

| Command | Created By | Location | Description |
|---------|-----------|----------|-------------|
| `start-audio` | Script 1 | Termux `$PREFIX/bin/` | Start PulseAudio with AAudio sink |
| `start-x11` | Script 1 | Termux `$PREFIX/bin/` | Start X11 server + VirGL GPU |
| `start-display` | Script 1 | Termux `$PREFIX/bin/` | Minimal X11 start (clean restart) |
| `start-graphics` | Script 1 | Termux `$PREFIX/bin/` | Start only VirGL GPU server |
| `start-wayland` | Script 1 | Termux `$PREFIX/bin/` | Bring Termux X11 app to foreground |
| `ubuntu` | Script 2 | Termux `$PREFIX/bin/` | Enter Ubuntu proot as user `ubuntu` |
| `desktop` | Script 3/4 | Ubuntu `/usr/local/bin/` | Launch XFCE desktop session |
| `desktop-prebuilt` | Script 4 | Ubuntu `/usr/local/bin/` | Launch pre-configured XFCE desktop |

---

## Pre-Built Desktop Features

Script 4 (`setup-desktop-prebuilt.sh`) installs a complete desktop with:

### Applications
- **Firefox** — Web browser
- **VLC** — Media player
- **Thunar** — File manager
- **Mousepad / Pluma** — Text editors
- **xterm / LXTerminal** — Terminal emulators
- **Ristretto** — Image viewer
- **Parole** — Video player
- **Neofetch** — System info

### Themes & Icons
- **Arc-Dark** — GTK theme
- **Papirus-Dark** — Icon theme
- **Noto Sans** — Font family

### Pre-Configured Shortcuts
| Shortcut | Action |
|----------|--------|
| `Super+T` | Open Terminal |
| `Super+E` | Open File Manager |
| `Super+L` | Lock Screen |
| `Ctrl+Alt+T` | Open Terminal |
| `Ctrl+Alt+Delete` | Logout Menu |
| `Print` | Screenshot |

### Panel Layout
- Bottom panel with whisker menu, taskbar, clock, system tray, audio controls

---

## What Gets Installed

### Termux Packages (Script 1)
- `proot-distro` — proot container manager
- `termux-x11-nightly` — X11 display server
- `virglrenderer-android` — VirGL GPU acceleration
- `pulseaudio` — audio server

### Ubuntu System (Script 2)
- Ubuntu 22.04 base system
- `sudo` — privilege management
- User `ubuntu` with passwordless sudo

### Desktop Packages (Script 3 — Minimal)
- `xfce4` + `xfce4-goodies` — desktop environment
- `dbus-x11` + `xauth` — display session support
- `mesa-utils` — OpenGL utilities
- `alsa-utils` — audio utilities

### Pre-Built Packages (Script 4 — Full)
Everything in Script 3, plus:
- `firefox`, `vlc`, `thunar`, `mousepad`, `pluma`
- `xterm`, `lxterminal`, `ristretto`, `parole`
- `arc-theme`, `papirus-icon-theme`
- `network-manager`, `gnome-screenshot`
- `fonts-noto`, `fonts-liberation`
- `ffmpeg`, `htop`, `neofetch`, `tree`

---

## Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `DISPLAY` | `:0` | X11 display number |
| `PULSE_SERVER` | `tcp:127.0.0.1:4713` | PulseAudio TCP connection |
| `GALLIUM_DRIVER` | `virpipe` | VirGL OpenGL driver |

---

## Project Structure

```
ubuntu-mobile-desktop/
├── README.md                    # This file
├── AGENTS.md                    # Project rules & AI reminders
├── LICENSE                      # MIT License
├── CONTRIBUTING.md              # Contribution guidelines
├── setup-all.sh                 # All-in-one installer (fast/full modes)
├── setup-subsystems.sh          # Script 1: Termux packages & commands
├── setup-ubuntu.sh              # Script 2: Ubuntu install & login
├── setup-desktop.sh             # Script 3: Minimal XFCE desktop
├── setup-desktop-prebuilt.sh    # Script 4: Full XFCE with apps & themes
├── .gitignore
├── .github/
│   └── workflows/
│       ├── test.yml             # CI tests (lint, structure, audio, GPU)
│       └── build-release.yml    # Builds pre-built rootfs tarball
└── docs/
    └── TROUBLESHOOTING.md       # Common issues & fixes
```

---

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for solutions to common issues:

- Audio not working
- Display not showing
- GPU acceleration issues
- Ubuntu login problems
- Performance optimization

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Termux](https://termux.dev) — Android terminal emulator
- [Termux:X11](https://github.com/termux/termux-x11) — X11 display server
- [proot-distro](https://github.com/termux/proot-distro) — proot container management
- [VirGL](https://gitlab.freedesktop.org/virgl/) — Virgil3D GPU emulation
- [XFCE](https://xfce.org) — lightweight desktop environment
- [Arc Theme](https://github.com/horst3180/arc-theme) — GTK theme
- [Papirus Icons](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) — Icon theme

---

<p align="center">
  <b>Star this repo if it helped you!</b><br>
  <sub>Made for the Android Linux community</sub>
</p>
