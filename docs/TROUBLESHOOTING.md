# Troubleshooting

## Table of Contents

- [Audio Issues](#audio-issues)
- [Display Issues](#display-issues)
- [GPU Issues](#gpu-issues)
- [Ubuntu Issues](#ubuntu-issues)
- [Performance](#performance)

---

## Audio Issues

### No sound / `Default Sink: auto_null`

**Cause:** PulseAudio couldn't load the AAudio sink module.

**Fix:**

```bash
# Restart audio
start-audio

# Check status
pactl info
```

If still `auto_null`, manually load the sink:

```bash
pacmd load-module module-aaudio-sink
pacmd set-default-sink AAudio_sink
```

### Audio works in Termux but not in Ubuntu

**Cause:** Ubuntu can't reach the PulseAudio TCP server.

**Fix:** Ensure these are set inside Ubuntu:

```bash
export PULSE_SERVER=tcp:127.0.0.1:4713
```

Verify:

```bash
pactl info
# Should show: Server String: 127.0.0.1:4713
```

### `Connection refused` from Ubuntu

**Fix:**

1. Make sure `start-audio` is running in Termux (not Ubuntu)
2. Check PulseAudio is listening on TCP:

```bash
# In Termux
pactl info | grep "Server String"
```

### Crackling or choppy audio

**Fix:** Increase PulseAudio buffer:

```bash
# In Termux, before start-audio
export PULSEAUDIO_SCRIPT_ARGS="--exit-idle-time=-1 --load='module-aaudio-sink fragments=2 period_size=1024'"
```

---

## Display Issues

### Black screen in Termux X11 app

**Fix:**

```bash
# Kill old sessions
pkill -9 -f termux-x11
pkill -9 -f virgl_test_server_android

# Restart
start-x11
```

Then reopen the Termux X11 app.

### `Cannot open display :0`

**Fix:** Ensure X11 is running and DISPLAY is set:

```bash
# In Termux
start-x11
ps aux | grep termux-x11

# In Ubuntu
export DISPLAY=:0
```

### Termux X11 app not installed

Download from: https://github.com/termux/termux-x11/releases

Install the `.apk` file. Do NOT install from Play Store.

### Display works but is very small / wrong resolution

In the Termux X11 app settings:

1. Tap the hamburger menu
2. Set resolution (e.g., 1280x720)
3. Restart the session

---

## GPU Issues

### No GPU acceleration / `llvmpipe` renderer

**Check:**

```bash
# In Ubuntu
export DISPLAY=:0
export GALLIUM_DRIVER=virpipe
glxinfo | grep "OpenGL renderer"
```

If shows `llvmpipe` (software), VirGL isn't connected.

**Fix:**

```bash
# In Termux
start-graphics

# Verify VirGL is running
ps aux | grep virgl_test_server_android

# In Ubuntu, recheck
glxinfo | grep "OpenGL renderer"
```

### `libEGL warning` or GL errors

Install mesa drivers in Ubuntu:

```bash
apt install -y mesa-utils mesa-vulkan-drivers
```

### GPU crashes or freezes

Lower graphics settings in XFCE:

1. Settings → Appearance → Style → Choose a lighter theme
2. Disable compositing: Settings → Window Manager Tweaks → Compositor → Uncheck

---

## Ubuntu Issues

### `proot-distro login ubuntu` fails

**Fix:**

```bash
# Reinstall
proot-distro remove ubuntu
proot-distro install ubuntu
```

### `ubuntu` command not found

Ensure the command was created:

```bash
ls -la $PREFIX/bin/ubuntu
```

If missing, recreate it:

```bash
cat > $PREFIX/bin/ubuntu << 'CMD'
#!/usr/bin/env bash
set -e
export TMPDIR=/data/data/com.termux/files/usr/tmp
proot-distro login ubuntu --shared-tmp --no-sysvipc --user ubuntu
CMD
chmod +x $PREFIX/bin/ubuntu
```

### `sudo` not working inside Ubuntu

```bash
# Reconfigure sudoers
proot-distro login ubuntu --shared-tmp --no-sysvipc -- bash -c "
echo 'ubuntu ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
chmod 440 /etc/sudoers.d/ubuntu
"
```

### Slow performance

- Close background apps on Android
- Use a lighter XFCE panel layout
- Disable animations in Settings → Window Manager Tweaks
- Consider using `start-display` instead of `start-x11` (lighter)

---

## Performance

### Recommended Android Settings

- Enable Developer Options
- Set background process limit to 4
- Disable battery optimization for Termux
- Keep Termux in foreground (notification)

### Speed Up Boot

Preload packages in Ubuntu:

```bash
# Inside Ubuntu
apt install -y vim git htop neofetch tree
```

### Reduce Memory Usage

```bash
# Inside Ubuntu, remove unnecessary packages
apt remove -y gnome-screensaver xfce4-terminal
apt autoremove -y
```

---

## Still Stuck?

1. Check the [GitHub Issues](https://github.com/adittaya/termux-ubuntu-gui/issues)
2. Search for your error message
3. Open a new issue with:
   - Android version
   - Device model
   - Termux version (`termux-info`)
   - Full error output
