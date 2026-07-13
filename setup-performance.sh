#!/usr/bin/env bash
# =============================================================================
# GPU & PERFORMANCE OPTIMIZATION — Auto-Detect & Configure Best Drivers
# =============================================================================
# Auto-detects GPU type (Adreno vs Mali vs Unknown) and installs the best
# available GPU acceleration drivers and performance optimizations.
#
# Adreno (Qualcomm):  Turnip + Zink — 2-3x faster than VirGL
# Mali (MediaTek):    VirGL + ANGLE — only working path without root
# Unknown/Other:      VirGL fallback — basic GPU acceleration
#
# Also creates CPU/memory optimization commands.
#
# Usage:  bash setup-performance.sh
# Docs:   https://github.com/adittaya/ubuntu-mobile-desktop
# =============================================================================
set -euo pipefail

RED='\e[1;31m'; GRN='\e[1;32m'; YEL='\e[1;33m'; BLU='\e[1;34m'; NC='\e[0m'
info()  { echo -e "${BLU}[*]${NC} $*"; }
ok()    { echo -e "${GRN}[+]${NC} $*"; }
warn()  { echo -e "${YEL}[!]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*" >&2; }
hr()    { echo -e "${BLU}==================================================${NC}"; }

if [ -z "${PREFIX:-}" ]; then
    err "This script must run inside Termux (PREFIX is unset)."
    exit 1
fi

hr
echo -e "${GRN}   GPU & Performance Optimization Setup   ${NC}"
hr

# ===========================================================================
# GPU DETECTION
# ===========================================================================
info "Detecting GPU type..."

detect_gpu() {
    local gpu_info=""

    # Method 1: Android system property
    if command -v getprop >/dev/null 2>&1; then
        gpu_info=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    fi

    # Method 2: Try vulkaninfo
    if [ -z "$gpu_info" ] && command -v vulkaninfo >/dev/null 2>&1; then
        gpu_info=$(vulkaninfo 2>/dev/null | grep -i "deviceName\|vendorName" | head -2 || echo "")
    fi

    # Method 3: Check /proc/gpuinfo (some devices)
    if [ -z "$gpu_info" ] && [ -f /proc/gpuinfo ]; then
        gpu_info=$(cat /proc/gpuinfo 2>/dev/null | head -5 || echo "")
    fi

    # Determine GPU type
    if echo "$gpu_info" | grep -qi "adreno"; then
        echo "adreno"
    elif echo "$gpu_info" | grep -qi "mali"; then
        echo "mali"
    elif echo "$gpu_info" | grep -qi "qualcomm\|qcom"; then
        echo "adreno"
    elif echo "$gpu_info" | grep -qi "arm\|mediatek\|dimensity"; then
        echo "mali"
    else
        # Fallback: check for kgsl (Adreno) or mali device nodes
        if [ -e /dev/kgsl-3d0 ] 2>/dev/null; then
            echo "adreno"
        else
            echo "unknown"
        fi
    fi
}

GPU_TYPE=$(detect_gpu)
ok "Detected GPU: ${GRN}${GPU_TYPE}${NC}"

case "$GPU_TYPE" in
    adreno)
        echo -e "  ${GRN}Qualcomm Adreno detected — using Turnip + Zink${NC}"
        echo -e "  ${YEL}Expected: 2-3x faster than VirGL${NC}"
        ;;
    mali)
        echo -e "  ${GRN}ARM Mali (MediaTek) detected — using VirGL + ANGLE${NC}"
        echo -e "  ${YEL}Expected: ~75% of Adreno VirGL performance${NC}"
        ;;
    *)
        echo -e "  ${YEL}Unknown GPU — using VirGL fallback${NC}"
        ;;
esac

# ===========================================================================
# INSTALL GPU PACKAGES
# ===========================================================================
info "Installing GPU packages..."

