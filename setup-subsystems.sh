#!/usr/bin/env bash
# =============================================================================
# SCRIPT 1: SUBSYSTEMS & DEPENDENCIES
# =============================================================================
# Installs all Termux packages and creates global convenience commands:
#   start-audio, start-x11, start-display, start-graphics, start-wayland
#   start-gpu-auto, start-gpu-turnip, start-gpu-angle, gpu
#   monitor-gpu, monitor-thermal, benchmark-gpu, optimize-desktop
#
# Usage:  bash setup-subsystems.sh
# =============================================================================
set -euo pipefail

RED='\e[1;31m'; GRN='\e[1;32m'; YEL='\e[1;33m'; BLU='\e[1;34m'; NC='\e[0m'
info()  { echo -e "${BLU}[*]${NC} $*"; }
ok()    { echo -e "${GRN}[+]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*" >&2; }
hr()    { echo -e "${BLU}==================================================${NC}"; }

if [ -z "${PREFIX:-}" ]; then
    err "This script must run inside Termux (PREFIX is unset)."
    exit 1
fi

hr
echo -e "${GRN}      SCRIPT 1: SUBSYSTEMS & DEPENDENCIES         ${NC}"
hr

# ============================= PACKAGES ====================================
info "Installing Termux dependencies..."
pkg update -y
pkg install -y x11-repo
pkg install -y \
    proot-distro \
    termux-x11-nightly \
    virglrenderer-android \
    virglrenderer \
    pulseaudio \
    wget curl coreutils \
    glmark2 2>/dev/null || true

# GPU packages (best effort — some may not be available)
info "Installing GPU acceleration packages..."
pkg install -y mesa-zink vulkan-loader-android 2>/dev/null || true
pkg install -y mesa-vulkan-icd-freedreno-dri3 2>/dev/null || true
pkg install -y mesa-vulkan-icd-freedreno 2>/dev/null || true
pkg install -y angle-android 2>/dev/null || true
pkg install -y vulkan-loader-generic 2>/dev/null || true

# ============================= COMMANDS ====================================
info "Creating global commands..."

# --- start-audio -----------------------------------------------------------
cat > "$PREFIX/bin/start-audio" << 'CMD'
#!/usr/bin/env bash
set -e

pkill -9 -f pulseaudio 2>/dev/null || true
sleep 0.5

pulseaudio --start --exit-idle-time=-1 \
    --disable-shm=yes >/dev/null 2>&1

pacmd load-module module-native-protocol-tcp \
    auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1

pacmd load-module module-aaudio-sink >/dev/null 2>&1
pacmd set-default-sink AAudio_sink >/dev/null 2>&1

echo "[+] PulseAudio started — sink: AAudio_sink"
echo "[+] In Ubuntu use: export PULSE_SERVER=tcp:127.0.0.1:4713"
CMD
chmod +x "$PREFIX/bin/start-audio"

# --- start-graphics --------------------------------------------------------
cat > "$PREFIX/bin/start-graphics" << 'CMD'
#!/usr/bin/env bash
set -e

pkill -9 -f virgl_test_server_android 2>/dev/null || true
sleep 0.2

virgl_test_server_android >/dev/null 2>&1 &

echo "[+] VirGL GPU server started."
CMD
chmod +x "$PREFIX/bin/start-graphics"

# --- start-x11 -------------------------------------------------------------
cat > "$PREFIX/bin/start-x11" << 'CMD'
#!/usr/bin/env bash
set -e

export DISPLAY=:0
export XDG_RUNTIME_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

echo "[*] Starting VirGL server..."
virgl_test_server_android &

echo "[*] Starting Termux X11 server..."
termux-x11 :0 -ac &

echo "[+] X11 + GPU acceleration started."
echo "[*] Open the Termux X11 app to see the desktop."
CMD
chmod +x "$PREFIX/bin/start-x11"

# --- start-display ---------------------------------------------------------
cat > "$PREFIX/bin/start-display" << 'CMD'
#!/usr/bin/env bash
set -e

export TMPDIR=/data/data/com.termux/files/usr/tmp
export XDG_RUNTIME_DIR="${TMPDIR}"

rm -f "$TMPDIR/.X0-lock" "$TMPDIR/.X11-unix/X0" 2>/dev/null

