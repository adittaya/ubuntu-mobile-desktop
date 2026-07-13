#!/usr/bin/env bash
# =============================================================================
# SCRIPT 2: UBUNTU INSTALL & LOGIN
# =============================================================================
# Installs Ubuntu via proot-distro, creates ubuntu user with sudo,
# and creates the global 'ubuntu' login command.
#
# Usage:  bash setup-ubuntu.sh
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
echo -e "${GRN}      SCRIPT 2: UBUNTU INSTALL & LOGIN            ${NC}"
hr

# ============================= INSTALL UBUNTU ==============================
info "Setting up Ubuntu environment..."
if ! proot-distro list 2>/dev/null | grep -q "ubuntu"; then
    proot-distro install ubuntu
else
    ok "Ubuntu already installed."
fi

# ============================= CONFIGURE USER ==============================
info "Configuring ubuntu user and sudo privileges..."
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

# ============================= CREATE LOGIN COMMAND ========================
info "Creating ubuntu global command..."
cat > "$PREFIX/bin/ubuntu" << 'CMD'
#!/usr/bin/env bash
set -e

export TMPDIR=/data/data/com.termux/files/usr/tmp
echo -e "\e[1;32m[+] Entering Ubuntu...\e[0m"
proot-distro login ubuntu --shared-tmp --no-sysvipc --user ubuntu
CMD
chmod +x "$PREFIX/bin/ubuntu"

# ============================= DONE ========================================
hr
ok "Script 2 Completed. Login command created."
echo ""
echo "  Usage:"
echo "    ubuntu    — Enter Ubuntu shell"
echo ""
echo "  Next: bash setup-desktop.sh  (run inside Ubuntu)"
hr
