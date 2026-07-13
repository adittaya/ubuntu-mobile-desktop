#!/usr/bin/env bash
# =============================================================================
# SCRIPT 4: PRE-BUILT DESKTOP — Full XFCE with Apps, Themes & Config
# =============================================================================
# Installs a complete, ready-to-use XFCE desktop with:
#   - Common apps (Firefox, File Manager, Terminal, Text Editor, etc.)
#   - Custom theme (Arc-Dark), Papirus icons, wallpapers
#   - Pre-configured panel layout, desktop settings, shortcuts
#   - Audio/GPU environment pre-set
#
# MUST be run INSIDE Ubuntu (after running 'ubuntu' command).
# This is OPTIONAL — use setup-desktop.sh for a minimal install.
#
# Usage (inside Ubuntu):  bash setup-desktop-prebuilt.sh
# =============================================================================
set -euo pipefail

RED='\e[1;31m'; GRN='\e[1;32m'; YEL='\e[1;33m'; BLU='\e[1;34m'; NC='\e[0m'
info()  { echo -e "${BLU}[*]${NC} $*"; }
ok()    { echo -e "${GRN}[+]${NC} $*"; }
warn()  { echo -e "${YEL}[!]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*" >&2; }
hr()    { echo -e "${BLU}==================================================${NC}"; }

hr
echo -e "${GRN}   SCRIPT 4: PRE-BUILT DESKTOP — FULL XFCE SETUP   ${NC}"
hr

# ============================= CORE PACKAGES ===============================
info "Installing XFCE desktop and core packages..."
apt update -y
apt install -y \
    xfce4 xfce4-goodies \
    dbus-x11 xauth \
    mesa-utils alsa-utils \
    pavucontrol pulseaudio \
    firefox vlc ffmpeg \
    mousepad pluma \
    xterm lxterminal \
    thunar thunar-archive-plugin thunar-volman \
    ristretto parole \
    xdg-utils xdg-user-dirs \
    fonts-noto fonts-liberation \
    arc-theme \
    wget curl git htop neofetch tree \
    network-manager network-manager-gnome \
    gnome-screenshot xfce4-screenshooter

# ============================= THEMES & ICONS ==============================
info "Installing Arc-Dark theme and Papirus icons..."
add-apt-repository -y ppa:papirus/papirus 2>/dev/null || true
apt update -y
apt install -y papirus-icon-theme arc-theme 2>/dev/null || {
    warn "Papirus PPA not available, installing from source..."
    cd /tmp
    wget -q "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.tar.gz" -O papirus.tar.gz 2>/dev/null || true
    tar xzf papirus.tar.gz 2>/dev/null && cp -r papirus-icon-theme-master/Papirus /usr/share/icons/ 2>/dev/null || true
    rm -rf papirus-icon-theme-master papirus.tar.gz 2>/dev/null
    cd -
}

# ============================= WALLPAPERS ==================================
info "Setting up wallpapers directory..."
mkdir -p /home/ubuntu/Wallpapers

cat > /home/ubuntu/Wallpapers/README.md << 'EOF'
# Wallpapers

Place your wallpaper images here.

Supported formats: JPG, PNG, BMP, WEBP

To set a wallpaper:
  Right-click desktop → Desktop Settings → Backdrop → Select Image
EOF

# Download a few free wallpapers if wget is available
for url in \
    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&q=80" \
    "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1920&q=80" \
    "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1920&q=80"; do
    fname=$(basename "$url" | cut -d'?' -f1)
    wget -q "$url" -O "/home/ubuntu/Wallpapers/$fname" 2>/dev/null || true
done
chown -R ubuntu:ubuntu /home/ubuntu/Wallpapers 2>/dev/null || true

# ============================= XFCE CONFIG =================================
info "Pre-configuring XFCE desktop settings..."

# Create xfconf directory
mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /home/ubuntu/.config/xfce4/panel
mkdir -p /home/ubuntu/.config/xfce4/helpers.rc.d

# --- Desktop settings (backdrop, icons) ---
cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorscreen" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/xfce-blue.svg"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="2"/>
  </property>
