# AGENTS.md — Project Rules & Reminders

## Repository

**Name:** ubuntu-mobile-desktop
**Owner:** adittaya
**URL:** https://github.com/adittaya/ubuntu-mobile-desktop
**Purpose:** Ubuntu Desktop Environment on Android Mobile — Full XFCE GUI via Termux X11 + proot with GPU (VirGL) and audio (PulseAudio)

---

## NO HALLUCINATION RULES

1. **Never assume a package exists.** Always check with `pkg list-installed` or `apt list --installed` before referencing installed packages.
2. **Never assume a service is running.** Always verify with `ps aux | grep <service>` or `pactl info` before assuming audio/display is active.
3. **Never guess file paths.** Termux uses `$PREFIX/bin/` not `/usr/bin/`. Ubuntu proot uses `/usr/local/bin/`. Verify paths before writing files.
4. **Never assume network connectivity.** Always handle `curl`/`wget` failures with `--fail` or error checking.
5. **Never assume root access.** Termux has no root. Ubuntu proot has no real root. Use `sudo` only inside proot with the ubuntu user.
6. **Always test commands mentally** before including them in scripts. Trace the execution path.
7. **Never use `sudo` in Termux.** Termux does not have sudo. Only use sudo inside Ubuntu proot.
8. **Never assume DISPLAY is set.** Always export it explicitly: `export DISPLAY=:0`

---

## SCRIPT ARCHITECTURE

### Script 1: `setup-subsystems.sh` (Termux)
- Installs: proot-distro, termux-x11-nightly, virglrenderer-android, pulseaudio
- Creates commands: start-audio, start-x11, start-display, start-graphics, start-wayland
- **Run in:** Termux
- **Dependencies:** None

### Script 2: `setup-ubuntu.sh` (Termux)
- Installs: Ubuntu via proot-distro
- Configures: ubuntu user with passwordless sudo
- Creates command: ubuntu
- **Run in:** Termux
- **Dependencies:** Script 1 (needs proot-distro)

### Script 3: `setup-desktop.sh` (Ubuntu)
- Installs: xfce4, xfce4-goodies, dbus-x11, xauth, mesa-utils, alsa-utils
- Creates command: desktop
- **Run in:** Ubuntu (inside proot)
- **Dependencies:** Script 2 (needs Ubuntu installed)

### Script 4: `setup-desktop-prebuilt.sh` (Ubuntu)
- Installs: Everything from Script 3 + additional apps, themes, icons, wallpapers
- Pre-configures: XFCE panel, desktop settings, window manager, appearance
- Creates command: desktop-prebuilt
- **Run in:** Ubuntu (inside proot)
- **Dependencies:** Script 2 (needs Ubuntu installed)

### Script 5: `setup-all.sh` (Termux — All-in-One)
- Combines Scripts 1 + 2 + 3 into a single installer
- Does NOT include Script 4 (prebuilt is optional)
- **Run in:** Termux
- **Dependencies:** None

---

## COMMANDS CREATED

| Command | Created By | Location | Description |
|---------|-----------|----------|-------------|
| `start-audio` | Script 1 | `$PREFIX/bin/` | Start PulseAudio with AAudio sink |
| `start-graphics` | Script 1 | `$PREFIX/bin/` | Start VirGL GPU server |
| `start-x11` | Script 1 | `$PREFIX/bin/` | Start X11 + GPU together |
| `start-display` | Script 1 | `$PREFIX/bin/` | Minimal X11 start (clean restart) |
| `start-wayland` | Script 1 | `$PREFIX/bin/` | Bring Termux X11 to foreground |
| `start-gpu-auto` | Script 1 | `$PREFIX/bin/` | Auto-detect GPU (Adreno/Mali) |
| `start-gpu-turnip` | Script 1 | `$PREFIX/bin/` | Turnip+Zink (Adreno) |
| `start-gpu-angle` | Script 1 | `$PREFIX/bin/` | VirGL+ANGLE (Mali) |
| `gpu` | Script 1 | `$PREFIX/bin/` | Run app with GPU acceleration |
| `monitor-gpu` | Script 1 | `$PREFIX/bin/` | Show GPU info and processes |
| `monitor-thermal` | Script 1 | `$PREFIX/bin/` | Show CPU/GPU temperatures |
| `benchmark-gpu` | Script 1 | `$PREFIX/bin/` | Run GLMark2 benchmark |
| `optimize-desktop` | Script 1 | `$PREFIX/bin/` | Pin desktop to big CPU cores |
| `ubuntu` | Script 2 | `$PREFIX/bin/` | Enter Ubuntu proot shell |
| `desktop` | Script 3 | `/usr/local/bin/` | Launch XFCE desktop |
| `desktop-prebuilt` | Script 4 | `/usr/local/bin/` | Launch pre-configured XFCE desktop |

---

## ENVIRONMENT VARIABLES

