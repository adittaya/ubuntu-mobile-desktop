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

- **One-command setup** — single script handles everything
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

## Quick Start

### 1. Install & Run

```bash
# Clone the repository
git clone https://github.com/adittaya/ubuntu-mobile-desktop.git
cd ubuntu-mobile-desktop

# Run the installer
bash setup-termux-gui.sh
```

Or download and run directly:

```bash
wget https://raw.githubusercontent.com/adittaya/ubuntu-mobile-desktop/main/setup-termux-gui.sh
bash setup-termux-gui.sh
```

### 2. Start Everything

```bash
# Start audio
start-audio

# Start display + GPU
start-x11

# Open the Termux X11 app on your device

# Enter Ubuntu
ubuntu

# Launch the desktop
desktop
```

---

## Commands Reference

After installation, these commands are available in Termux:

| Command | Location | Description |
|---------|----------|-------------|
| `start-audio` | Termux | Start PulseAudio with AAudio sink |
| `start-x11` | Termux | Start X11 server + VirGL GPU |
| `start-display` | Termux | Minimal X11 start (kills old sessions) |
| `start-graphics` | Termux | Start only VirGL GPU server |
| `start-wayland` | Termux | Bring Termux X11 app to foreground |
| `ubuntu` | Termux | Enter Ubuntu proot as user `ubuntu` |
| `desktop` | Ubuntu | Launch XFCE desktop session |

---

## Usage Workflow

```
┌─────────────────────────────────────┐
│            TERMUX SHELL             │
│                                     │
│  $ start-audio                      │
│  $ start-x11                        │
│  ┌─────────────────────────────┐    │
│  │   Open Termux X11 App       │    │
│  └─────────────────────────────┘    │
│  $ ubuntu                           │
│  ┌─────────────────────────────┐    │
│  │      UBUNTU SHELL           │    │
│  │                             │    │
│  │  $ desktop                  │    │
│  │  ┌───────────────────────┐  │    │
│  │  │   XFCE DESKTOP        │  │    │
│  │  │   (in Termux X11)     │  │    │
│  │  └───────────────────────┘  │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

---

## What Gets Installed

### Termux Packages
- `proot-distro` — proot container manager
- `termux-x11-nightly` — X11 display server
- `virglrenderer-android` — VirGL GPU acceleration
- `pulseaudio` — audio server

### Ubuntu Packages
- `xfce4` + `xfce4-goodies` — desktop environment
- `dbus-x11` + `xauth` — display session support
- `mesa-utils` — OpenGL utilities
- `alsa-utils` + `pulseaudio` + `pavucontrol` — audio tools
- `sudo` — privilege management

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
├── README.md              # This file
├── LICENSE                # MIT License
├── CONTRIBUTING.md        # Contribution guidelines
├── setup-termux-gui.sh    # Main installer script
├── .gitignore
└── docs/
    └── TROUBLESHOOTING.md # Common issues & fixes
```

---

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for solutions to common issues including:

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