</channel>
XMLEOF

# --- Window Manager settings ---
cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Arc-Dark"/>
    <property name="title_font" type="string" value="Noto Sans Bold 10"/>
    <property name="placement_ratio" type="int" value="50"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="tile_on_move" type="bool" value="true"/>
    <property name="show_frame_shadow" type="bool" value="true"/>
    <property name="show_dock_shadow" type="bool" value="true"/>
  </property>
</channel>
XMLEOF

# --- Appearance settings (theme, icons) ---
cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Noto Sans 10"/>
    <property name="MonospaceFontName" type="string" value="Noto Sans Mono 10"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
  </property>
</channel>
XMLEOF

# --- Panel layout (bottom panel with dock) ---
cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="48"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whisker-menu"/>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator"/>
    <property name="plugin-4" type="string" value="clock"/>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="pulseaudio"/>
    <property name="plugin-7" type="string" value="actions"/>
  </property>
</channel>
XMLEOF

# --- Keyboard shortcuts ---
cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="Custom" type="empty">
    <property name="Default" type="empty">
      <property name="&lt;Super&gt;e" type="string" value="thunar"/>
      <property name="&lt;Super&gt;t" type="string" value="xterm"/>
      <property name="&lt;Super&gt;l" type="string" value="xflock4"/>
      <property name="&lt;Ctrl&gt;&lt;Alt&gt;Delete" type="string" value="xfce4-session-logout"/>
      <property name="&lt;Ctrl&gt;&lt;Alt&gt;t" type="string" value="xterm"/>
      <property name="Print" type="string" value="xfce4-screenshooter"/>
    </property>
  </property>
</channel>
XMLEOF

# --- Mousepad (text editor) settings ---
mkdir -p /home/ubuntu/.config/Mousepad
cat > /home/ubuntu/.config/Mousepad/mousepad.conf << 'EOF'
[Preferences]
Font-Name=Noto Sans Mono 11
Show-Line-Numbers=true
Highlight-current-line=true
Auto-indent=true
Word-wrap=true
EOF

# Set ownership
chown -R ubuntu:ubuntu /home/ubuntu/.config 2>/dev/null || true

# ============================= DESKTOP LAUNCHER ============================
info "Creating desktop-prebuilt launcher command..."
cat > /usr/local/bin/desktop-prebuilt << 'CMD'
#!/usr/bin/env bash
set -e

export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
export GALLIUM_DRIVER=virpipe

unset DBUS_SESSION_BUS_ADDRESS

USER_RUNTIME_DIR="/run/user/$(id -u)"
mkdir -p "$USER_RUNTIME_DIR"
chmod 700 "$USER_RUNTIME_DIR"

echo -e "\e[1;32m[+] Launching Pre-Built XFCE Desktop...\e[0m"
echo -e "\e[1;33m[+] Theme: Arc-Dark | Icons: Papirus-Dark\e[0m"
echo -e "\e[1;33m[+] Shortcuts: Super+T=Terminal, Super+E=Files\e[0m"
sleep 1

exec dbus-launch --exit-with-session startxfce4
CMD
chmod +x /usr/local/bin/desktop

# Also update the standard desktop command
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
ok "Script 4 Complete — Pre-Built Desktop Ready!"
echo ""
echo "  Installed:"
echo "    XFCE4 Desktop — Arc-Dark theme, Papirus-Dark icons"
echo "    Firefox, VLC, File Manager, Terminal, Text Editor"
echo "    Screenshots, Network Manager, Audio Controls"
echo "    Pre-configured panel, shortcuts, wallpapers"
echo ""
echo "  Shortcuts:"
echo "    Super+T        — Open Terminal"
echo "    Super+E        — Open File Manager"
echo "    Super+L        — Lock Screen"
echo "    Ctrl+Alt+Delete — Logout Menu"
echo "    Print          — Screenshot"
echo ""
echo "  Launch:"
echo "    desktop         — Launch XFCE (standard)"
echo "    desktop-prebuilt — Launch XFCE (pre-configured)"
hr