| Variable | Value | Set By | Used In |
|----------|-------|--------|---------|
| `DISPLAY` | `:0` | start-x11, desktop | X11 display |
| `PULSE_SERVER` | `tcp:127.0.0.1:4713` | desktop | Audio connection |
| `GALLIUM_DRIVER` | `virpipe` | desktop | GPU renderer |
| `XDG_RUNTIME_DIR` | `$TMPDIR` | start-x11 | X11 runtime dir |
| `TMPDIR` | `/data/data/com.termux/files/usr/tmp` | ubuntu command | Shared tmp |

---

## AUDIO PIPELINE

```
Android Audio Hardware
    ↑ (AAudio API)
PulseAudio (Termux) — module-aaudio-sink
    ↑ (TCP 127.0.0.1:4713)
PulseAudio Client (Ubuntu) — PULSE_SERVER=tcp:127.0.0.1:4713
    ↑
Applications (firefox, mpv, etc.)
```

**Key:** PulseAudio runs in Termux, Ubuntu apps connect via TCP.

---

## GPU PIPELINE

### Adreno (Qualcomm/ Snapdragon)

```
Android GPU (Adreno)
    ↑ (Vulkan)
Turnip Driver (vulkan-loader-android) — Termux
    ↑ (Zink)
Mesa Zink Driver (MESA_LOADER_DRIVER_OVERRIDE=zink) — Ubuntu
    ↑ (OpenGL 4.3)
Applications (firefox, libreoffice, etc.)
```

### Mali (MediaTek/Dimensity)

```
Android GPU (Mali)
    ↑ (Vulkan)
VirGL + ANGLE (virglrenderer-android --angle-vulkan) — Termux
    ↑ (virtio-GPU)
Mesa Gallium Driver (virpipe) — Ubuntu
    ↑ (OpenGL 4.3)
Applications (firefox, libreoffice, etc.)
```

### Unknown GPU (Fallback)

```
Android GPU
    ↑ (EGL)
VirGL Server (virgl_test_server_android) — Termux
    ↑ (virtio-GPU)
Mesa Gallium Driver (virpipe) — Ubuntu
    ↑ (OpenGL 4.3)
Applications (firefox, libreoffice, etc.)
```

---

## GPU DETECTION LOGIC

```bash
# Auto-detect GPU type
GPU_INFO=$(getprop ro.hardware.egl 2>/dev/null || echo "")

if echo "$GPU_INFO" | grep -qi "adreno\|qualcomm\|qcom"; then
    # Adreno: Turnip + Zink (2-3x faster)
    start-gpu-turnip
elif echo "$GPU_INFO" | grep -qi "mali\|arm\|mediatek"; then
    # Mali: VirGL + ANGLE
    start-gpu-angle
else
    # Unknown: VirGL fallback
    virgl_test_server_android
fi
```

---

## DISPLAY PIPELINE

```
Android Display
    ↑ (SurfaceView)
Termux X11 App — displays X11 output
    ↑ (X11 protocol)
Xvnc/X11 Server (termux-x11 :0) — Termux
    ↑
XFCE Desktop (startxfce4) — Ubuntu
```

**Key:** Termux X11 app is the display client. X11 server runs in Termux. Desktop runs in Ubuntu.

---

## TESTING RULES

1. **Always test bash syntax** before committing: `bash -n script.sh`
2. **Always test shellcheck** if available: `shellcheck -S warning script.sh`
3. **Never test on real device in CI.** Use mock tests for audio/GPU/X11.
4. **Always verify file permissions:** scripts must be `chmod +x`
5. **Always verify shebang:** must be `#!/usr/bin/env bash`
6. **Always verify README** references all scripts

---

## COMMON MISTAKES TO AVOID

1. Using `sudo` in Termux (no sudo in Termux)
2. Forgetting to export DISPLAY=:0 in Ubuntu
3. PulseAudio not started before launching desktop
4. VirGL server not started before launching desktop
5. Wrong TMPDIR path (must be `/data/data/com.termux/files/usr/tmp`)
6. Using `apt` instead of `pkg` in Termux
7. Using `pkg` instead of `apt` in Ubuntu
8. Not using `--shared-tmp` with proot-distro login
9. Not using `--no-sysvipc` with proot-distro login
10. Forgetting to set `GALLIUM_DRIVER=virpipe` in Ubuntu

---

## RELEASE CHECKLIST

Before pushing to GitHub:

- [ ] All scripts have `bash -n` syntax check pass
- [ ] All scripts have `#!/usr/bin/env bash` shebang
- [ ] All scripts are `chmod +x`
- [ ] README references all scripts
- [ ] README has correct repo URL (adittaya/ubuntu-mobile-desktop)
- [ ] All scripts use correct colors (`\e[1;32m` not `e[1;32m`)
- [ ] No secrets or tokens in any file
- [ ] AGENTS.md is up to date
- [ ] GitHub Actions workflow tests pass
