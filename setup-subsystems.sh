#!/usr/bin/env bash
# =============================================================================
# SCRIPT 1: SUBSYSTEMS & DEPENDENCIES
# =============================================================================
# Installs all Termux packages and creates global convenience commands:
#   start-audio, start-x11, start-display, start-graphics, start-wayland
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
    pulseaudio \
    wget curl coreutils

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

# ============================= DONE ========================================
hr
ok "Script 1 Completed. Subsystems ready."
echo ""
echo "  Created commands:"
echo "    start-audio      — Start PulseAudio server"
echo "    start-graphics   — Start VirGL GPU server"
echo "    start-x11        — Start X11 + VirGL together"
echo "    start-display    — Minimal X11 start (clean restart)"
echo "    start-wayland    — Bring Termux X11 to foreground"
echo ""
echo "  Next: bash setup-ubuntu.sh"
hr