pkill -9 -f termux-x11 2>/dev/null || true
sleep 0.2

virgl_test_server_android >/dev/null 2>&1 &
termux-x11 :0 -ac >/dev/null 2>&1 &

echo "[+] X11 Canvas pipeline initialized."
CMD
chmod +x "$PREFIX/bin/start-display"

# --- start-wayland ---------------------------------------------------------
cat > "$PREFIX/bin/start-wayland" << 'CMD'
#!/usr/bin/env bash
set -e

echo "[*] Bringing Termux X11 to foreground..."
am start --user 0 \
    -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true

echo "[+] Termux X11 window focused."
CMD
chmod +x "$PREFIX/bin/start-wayland"

# --- start-gpu-auto (auto-detect and start) --------------------------------
cat > "$PREFIX/bin/start-gpu-auto" << 'CMD'
#!/usr/bin/env bash
set -e

echo "[*] Auto-detecting GPU..."

GPU_INFO=""
if command -v getprop >/dev/null 2>&1; then
    GPU_INFO=$(getprop ro.hardware.egl 2>/dev/null || echo "")
fi

if echo "$GPU_INFO" | grep -qi "adreno\|qualcomm\|qcom"; then
    echo "[+] Adreno — starting Turnip + Zink"
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export TU_DEBUG=noconform
    virgl_test_server_android &

elif echo "$GPU_INFO" | grep -qi "mali\|arm\|mediatek"; then
    echo "[+] Mali — starting VirGL + ANGLE"
    if [ -x "$HOME/vgl" ]; then
        ~/vgl angle=vulkan &
    else
        virgl_test_server_android --angle-vulkan &
    fi

else
    echo "[!] Unknown GPU — VirGL fallback"
    virgl_test_server_android &
fi

echo "[+] GPU acceleration started."
CMD
chmod +x "$PREFIX/bin/start-gpu-auto"

# --- start-gpu-turnip (Adreno only) ----------------------------------------
cat > "$PREFIX/bin/start-gpu-turnip" << 'CMD'
#!/usr/bin/env bash
set -e
echo "[*] Starting Turnip + Zink (Adreno)..."
pkill -9 -f virgl_test_server_android 2>/dev/null || true
sleep 0.2
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
virgl_test_server_android &
echo "[+] Turnip + Zink started."
CMD
chmod +x "$PREFIX/bin/start-gpu-turnip"

# --- start-gpu-angle (Mali only) -------------------------------------------
cat > "$PREFIX/bin/start-gpu-angle" << 'CMD'
#!/usr/bin/env bash
set -e
echo "[*] Starting VirGL + ANGLE (Mali)..."
pkill -9 -f virgl_test_server_android 2>/dev/null || true
pkill -9 -f vgl 2>/dev/null || true
sleep 0.2
if [ -x "$HOME/vgl" ]; then
    ~/vgl angle=vulkan &
else
    virgl_test_server_android --angle-vulkan &
fi
echo "[+] VirGL + ANGLE started."
CMD
chmod +x "$PREFIX/bin/start-gpu-angle"