case "$GPU_TYPE" in
    adreno)
        info "Installing Turnip + Zink for Adreno..."
        pkg install -y \
            mesa-zink \
            vulkan-loader-android \
            mesa-vulkan-icd-freedreno-dri3 \
            virglrenderer-android \
            glmark2 2>/dev/null || true

        # Also try tur-repo packages
        pkg install -y mesa-vulkan-icd-freedreno 2>/dev/null || true

        ok "Adreno GPU packages installed."
        ;;

    mali)
        info "Installing VirGL + ANGLE for Mali..."
        pkg install -y \
            virglrenderer \
            virglrenderer-android \
            vulkan-loader-generic \
            glmark2 2>/dev/null || true

        # Install ANGLE from tur-repo
        pkg install -y angle-android 2>/dev/null || {
            warn "angle-android not available in repos, trying alternative..."
        }

        # Install the vgl launcher
        info "Installing vgl launcher..."
        cd "$HOME"
        rm -f ~/vgl
        if wget --timeout=30 -q https://github.com/ar37-rs/virgl-angle/raw/refs/heads/main/vgl -O ~/vgl 2>/dev/null; then
            chmod +x ~/vgl
            ok "vgl launcher installed."
        else
            warn "Failed to download vgl launcher — will create manual launcher."
            cat > ~/vgl << 'VGL'
#!/usr/bin/env bash
# Manual VirGL + ANGLE launcher
ANGLE_MODE="${1:-vulkan}"
echo "[+] Starting VirGL with ANGLE mode: $ANGLE_MODE"
exec virgl_test_server_android --angle-vulkan
VGL
            chmod +x ~/vgl
        fi

        # Install Mali Vulkan ICD wrapper (critical!)
        info "Installing Mali Vulkan ICD wrapper..."
        pkg install -y vulkan-loader-generic openssl 2>/dev/null || true

        if wget --timeout=30 -q \
            https://github.com/ar37-rs/virgl-angle/releases/download/latest/mesa-vulkan-icd-wrapper_25.0.0-1_aarch64.deb \
            -O /tmp/mesa-vulkan-icd-wrapper.deb 2>/dev/null; then
            dpkg -i /tmp/mesa-vulkan-icd-wrapper.deb 2>/dev/null || true
            rm -f /tmp/mesa-vulkan-icd-wrapper.deb
            ok "Mali Vulkan ICD wrapper installed."
        else
            warn "Failed to download ICD wrapper — ANGLE may not work correctly."
            warn "Manual install: dpkg -i mesa-vulkan-icd-wrapper_*.deb"
        fi

        ok "Mali GPU packages installed."
        ;;

    *)
        info "Installing VirGL fallback..."
        pkg install -y \
            virglrenderer-android \
            glmark2 2>/dev/null || true
        ok "VirGL fallback packages installed."
        ;;
esac

# ===========================================================================
# CREATE GPU COMMANDS
# ===========================================================================
info "Creating GPU commands..."

# --- start-gpu-auto (auto-detect and start) --------------------------------
cat > "$PREFIX/bin/start-gpu-auto" << 'CMD'
#!/usr/bin/env bash
set -e

echo "[*] Auto-detecting GPU and starting acceleration..."

# Detect GPU
GPU_INFO=""
if command -v getprop >/dev/null 2>&1; then
    GPU_INFO=$(getprop ro.hardware.egl 2>/dev/null || echo "")
fi

if echo "$GPU_INFO" | grep -qi "adreno\|qualcomm\|qcom"; then
    echo "[+] Adreno GPU detected — starting Turnip + Zink"
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export TU_DEBUG=noconform
    virgl_test_server_android &

elif echo "$GPU_INFO" | grep -qi "mali\|arm\|mediatek"; then
    echo "[+] Mali GPU detected — starting VirGL + ANGLE"
    if [ -x "$HOME/vgl" ]; then
        ~/vgl angle=vulkan &
    else
        virgl_test_server_android --angle-vulkan &
    fi

else
    echo "[!] Unknown GPU — starting VirGL fallback"
    virgl_test_server_android &
fi

echo "[+] GPU acceleration started."
CMD
chmod +x "$PREFIX/bin/start-gpu-auto"

# --- start-gpu-turnip (Adreno only) ----------------------------------------
cat > "$PREFIX/bin/start-gpu-turnip" << 'CMD'
#!/usr/bin/env bash
set -e

echo "[*] Starting Turnip + Zink (Adreno only)..."
pkill -9 -f virgl_test_server_android 2>/dev/null || true
sleep 0.2

export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform

virgl_test_server_android &

echo "[+] Turnip + Zink started."
echo "[*] In proot, use: GALLIUM_DRIVER=virpipe <app>"
CMD
chmod +x "$PREFIX/bin/start-gpu-turnip"

# --- start-gpu-angle (Mali only) -------------------------------------------
cat > "$PREFIX/bin/start-gpu-angle" << 'CMD'
#!/usr/bin/env bash
set -e

