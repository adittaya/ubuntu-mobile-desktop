#!/usr/bin/env bash
# =============================================================================
# Termux X11 + Ubuntu Proot: Full GUI + GPU + Audio Setup
# =============================================================================
# One-script installer for XFCE desktop on Android via Termux X11,
# Ubuntu proot, VirGL GPU acceleration, and PulseAudio.
#
# Usage:  bash setup-termux-gui.sh
# Docs:   https://github.com/YOUR_USER/termux-ubuntu-gui
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Colors & helpers
# ---------------------------------------------------------------------------
RED='\e[1;31m'
GRN='\e[1;32m'
YEL='\e[1;33m'
BLU='\e[1;34m'
NC='\e[0m'

info()  { echo -e "${BLU}[*]${NC} $*"; }
ok()    { echo -e "${GRN}[+]${NC} $*"; }
warn()  { echo -e "${YEL}[!]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*" >&2; }
hr()    { echo -e "${BLU}==================================================${NC}"; }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
if [ -z "${PREFIX:-}" ]; then
    err "This script must run inside Termux (PREFIX is unset)."
    exit 1
fi

hr
echo -e "${GRN}      Termux X11 + Ubuntu Proot — Full Setup      ${NC}"
hr

# ============================= PHASE 1 =====================================
# 1) Termux packages
# =============================
info "Installing Termux dependencies..."
pkg update -y
pkg install -y x11-repo
pkg install -y \
    proot-distro \
    termux-x11-nightly \
    virglrenderer-android \
    pulseaudio \
    wget curl coreutils

# ============================= PHASE 2 =====================================
# 2) Subsystem helper commands
# =============================
info "Creating subsystem commands..."

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

ok "Subsystem commands created."

# ============================= PHASE 3 =====================================
# 3) Install & configure Ubuntu via proot-distro
# =============================
info "Setting up Ubuntu..."
if ! proot-distro list 2>/dev/null | grep -q "ubuntu"; then
    proot-distro install ubuntu
fi

info "Configuring ubuntu user + sudo..."
proot-distro login ubuntu --shared-tmp --no-sysvipc -- bash -c '
apt update -y && apt install -y sudo
mkdir -p /etc/sudoers.d
echo "ubuntu ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
chmod 440 /etc/sudoers.d/ubuntu
if ! id -u ubuntu >/dev/null 2>&1; then
    useradd -m -G sudo -s /bin/bash ubuntu
    printf "ubuntu:ubuntu" | chpasswd
fi
'

# --- ubuntu login command --------------------------------------------------
info "Creating ubuntu command..."
cat > "$PREFIX/bin/ubuntu" << 'CMD'
#!/usr/bin/env bash
set -e
export TMPDIR=/data/data/com.termux/files/usr/tmp
echo "[+] Entering Ubuntu..."
proot-distro login ubuntu --shared-tmp --no-sysvipc --user ubuntu
CMD
chmod +x "$PREFIX/bin/ubuntu"

ok "Ubuntu ready — run 'ubuntu' to enter."

# ============================= PHASE 4 =====================================
# 4) Install XFCE + GUI deps inside Ubuntu
# =============================
info "Installing XFCE desktop and audio/GPU tools inside Ubuntu..."
proot-distro login ubuntu --shared-tmp --no-sysvipc --user ubuntu -- bash -c '
apt update -y
apt install -y \
    xfce4 xfce4-goodies \
    dbus-x11 xauth \
    mesa-utils alsa-utils \
    pavucontrol pulseaudio
'

# --- desktop launcher inside Ubuntu ----------------------------------------
info "Creating desktop command inside Ubuntu..."
proot-distro login ubuntu --shared-tmp --no-sysvipc --user ubuntu -- bash -c '
cat > /usr/local/bin/desktop << "INNER"
#!/usr/bin/env bash
set -e

export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
export GALLIUM_DRIVER=virpipe

unset DBUS_SESSION_BUS_ADDRESS

USER_RUNTIME_DIR="/run/user/$(id -u)"
mkdir -p "$USER_RUNTIME_DIR"
chmod 700 "$USER_RUNTIME_DIR"

echo "[+] Launching XFCE desktop..."
sleep 1
exec dbus-launch --exit-with-session startxfce4
INNER
chmod +x /usr/local/bin/desktop
'

# ============================= DONE ========================================
hr
ok "Setup complete!"
echo ""
echo "  Usage workflow:"
echo ""
echo "    1. start-audio        # start PulseAudio"
echo "    2. start-x11          # start X11 + VirGL"
echo "    3. Open Termux X11 app"
echo "    4. ubuntu             # enter Ubuntu"
echo "    5. desktop            # launch XFCE"
echo ""
echo "  See docs/TROUBLESHOOTING.md for common issues."
hr