# --- gpu command (run app with HW accel) -----------------------------------
cat > "$PREFIX/bin/gpu" << 'CMD'
#!/usr/bin/env bash
set -e
if [ $# -eq 0 ]; then
    echo "Usage: gpu <command> [args...]"
    echo "Run a command with GPU hardware acceleration."
    exit 1
fi
export DISPLAY="${DISPLAY:-:0}"
export GALLIUM_DRIVER=virpipe
export MESA_GL_VERSION_OVERRIDE=4.1COMPAT
export MESA_GLSL_VERSION_OVERRIDE=410
unset LIBGL_ALWAYS_SOFTWARE
exec "$@"
CMD
chmod +x "$PREFIX/bin/gpu"

# --- monitor-gpu -----------------------------------------------------------
cat > "$PREFIX/bin/monitor-gpu" << 'CMD'
#!/usr/bin/env bash
set -e
echo "=== GPU Information ==="
if command -v getprop >/dev/null 2>&1; then
    echo "EGL:     $(getprop ro.hardware.egl 2>/dev/null || echo N/A)"
    echo "Vulkan:  $(getprop ro.hardware.vulkan 2>/dev/null || echo N/A)"
fi
[ -f /sys/class/kgsl/kgsl-3d0/temp ] && echo "GPU Temp: $(cat /sys/class/kgsl/kgsl-3d0/temp)°C"
[ -f /sys/class/kgsl/kgsl-3d0/devfreq/cur_freq ] && echo "GPU Freq: $(( $(cat /sys/class/kgsl/kgsl-3d0/devfreq/cur_freq) / 1000000 )) MHz"
echo ""
echo "=== Memory ==="
free -h 2>/dev/null || cat /proc/meminfo | head -5
echo ""
echo "=== GPU Processes ==="
ps -eo pid,cmd 2>/dev/null | grep -i "virgl\|vgl\|angle\|zink" | grep -v grep || echo "  None"
CMD
chmod +x "$PREFIX/bin/monitor-gpu"

# --- benchmark-gpu ---------------------------------------------------------
cat > "$PREFIX/bin/benchmark-gpu" << 'CMD'
#!/usr/bin/env bash
set -e
echo "=== GPU Benchmark ==="
if command -v glmark2 >/dev/null 2>&1; then
    export DISPLAY="${DISPLAY:-:0}"
    export GALLIUM_DRIVER=virpipe
    export MESA_GL_VERSION_OVERRIDE=4.1COMPAT
    unset LIBGL_ALWAYS_SOFTWARE
    glmark2 2>/dev/null || echo "[!] GLMark2 failed"
else
    echo "[!] glmark2 not installed — pkg install glmark2"
fi
CMD
chmod +x "$PREFIX/bin/benchmark-gpu"

# --- optimize-desktop (pin to big cores) -----------------------------------
cat > "$PREFIX/bin/optimize-desktop" << 'CMD'
#!/usr/bin/env bash
set -e
echo "[*] Optimizing desktop placement..."
XFCE_PID=$(pgrep -f "xfce4-session" 2>/dev/null | head -1 || echo "")
VIRGL_PID=$(pgrep -f "virgl\|vgl" 2>/dev/null | head -1 || echo "")
[ -n "$XFCE_PID" ] && taskset -pc 4-7 "$XFCE_PID" 2>/dev/null && echo "  [OK] XFCE → big cores"
[ -n "$VIRGL_PID" ] && taskset -pc 4-7 "$VIRGL_PID" 2>/dev/null && echo "  [OK] GPU → big cores"
echo "[+] Done."
CMD
chmod +x "$PREFIX/bin/optimize-desktop"

# --- monitor-thermal -------------------------------------------------------
cat > "$PREFIX/bin/monitor-thermal" << 'CMD'
#!/usr/bin/env bash
set -e
echo "=== Thermal Status ==="
for zone in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$zone" ] || continue
    TEMP=$(cat "$zone" 2>/dev/null || echo N/A)
    [ "$TEMP" -gt 1000 ] 2>/dev/null && TEMP="$((TEMP / 1000))°C" || TEMP="${TEMP}°C"
    echo "  $(basename "$(dirname "$zone")"): $TEMP"
done 2>/dev/null
[ -f /sys/class/kgsl/kgsl-3d0/temp ] && echo "  GPU: $(cat /sys/class/kgsl/kgsl-3d0/temp)°C"
CMD
chmod +x "$PREFIX/bin/monitor-thermal"

# ============================= DONE ========================================
hr
ok "Script 1 Completed. Subsystems ready."
echo ""
echo "  Audio commands:"
echo "    start-audio      — Start PulseAudio server"
echo ""
echo "  Display commands:"
echo "    start-x11        — Start X11 + GPU together"
echo "    start-display    — Minimal X11 start"
echo "    start-wayland    — Bring Termux X11 to foreground"
echo ""
echo "  GPU commands:"
echo "    start-gpu-auto   — Auto-detect GPU (Adreno/Mali)"
echo "    start-gpu-turnip — Turnip+Zink (Adreno)"
echo "    start-gpu-angle  — VirGL+ANGLE (Mali)"
echo "    gpu <app>        — Run app with GPU"
echo ""
echo "  Monitoring:"
echo "    monitor-gpu      — GPU info and processes"
echo "    monitor-thermal  — CPU/GPU temperatures"
echo "    benchmark-gpu    — Run GLMark2"
echo "    optimize-desktop — Pin desktop to big cores"
echo ""
echo "  Next: bash setup-ubuntu.sh"
hr
