#!/usr/bin/env bash
# =============================================================================
# GLOBAL ONE-SHOT INSTALLER
# =============================================================================
# Run a single command to install Ubuntu Desktop on your Android device:
#
#   curl -sL https://raw.githubusercontent.com/adittaya/ubuntu-mobile-desktop/main/install.sh | bash
#
# This will:
#   1. Check prerequisites (Termux, Termux:X11)
#   2. Download all scripts from GitHub
#   3. Install Termux packages + GPU drivers
#   4. Download pre-built Ubuntu+XFCE rootfs (~1.2GB)
#   5. Configure desktop, audio, GPU acceleration
#   6. Start all services
#
# Usage:  bash install.sh
# Docs:   https://github.com/adittaya/ubuntu-mobile-desktop
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
REPO="adittaya/ubuntu-mobile-desktop"
BRANCH="main"
INSTALL_DIR="${HOME}/ubuntu-mobile-desktop"
RELEASE_TAG="v2.0.0"
TARBALL_NAME="ubuntu-mobile-desktop-rootfs-2.0.0-arm64.tar.gz"
TARBALL_URL="https://github.com/${REPO}/releases/download/${RELEASE_TAG}/${TARBALL_NAME}"
PROOT_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro"

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\e[1;31m'; GRN='\e[1;32m'; YEL='\e[1;33m'; BLU='\e[1;34m'; CYN='\e[1;36m'; NC='\e[0m'
info()  { echo -e "${BLU}[*]${NC} $*"; }
ok()    { echo -e "${GRN}[+]${NC} $*"; }
warn()  { echo -e "${YEL}[!]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*" >&2; }
hr()    { echo -e "${BLU}══════════════════════════════════════════════════════${NC}"; }
phase() { echo -e "\n${CYN}▶ ${1}${NC}\n"; }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
clear 2>/dev/null || true
hr
echo -e "${GRN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║   Ubuntu Desktop on Android — Global Installer    ║"
echo "  ║   https://github.com/adittaya/ubuntu-mobile-desktop  ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
hr
echo ""

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
phase "PREREQUISITES"

# Check Termux
if [ -z "${PREFIX:-}" ]; then
    err "This script must run inside Termux."
    echo ""
    echo "  Install Termux from F-Droid: https://f-droid.org/en/packages/com.termux/"
    echo "  Then run this script inside the Termux app."
    exit 1
fi
ok "Running in Termux"

# Check Termux:X11
if ! command -v termux-x11 >/dev/null 2>&1; then
    warn "Termux:X11 not found. Installing..."
    pkg install -y termux-x11-nightly
fi
ok "Termux:X11 available"

# Check curl/wget
for cmd in curl wget; do
    command -v "$cmd" >/dev/null 2>&1 || pkg install -y "$cmd"
done
ok "Download tools ready"

# Check disk space (need ~3GB)
AVAIL=$(df -BM "$HOME" 2>/dev/null | awk 'NR==2 {gsub(/M/,"",$4); print $4}' || echo "0")
if [ "$AVAIL" -lt 2500 ] 2>/dev/null; then
    warn "Low disk space: ${AVAIL}MB available. Recommend 3GB+ free."
fi

# ---------------------------------------------------------------------------
# Phase 1: Download scripts
# ---------------------------------------------------------------------------
phase "DOWNLOADING SCRIPTS"

mkdir -p "$INSTALL_DIR"

# List of scripts to download
SCRIPTS=(
    "setup-all.sh"
    "setup-subsystems.sh"
    "setup-ubuntu.sh"
    "setup-desktop.sh"
    "setup-desktop-prebuilt.sh"
    "setup-performance.sh"
)

for script in "${SCRIPTS[@]}"; do
    info "Downloading ${script}..."
    wget -q --timeout=30 --tries=3 \
        -O "${INSTALL_DIR}/${script}" \
        "https://raw.githubusercontent.com/${REPO}/${BRANCH}/${script}" 2>/dev/null && \
        ok "  ${script}" || { err "Failed to download ${script}"; exit 1; }
    chmod +x "${INSTALL_DIR}/${script}"
done
ok "All scripts downloaded to ${INSTALL_DIR}"

# ---------------------------------------------------------------------------
# Phase 2: Run setup-all.sh --fast
# ---------------------------------------------------------------------------
phase "RUNNING SETUP"

cd "$INSTALL_DIR"
bash setup-all.sh --fast

# ---------------------------------------------------------------------------
# Phase 3: Start services
# ---------------------------------------------------------------------------
phase "STARTING SERVICES"

# Start audio
info "Starting PulseAudio..."
bash "${PREFIX}/bin/start-audio" 2>/dev/null && ok "Audio started" || warn "Audio start issue"

# Auto-detect and start GPU
info "Detecting GPU and starting acceleration..."
bash "${PREFIX}/bin/start-gpu-auto" 2>/dev/null && ok "GPU started" || warn "GPU start issue"

# Start X11
info "Starting X11 display..."
bash "${PREFIX}/bin/start-x11" 2>/dev/null && ok "X11 started" || warn "X11 start issue"

sleep 2

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
hr
echo -e "${GRN}  ✓ INSTALLATION COMPLETE!${NC}"
hr
echo ""
echo -e "  ${GRN}Services running:${NC}"
echo "    • PulseAudio (audio)"
echo "    • GPU acceleration"
echo "    • X11 display"
echo ""
echo -e "  ${GRN}Next steps:${NC}"
echo ""
echo "    1. Open the ${CYN}Termux:X11${NC} app on your phone"
echo "    2. Run: ${CYN}ubuntu${NC}"
echo "    3. Run: ${CYN}desktop${NC}"
echo ""
echo -e "  ${GRN}Quick commands:${NC}"
echo "    ubuntu          — Enter Ubuntu"
echo "    desktop         — Launch XFCE desktop"
echo "    start-audio     — Restart audio"
echo "    start-gpu-auto  — Restart GPU"
echo "    start-x11       — Restart display"
echo "    gpu <app>       — Run app with GPU"
echo "    monitor-gpu     — GPU info"
echo "    optimize-desktop — Pin to big cores"
echo ""
echo -e "  ${YEL}Tip: If X11 app is black, close and reopen it.${NC}"
echo ""
echo "  Docs: https://github.com/${REPO}"
hr
echo ""
