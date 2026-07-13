#!/usr/bin/env bash
# =============================================================================
# SCRIPT 3: DESKTOP & GUI DEPENDENCIES
# =============================================================================
# Installs XFCE desktop, audio/GPU client tools inside Ubuntu,
# and creates the global 'desktop' launcher command.
#
# MUST be run INSIDE Ubuntu (after running 'ubuntu' command).
#
# Usage (inside Ubuntu):  bash setup-desktop.sh
# =============================================================================
set -euo pipefail

RED='\e[1;31m'; GRN='\e[1;32m'; YEL='\e[1;33m'; BLU='\e[1;34m'; NC='\e[0m'
info()  { echo -e "${BLU}[*]${NC} $*"; }
ok()    { echo -e "${GRN}[+]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*" >&2; }
hr()    { echo -e "${BLU}==================================================${NC}"; }

hr
echo -e "${GRN}      SCRIPT 3: DESKTOP & GUI DEPENDENCIES        ${NC}"
hr

# ============================= INSTALL XFCE ================================
info "Installing XFCE and client graphics/audio tools..."
apt update -y
apt install -y \
    xfce4 xfce4-goodies \
    dbus-x11 xauth \
    mesa-utils alsa-utils

# ============================= CREATE DESKTOP COMMAND =======================
info "Creating desktop global command..."
cat > /usr/local/bin/desktop << 'CMD'
#!/usr/bin/env bash
set -e

export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
export GALLIUM_DRIVER=virpipe

unset DBUS_SESSION_BUS_ADDRESS

USER_RUNTIME_DIR="/run/user/$(id -u)"
mkdir -p "$USER_RUNTIME_DIR"
chmod 700 "$USER_RUNTIME_DIR"

echo -e "\e[1;32m[+] Launching XFCE via clean DBus session...\e[0m"
sleep 1

exec dbus-launch --exit-with-session startxfce4
CMD
chmod +x /usr/local/bin/desktop

# ============================= DONE ========================================
hr
ok "Script 3 Completed. desktop command is ready to use."
echo ""
echo "  Usage:"
echo "    desktop   — Launch XFCE desktop"
echo ""
echo "  Workflow:"
echo "    1. start-audio      (in Termux)"
echo "    2. start-x11        (in Termux)"
echo "    3. Open Termux X11 app"
echo "    4. ubuntu           (in Termux)"
echo "    5. desktop          (inside Ubuntu)"
hr