echo "[*] Starting VirGL + ANGLE (Mali only)..."
pkill -9 -f virgl_test_server_android 2>/dev/null || true
pkill -9 -f vgl 2>/dev/null || true
sleep 0.2

if [ -x "$HOME/vgl" ]; then
    ~/vgl angle=vulkan &
else
    virgl_test_server_android --angle-vulkan &
fi

echo "[+] VirGL + ANGLE started."
echo "[*] In proot, use: gpu <app> for hardware acceleration"
CMD
chmod +x "$PREFIX/bin/start-gpu-angle"

# --- gpu command (run app with HW accel — Mali) ----------------------------
cat > "$PREFIX/bin/gpu" << 'CMD'
#!/usr/bin/env bash
set -e

if [ $# -eq 0 ]; then
    echo "Usage: gpu <command> [args...]"
    echo ""
    echo "Run a command with GPU hardware acceleration."
    echo "Example: gpu glxgears"
    echo "Example: gpu firefox"
    echo ""
    echo "This sets the correct environment variables for VirGL/ANGLE."
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

# --- monitor-gpu (show GPU info) -------------------------------------------
cat > "$PREFIX/bin/monitor-gpu" << 'CMD'
#!/usr/bin/env bash
set -e

echo "=== GPU Information ==="
echo ""

# GPU type
if command -v getprop >/dev/null 2>&1; then
    GPU_EGL=$(getprop ro.hardware.egl 2>/dev/null || echo "unknown")
    GPU_VULKAN=$(getprop ro.hardware.vulkan 2>/dev/null || echo "unknown")
    echo "EGL:     $GPU_EGL"
    echo "Vulkan:  $GPU_VULKAN"
fi

# GPU temperature (Adreno)
if [ -f /sys/class/kgsl/kgsl-3d0/temp ]; then
    TEMP=$(cat /sys/class/kgsl/kgsl-3d0/temp 2>/dev/null || echo "N/A")
    echo "GPU Temp: ${TEMP}°C"
fi

# GPU frequency (Adreno)
if [ -f /sys/class/kgsl/kgsl-3d0/devfreq/cur_freq ]; then
    FREQ=$(cat /sys/class/kgsl/kgsl-3d0/devfreq/cur_freq 2>/dev/null || echo "N/A")
    echo "GPU Freq: $((FREQ / 1000000)) MHz"
fi

# CPU temperatures
echo ""
echo "=== CPU Temperatures ==="
for zone in /sys/class/thermal/thermal_zone*/temp; do
    if [ -r "$zone" ]; then
        TEMP=$(cat "$zone" 2>/dev/null || echo "N/A")
        ZONE_NAME=$(dirname "$zone" | xargs basename 2>/dev/null || echo "$zone")
        echo "  $ZONE_NAME: ${TEMP}"
    fi
done 2>/dev/null || echo "  N/A"

# Memory
echo ""
echo "=== Memory ==="
free -h 2>/dev/null || cat /proc/meminfo | head -5

# Active GPU processes
echo ""
echo "=== GPU Processes ==="
ps -eo pid,cmd 2>/dev/null | grep -i "virgl\|vgl\|angle\|zink\|turnip" | grep -v grep || echo "  No GPU processes"
CMD
chmod +x "$PREFIX/bin/monitor-gpu"

# --- benchmark-gpu (run GLMark2) -------------------------------------------
cat > "$PREFIX/bin/benchmark-gpu" << 'CMD'
#!/usr/bin/env bash
set -e

echo "=== GPU Benchmark ==="
echo ""

if command -v glmark2 >/dev/null 2>&1; then
    echo "[*] Running GLMark2..."
    echo ""

    export DISPLAY="${DISPLAY:-:0}"
    export GALLIUM_DRIVER=virpipe
    export MESA_GL_VERSION_OVERRIDE=4.1COMPAT
    unset LIBGL_ALWAYS_SOFTWARE

    glmark2 2>/dev/null || echo "[!] GLMark2 failed — check GPU setup"
else
    echo "[!] glmark2 not installed"
    echo "    Install: pkg install glmark2"
fi
CMD
chmod +x "$PREFIX/bin/benchmark-gpu"

# ===========================================================================
# CPU OPTIMIZATION COMMANDS
# ===========================================================================
info "Creating CPU optimization commands..."

# --- optimize-desktop (pin desktop to big cores) ---------------------------
cat > "$PREFIX/bin/optimize-desktop" << 'CMD'
#!/usr/bin/env bash
set -e

echo "[*] Optimizing desktop process placement..."

# Find PIDs of desktop processes
XFCE_PID=$(pgrep -f "xfce4-session\|startxfce4" 2>/dev/null | head -1 || echo "")
PULSE_PID=$(pgrep -f "pulseaudio" 2>/dev/null | head -1 || echo "")
VIRGL_PID=$(pgrep -f "virgl_test_server\|vgl" 2>/dev/null | head -1 || echo "")

# Pin desktop to big cores (4-7 on typical 8-core SoC)
if [ -n "$XFCE_PID" ]; then
    taskset -pc 4-7 "$XFCE_PID" 2>/dev/null && \
        echo "  [OK] XFCE pinned to big cores" || \
        echo "  [WARN] Could not pin XFCE"
fi

# Keep audio on little cores (low latency)
if [ -n "$PULSE_PID" ]; then
    taskset -pc 0-3 "$PULSE_PID" 2>/dev/null && \
        echo "  [OK] PulseAudio pinned to little cores" || \
        echo "  [WARN] Could not pin PulseAudio"
fi

# Pin GPU server to big cores
if [ -n "$VIRGL_PID" ]; then
    taskset -pc 4-7 "$VIRGL_PID" 2>/dev/null && \
        echo "  [OK] GPU server pinned to big cores" || \
        echo "  [WARN] Could not pin GPU server"
fi

echo ""
echo "[+] Desktop optimization complete."
CMD
chmod +x "$PREFIX/bin/optimize-desktop"

# --- monitor-thermal (show temperatures) -----------------------------------
cat > "$PREFIX/bin/monitor-thermal" << 'CMD'
#!/usr/bin/env bash
set -e

echo "=== Thermal Status ==="
echo ""

# CPU temperatures
for zone in /sys/class/thermal/thermal_zone*/temp; do
    if [ -r "$zone" ]; then
        TEMP=$(cat "$zone" 2>/dev/null || echo "N/A")
        ZONE_NAME=$(basename "$(dirname "$zone")" 2>/dev/null || echo "$zone")
        # Convert millidegrees to degrees if needed
        if [ "$TEMP" -gt 1000 ] 2>/dev/null; then
            TEMP="$((TEMP / 1000))°C"
        else
            TEMP="${TEMP}°C"
        fi
        echo "  $ZONE_NAME: $TEMP"
    fi
done 2>/dev/null

# GPU temperature (Adreno)
if [ -f /sys/class/kgsl/kgsl-3d0/temp ]; then
    TEMP=$(cat /sys/class/kgsl/kgsl-3d0/temp 2>/dev/null || echo "N/A")
    if [ "$TEMP" -gt 1000 ] 2>/dev/null; then
        TEMP="$((TEMP / 1000))°C"
    fi
    echo "  GPU: ${TEMP}"
fi

echo ""
echo "Tip: If temperatures > 70°C, reduce load to prevent throttling."
CMD
chmod +x "$PREFIX/bin/monitor-thermal"

# ===========================================================================
# DONE
# ===========================================================================
hr
ok "Performance optimization complete!"
echo ""
echo "  Detected GPU: ${GRN}${GPU_TYPE}${NC}"
echo ""
echo "  GPU commands:"
echo "    start-gpu-auto      — Auto-detect and start best GPU driver"
echo "    start-gpu-turnip    — Start Turnip+Zink (Adreno only)"
echo "    start-gpu-angle     — Start VirGL+ANGLE (Mali only)"
echo "    gpu <app>           — Run app with GPU acceleration"
echo ""
echo "  Monitoring:"
echo "    monitor-gpu         — Show GPU info and processes"
echo "    monitor-thermal     — Show CPU/GPU temperatures"
echo "    benchmark-gpu       — Run GLMark2 benchmark"
echo ""
echo "  CPU optimization:"
echo "    optimize-desktop    — Pin desktop to big cores"
echo ""
echo "  Usage:"
echo "    start-gpu-auto      # Start GPU (in Termux)"
echo "    start-audio         # Start audio (in Termux)"
echo "    start-x11           # Start X11 (in Termux)"
echo "    ubuntu              # Enter Ubuntu"
echo "    desktop             # Launch XFCE"
echo "    gpu firefox         # Run Firefox with GPU (Mali)"
hr
