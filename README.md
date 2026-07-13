<p align="center">
  <img src="https://img.shields.io/badge/Android-Termux-green?style=for-the-badge" alt="Termux">
  <img src="https://img.shields.io/badge/OS-Ubuntu%2022.04-orange?style=for-the-badge" alt="Ubuntu">
  <img src="https://img.shields.io/badge/Desktop-XFCE-blue?style=for-the-badge" alt="XFCE">
  <img src="https://img.shields.io/badge/GPU-VirGL-accent?style=for-the-badge" alt="VirGL">
  <img src="https://img.shields.io/badge/Audio-PulseAudio-purple?style=for-the-badge" alt="PulseAudio">
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

- **3-step modular setup** — install only what you need
- **GPU acceleration** — VirGL provides OpenGL 4.3 compatibility
- **Audio support** — PulseAudio with AAudio sink for Android audio
- **XFCE desktop** — lightweight, customizable, full-featured
- **Persistent install** — survives Termux restarts
- **No root required** — runs entirely in proot
- **Convenience commands** — `start-audio`, `start-x11`, `ubuntu`, `desktop`

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

## Quick Start (One-Liners)

### Script 1: Install Subsystems (Termux)

```bash
curl -sL https://raw.githubusercontent.com/adittaya/ubuntu-mobile-desktop/main/setup-subsystems.sh | bash
```

### Script 2: Install Ubuntu (Termux)

```bash
curl -sL https://raw.githubusercontent.com/adittaya/ubuntu-mobile-desktop/main/setup-ubuntu.sh | bash
```

### Script 3: Install Desktop (Inside Ubuntu)

```bash
curl -sL https://raw.githubusercontent.com/adittaya/ubuntu-mobile-desktop/main/setup-desktop.sh | bash
```

---

## Full Workflow

```
┌──────────────────────────────────────────────────────┐
│                   TERMUX SHELL                       │
│                                                      │
│  Step 1 — Install subsystems                         │
│  $ bash setup-subsystems.sh                          │
│    → Installs: pulseaudio, virgl, termux-x11         │
│    → Creates: start-audio, start-x11, etc.           │
│                                                      │
│  Step 2 — Install Ubuntu                             │
│  $ bash setup-ubuntu.sh                              │
│    → Installs: Ubuntu proot                          │
│    → Creates: ubuntu login command                   │
│                                                      │
│  Step 3 — Start services                             │
│  $ start-audio                                       │
│  $ start-x11                                         │
│  → Open Termux X11 app                               │
│                                                      │
│  Step 4 — Enter Ubuntu                               │
│  $ ubuntu                                            │
│  ┌──────────────────────────────────────────────┐    │
│  │              UBUNTU SHELL                    │    │
│  │                                              │    │
│  Step 5 — Install desktop (first time only)      │    │
│  $ bash setup-desktop.sh                         │    │
│    → Installs: XFCE, dbus, mesa                   │    │
│    → Creates: desktop launcher command            │    │
│                                              │    │
│  Step 6 — Launch desktop                         │    │
│  $ desktop                                       │    │
│  ┌──────────────────────────────────────────┐   │    │
│  │          XFCE DESKTOP                    │   │    │
│  │          (in Termux X11)                 │   │    │
│  └──────────────────────────────────────────┘   │    │
│  └──────────────────────────────────────────┘    │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

---

## One-Liner Install (All 3 Scripts)

```bash
# Clone and run all scripts in order
git clone https://github.com/adittaya/ubuntu-mobile-desktop.git && \
cd ubuntu-mobile-desktop && \
bash setup-subsystems.sh && \
bash setup-ubuntu.sh && \
start-audio && start-x11 && \
ubuntu -c "bash setup-desktop.sh && desktop"
```

---

## Commands Reference

| Command | Location | Created By | Description |
|---------|----------|------------|-------------|
| `start-audio` | Termux | Script 1 | Start PulseAudio with AAudio sink |
| `start-x11` | Termux | Script 1 | Start X11 server + VirGL GPU |
| `start-display` | Termux | Script 1 | Minimal X11 start (clean restart) |
| `start-graphics` | Termux | Script 1 | Start only VirGL GPU server |
| `start-wayland` | Termux | Script 1 | Bring Termux X11 app to foreground |
| `ubuntu` | Termux | Script 2 | Enter Ubuntu proot as user `ubuntu` |
| `desktop` | Ubuntu | Script 3 | Launch XFCE desktop session |

---

## What Gets Installed

### Script 1 — Termux Packages
- `proot-distro` — proot container manager
- `termux-x11-nightly` — X11 display server
- `virglrenderer-android` — VirGL GPU acceleration
- `pulseaudio` — audio server

### Script 2 — Ubuntu System
- Ubuntu 22.04 base system
- `sudo` — privilege management
- User `ubuntu` with passwordless sudo

### Script 3 — Ubuntu Desktop Packages
- `xfce4` + `xfce4-goodies` — desktop environment
- `dbus-x11` + `xauth` — display session support
- `mesa-utils` — OpenGL utilities
- `alsa-utils` — audio utilities

---

## Environment Variables

These are set automatically by the `desktop` command:

| Variable | Value | Purpose |
|----------|-------|---------|
| `DISPLAY` | `:0` | X11 display number |
| `PULSE_SERVER` | `tcp:127.0.0.1:4713` | PulseAudio TCP connection |
| `GALLIUM_DRIVER` | `virpipe` | VirGL OpenGL driver |

---

## Project Structure

```
ubuntu-mobile-desktop/
├── README.md                # This file
├── LICENSE                  # MIT License
├── CONTRIBUTING.md          # Contribution guidelines
├── setup-subsystems.sh      # Script 1: Termux packages & commands
├── setup-ubuntu.sh          # Script 2: Ubuntu install & login
├── setup-desktop.sh         # Script 3: XFCE desktop & launcher
├── .gitignore
└── docs/
    └── TROUBLESHOOTING.md   # Common issues & fixes
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

---

<p align="center">
  <b>Star this repo if it helped you!</b><br>
  <sub>Made for the Android Linux community</sub>
</p>
