#!/usr/bin/env bash
# =============================================================================
# Saved GP — 01-setup.sh
# System-level configuration for a freshly installed Bluefin laptop.
#
# What this does:
#   1. Copies your wallpaper and menu icon to a shared system path
#   2. Writes GNOME dconf defaults that apply to ALL new users
#   3. Stages GNOME extensions into /etc/skel/ (every new user inherits them)
#   4. Installs Flatpak apps system-wide
#
# Usage:
#   sudo bash 01-setup.sh
#
# Run ONCE per laptop, after the Bluefin initial setup wizard is complete
# and the machine is connected to Wi-Fi.
#
# After this script: create user accounts, then run 02-apply-to-user.sh
# while logged in as any user who already existed (e.g. your admin account).
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()     { echo -e "${RED}[ERR ]${NC} $*"; }
heading() { echo -e "\n${BOLD}${BLUE}▶ $*${NC}"; }

# ── Paths — edit these if you rename things on the USB ───────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ASSETS="$SCRIPT_DIR/assets"          # wallpaper.png, menu-icon.png live here
USB_EXT_DIR="$SCRIPT_DIR/extensions"    # optional: pre-downloaded extension folders

SAVED_ASSETS="/var/lib/saved/assets"    # persistent, writable on Bluefin
SKEL_EXT_DIR="/etc/skel/.local/share/gnome-shell/extensions"
DCONF_CONF_DIR="/etc/dconf/db/local.d"

# ── 0. Preflight ──────────────────────────────────────────────────────────────
preflight() {
    heading "Preflight checks"

    if [[ $EUID -ne 0 ]]; then
        err "Must be run as root.  Try: sudo bash 01-setup.sh"
        exit 1
    fi

    for cmd in flatpak dconf unzip curl python3; do
        command -v "$cmd" >/dev/null 2>&1 || { err "Required command not found: $cmd"; exit 1; }
    done

    if ping -c 1 -W 3 flathub.org &>/dev/null 2>&1; then
        ONLINE=true
        ok "Internet: connected"
    else
        ONLINE=false
        warn "Internet: NOT connected — Flatpak and extension downloads will be skipped."
        warn "Run this script again once connected to install apps and missing extensions."
    fi
}

# ── 1. Asset files ────────────────────────────────────────────────────────────
copy_assets() {
    heading "Copying asset files"

    mkdir -p "$SAVED_ASSETS"
    mkdir -p "/etc/skel/.local/share/backgrounds"

    if [[ -f "$USB_ASSETS/wallpaper.png" ]]; then
        cp "$USB_ASSETS/wallpaper.png" "$SAVED_ASSETS/wallpaper.png"
        # Skel copy so users get a local editable copy in their home
        cp "$USB_ASSETS/wallpaper.png" "/etc/skel/.local/share/backgrounds/saved-wallpaper.png"
        ok "Wallpaper → $SAVED_ASSETS/wallpaper.png"
    else
        warn "assets/wallpaper.png not found on USB — wallpaper default will be broken."
        warn "Add wallpaper.png to the assets/ folder and re-run."
    fi

    if [[ -f "$USB_ASSETS/menu-icon.png" ]]; then
        cp "$USB_ASSETS/menu-icon.png" "$SAVED_ASSETS/menu-icon.png"
        ok "Menu icon → $SAVED_ASSETS/menu-icon.png"
    else
        warn "assets/menu-icon.png not found — ArcMenu will use its default icon."
    fi
}

# ── 2. dconf system defaults ──────────────────────────────────────────────────
# These are DEFAULTS, not locks. Users can still change things if they want.
# To lock a setting so it can't be changed, also add the key path to
# /etc/dconf/db/local.d/locks/saved-locks (one path per line).
write_dconf_defaults() {
    heading "Writing dconf system defaults"

    mkdir -p "$DCONF_CONF_DIR"

    # NOTE: The wallpaper and menu icon reference /var/lib/saved/assets/ —
    # a shared path that exists for all users on this machine.
    # The ArcMenu icon also references this path.

    cat > "$DCONF_CONF_DIR/00-saved-defaults" << 'DCONF_EOF'
# =============================================================================
# Saved GP — GNOME System Defaults
# File: /etc/dconf/db/local.d/00-saved-defaults
#
# These are defaults applied to all new user sessions.
# Edit and run `sudo dconf update` to apply changes.
# =============================================================================

# ── Desktop interface ─────────────────────────────────────────────────────────

[org/gnome/desktop/interface]
accent-color='teal'
document-font-name='Adwaita Sans Medium 10 @wght=500'
enable-animations=true
font-name='Adwaita Sans Medium 10 @wght=500'
icon-theme='Adwaita'

[org/gnome/desktop/wm/preferences]
focus-mode='sloppy'

[org/gnome/mutter]
overlay-key='Super_L'

# ── Wallpaper (desktop + screensaver) ─────────────────────────────────────────
# Points to /var/lib/saved/assets/wallpaper.png — copied there by 01-setup.sh

[org/gnome/desktop/background]
color-shading-type='solid'
picture-options='zoom'
picture-uri='file:///var/lib/saved/assets/wallpaper.png'
picture-uri-dark='file:///var/lib/saved/assets/wallpaper.png'
primary-color='#000000000000'
secondary-color='#000000000000'

[org/gnome/desktop/screensaver]
color-shading-type='solid'
picture-options='zoom'
picture-uri='file:///var/lib/saved/assets/wallpaper.png'
primary-color='#000000000000'
secondary-color='#000000000000'

# ── GNOME Shell extensions ────────────────────────────────────────────────────
# enabled-extensions lists the extensions to activate for each new user.
# The extensions themselves must be installed on disk (in /etc/skel/ or
# /usr/share/gnome-shell/extensions/) — this just switches them on.

[org/gnome/shell]
disable-user-extensions=false
disabled-extensions=['logomenu@aryan_k', 'dash-to-dock@micxgx.gmail.com', 'apps-menu@gnome-shell-extensions.gcampax.github.com', 'window-list@gnome-shell-extensions.gcampax.github.com', 'places-menu@gnome-shell-extensions.gcampax.github.com']
enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com', 'blur-my-shell@aunetx', 'gsconnect@andyholmes.github.io', 'tailscale@joaophi.github.com', 'search-light@icedman.github.com', 'just-perfection-desktop@just-perfection', 'dash-to-panel@jderose9.github.com', 'arcmenu@arcmenu.com', 'lockscreen-extension@pratap.fastmail.fm', 'windowIsReady_Remover@nunofarruca@gmail.com']
favorite-apps=['com.brave.Browser.desktop', 'com.google.Chrome.desktop', 'org.onlyoffice.desktopeditors.desktop']

# ── Dash to Panel ─────────────────────────────────────────────────────────────

[org/gnome/shell/extensions/dash-to-panel]
animate-appicon-hover=true
animate-appicon-hover-animation-extent={'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1}
appicon-margin=0
appicon-padding=8
dot-position='BOTTOM'
dot-style-unfocused='DOTS'
group-apps=true
group-apps-label-font-size=12
group-apps-use-launchers=true
hotkeys-overlay-combo='TEMPORARILY'
leftbox-padding=0
leftbox-size=12
panel-anchors='{"CMN-0x00000000":"MIDDLE"}'
panel-element-positions='{"CMN-0x00000000":[{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"activitiesButton","visible":true,"position":"stackedTL"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'
panel-lengths='{}'
panel-positions='{}'
panel-side-padding=0
panel-sizes='{"CMN-0x00000000":44}'
show-apps-icon-file=''
show-favorites=true
show-running-apps=true
status-icon-padding=0
trans-border-use-custom-color=true
trans-panel-opacity=0.0
trans-use-border=false
trans-use-custom-gradient=false
trans-use-custom-opacity=true
tray-padding=2
tray-size=12
window-preview-title-position='TOP'

# ── ArcMenu ───────────────────────────────────────────────────────────────────
# menu-button-icon points to the shared Saved menu icon.

[org/gnome/shell/extensions/arcmenu]
application-shortcuts=[{'id': 'ArcMenu_Software', 'name': 'Software'}, {'id': 'org.gnome.Settings.desktop'}, {'id': 'org.gnome.tweaks.desktop'}, {'id': 'ArcMenu_ActivitiesOverview', 'name': 'Activities Overview', 'icon': 'view-fullscreen-symbolic'}]
apps-show-extra-details=false
left-panel-width=315
menu-background-color='rgba(48,48,49,0.98)'
menu-border-color='rgb(60,60,60)'
menu-border-width=1
menu-button-appearance='Icon_Text'
menu-button-bg-color=(false, 'rgba(242,242,242,0.2)')
menu-button-border-radius=(true, 24)
menu-button-fg-color=(false, 'rgb(242,242,242)')
menu-button-hover-bg-color=(true, 'rgba(242,242,242,0.15)')
menu-button-icon='/var/lib/saved/assets/menu-icon.png'
menu-button-icon-size=26
menu-button-padding=-1
menu-button-position-offset=0
menu-button-text='Menu'
menu-font-size=11
menu-foreground-color='rgb(223,223,223)'
menu-item-active-bg-color='rgb(25,98,163)'
menu-item-active-fg-color='rgb(255,255,255)'
menu-item-grid-icon-size='Large'
menu-item-hover-bg-color='rgb(21,83,158)'
menu-item-hover-fg-color='rgb(255,255,255)'
menu-item-icon-size='Default'
menu-layout='Zest'
menu-separator-color='rgba(255,255,255,0.1)'
override-menu-theme=true
pinned-apps=[{'id': 'com.brave.Browser.desktop'}, {'id': 'com.google.Chrome.desktop'}, {'id': 'org.onlyoffice.desktopeditors.desktop'}, {'id': 'com.github.PintaProject.Pinta.desktop'}, {'id': 'io.github.kolunmi.Bazaar.desktop'}]
right-panel-width=200
search-entry-border-radius=(true, 25)
show-activities-button=true
windows-layout-extra-shortcuts=[{'id': 'org.gnome.Nautilus.desktop'}, {'id': 'org.gnome.Ptyxis.desktop'}, {'id': 'org.gnome.Settings.desktop'}]

# ── Blur My Shell ─────────────────────────────────────────────────────────────

[org/gnome/shell/extensions/blur-my-shell]
settings-version=2

[org/gnome/shell/extensions/blur-my-shell/appfolder]
brightness=0.59999999999999998
sigma=30

[org/gnome/shell/extensions/blur-my-shell/dash-to-dock]
blur=true
brightness=0.59999999999999998
sigma=30
static-blur=true
style-dash-to-dock=0

[org/gnome/shell/extensions/blur-my-shell/panel]
brightness=0.59999999999999998
sigma=30

[org/gnome/shell/extensions/blur-my-shell/window-list]
brightness=0.59999999999999998
sigma=30

# ── Just Perfection ───────────────────────────────────────────────────────────

[org/gnome/shell/extensions/just-perfection]
controls-manager-spacing-size=0
panel=true
theme=false
top-panel-position=0

# ── Lockscreen Extension ──────────────────────────────────────────────────────

[org/gnome/shell/extensions/lockscreen-extension]
hide-lockscreen-extension-button=true

# ── Search Light ──────────────────────────────────────────────────────────────

[org/gnome/shell/extensions/search-light]
animation-speed=200.0
background-color=(0.032799992710351944, 0.020000005140900612, 0.10000000149011612, 0.80000001192092896)
blur-brightness=0.59999999999999998
blur-sigma=30.0
border-color=(0.23000000000000001, 0.23000000000000001, 0.23000000000000001, 1.0)
border-radius=1.6499999999999999
border-thickness=0
entry-font-size=1
popup-at-cursor-monitor=false
preferred-monitor=0
scale-height=0.14999999999999999
scale-width=0.10000000000000001
shortcut-search=['<Super>space']
show-panel-icon=false

# ── Keyboard shortcuts ────────────────────────────────────────────────────────
# Ctrl+Alt+T / Ctrl+Alt+Enter  → Ptyxis terminal
# Ctrl+Shift+Esc               → Mission Center (task manager)
# Super+Print                  → Gradia screenshot editor
# Ctrl+Alt+Space / Super+.     → Smile emoji picker
# NOTE: Ctrl+Alt+Backspace (Alpaca AI) is excluded here — add back if wanted.

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Control><Alt>t'
command='/usr/bin/ptyxis --new-window'
name='Ptyxis'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='<Control><Alt>Return'
command='/usr/bin/ptyxis --new-window'
name='Ptyxis Alt'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
binding='<Control><Shift>Escape'
command='flatpak run io.missioncenter.MissionCenter'
name='Mission Center'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3]
binding='<Super>Print'
command='flatpak run be.alexandervanhee.gradia --screenshot'
name='Screenshot editor'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4]
binding='<Control><Alt>space'
command='flatpak run it.mijorus.smile'
name='Emoji picker'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5]
binding='<Super>period'
command='flatpak run it.mijorus.smile'
name='Emoji picker (Alt)'

# ── Terminal ──────────────────────────────────────────────────────────────────

[org/gnome/Ptyxis]
interface-style='dark'

DCONF_EOF

    dconf update
    ok "dconf defaults written to $DCONF_CONF_DIR/00-saved-defaults"
    ok "dconf database compiled (dconf update)"
}

# ── 3. GNOME Extensions ───────────────────────────────────────────────────────
# Extensions land in /etc/skel/.local/share/gnome-shell/extensions/
# When a new user is created, their home is seeded from /etc/skel, so they
# get all the extension files on first login.
#
# FASTER OPTION: On your reference laptop, run:
#   tar czf extensions.tar.gz -C ~/.local/share/gnome-shell extensions/
# Copy extensions.tar.gz to this USB. The script will use it automatically.

GNOME_MAJOR=""

detect_gnome_version() {
    GNOME_MAJOR=$(gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1 || echo "47")
    info "GNOME Shell major version detected: $GNOME_MAJOR"
}

install_one_extension() {
    local UUID="$1"
    local EGO_ID="$2"
    local DEST="$SKEL_EXT_DIR/$UUID"

    # Already installed system-wide by Bluefin itself — nothing to do
    if [[ -d "/usr/share/gnome-shell/extensions/$UUID" ]]; then
        info "  [sys] $UUID"
        return 0
    fi

    # Already staged in skel
    if [[ -d "$DEST" ]]; then
        info "  [ok ] $UUID"
        return 0
    fi

    # Fastest: copy from pre-downloaded folder on USB
    if [[ -d "$USB_EXT_DIR/$UUID" ]]; then
        cp -r "$USB_EXT_DIR/$UUID" "$DEST"
        ok "  [usb] $UUID"
        return 0
    fi

    # Online download from extensions.gnome.org
    if [[ "$ONLINE" == "false" ]]; then
        warn "  [skip-offline] $UUID — add to extensions/ folder on USB for offline install"
        return 1
    fi

    info "  [dl ] $UUID — downloading..."

    local API_URL="https://extensions.gnome.org/extension-info/?pk=${EGO_ID}&shell_version=${GNOME_MAJOR}"
    local API_RESP
    API_RESP=$(curl -sf --max-time 15 "$API_URL" 2>/dev/null || true)

    if [[ -z "$API_RESP" ]]; then
        warn "  [fail] $UUID — no API response (GNOME $GNOME_MAJOR may not be supported yet)"
        return 1
    fi

    local VERSION_TAG
    VERSION_TAG=$(python3 - <<PYEOF 2>/dev/null || true
import json, sys
try:
    d = json.loads('''${API_RESP}''')
    vm = d.get('shell_version_map', {})
    candidates = ['${GNOME_MAJOR}', '${GNOME_MAJOR}.0']
    for v in candidates:
        if v in vm:
            print(vm[v]['pk'])
            sys.exit()
    # Fall back to any available version (newest pk)
    if vm:
        best = sorted(vm.values(), key=lambda x: x.get('pk',0), reverse=True)[0]
        print(best['pk'])
except Exception:
    pass
PYEOF
    )

    if [[ -z "$VERSION_TAG" ]]; then
        warn "  [fail] $UUID — no compatible version found for GNOME $GNOME_MAJOR"
        return 1
    fi

    local DL_URL="https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version_tag=${VERSION_TAG}"
    local TMP_ZIP="/tmp/saved_ext_$$.zip"

    if curl -sf --max-time 60 -o "$TMP_ZIP" "$DL_URL"; then
        mkdir -p "$DEST"
        unzip -q "$TMP_ZIP" -d "$DEST" && ok "  [dl ] $UUID" || warn "  [fail] $UUID — unzip error"
        rm -f "$TMP_ZIP"
    else
        warn "  [fail] $UUID — download failed"
        rm -f "$TMP_ZIP"
        return 1
    fi
}

install_extensions() {
    heading "Installing GNOME extensions → /etc/skel"

    # TIP: Place a file called extensions.tar.gz in the same folder as this
    # script (created from your reference laptop — see README) to skip downloads.
    if [[ -f "$SCRIPT_DIR/extensions.tar.gz" ]]; then
        info "Found extensions.tar.gz on USB — extracting to skel..."
        mkdir -p "$SKEL_EXT_DIR"
        tar xzf "$SCRIPT_DIR/extensions.tar.gz" -C "/etc/skel/.local/share/gnome-shell/" \
            --strip-components=0 2>/dev/null || true
        ok "Extensions extracted from USB archive"
        # Still run the loop below so system-wide ones are detected cleanly
    fi

    mkdir -p "$SKEL_EXT_DIR"
    detect_gnome_version

    info "Extension status (sys=Bluefin built-in, usb=from USB, dl=downloaded, ok=already staged):"

    # Format: [UUID]  extensions.gnome.org numeric ID
    # Bluefin already bundles some of these (appindicator, gsconnect, tailscale
    # are common). The script will detect and skip those automatically.
    declare -A EXTS=(
        ["appindicatorsupport@rgcjonas.gmail.com"]="615"
        ["blur-my-shell@aunetx"]="3193"
        ["gsconnect@andyholmes.github.io"]="1319"
        ["tailscale@joaophi.github.com"]="4724"
        ["search-light@icedman.github.com"]="5489"
        ["just-perfection-desktop@just-perfection"]="3843"
        ["dash-to-panel@jderose9.github.com"]="1160"
        ["arcmenu@arcmenu.com"]="3628"
        ["lockscreen-extension@pratap.fastmail.fm"]="2080"
        ["windowIsReady_Remover@nunofarruca@gmail.com"]="3037"
    )

    local FAILED=()
    for UUID in "${!EXTS[@]}"; do
        install_one_extension "$UUID" "${EXTS[$UUID]}" || FAILED+=("$UUID")
    done

    if [[ ${#FAILED[@]} -gt 0 ]]; then
        warn "Extensions not installed (handle manually or see README):"
        for f in "${FAILED[@]}"; do warn "    - $f"; done
    else
        ok "All extensions staged"
    fi
}

# ── 4. Flatpak apps ───────────────────────────────────────────────────────────
# Installed system-wide so every user can run them without re-downloading.
# Derived from your flatpak list, minus apps pre-installed by Bluefin.
#
# Bluefin typically pre-installs: firefox, calculator, calendar, clocks,
# weather, maps, contacts, text-editor, ptyxis, baobab, loupe, etc.
# The list below only adds what Bluefin doesn't include.
#
# EDIT THIS LIST to suit the education centre — e.g. remove Spotify or
# RetroDeck if they're not appropriate.

install_flatpaks() {
    heading "Installing Flatpak apps (system-wide)"

    # Ensure Flathub is registered
    flatpak remote-add --if-not-exists --system flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

    local APPS=(
        # ── Browsers ──────────────────────────────────────────────────────────
        com.brave.Browser
        com.google.Chrome

        # ── Office & productivity ──────────────────────────────────────────────
        org.onlyoffice.desktopeditors

        # ── App management ────────────────────────────────────────────────────
        com.mattjakeman.ExtensionManager   # manage GNOME extensions via GUI
        com.github.tchx84.Flatseal        # manage Flatpak permissions
        io.github.flattool.Warehouse       # Flatpak app manager
        io.github.flattool.Ignition        # Flatpak startup/autostart manager
        io.github.kolunmi.Bazaar           # software centre

        # ── Images & creative ─────────────────────────────────────────────────
        com.github.PintaProject.Pinta      # simple image editor (Paint-like)
        org.gimp.GIMP                      # full image editor

        # ── System utilities ──────────────────────────────────────────────────
        io.missioncenter.MissionCenter     # task manager (Ctrl+Shift+Esc)
        io.gitlab.adhami3310.Impression    # USB/ISO flasher
        page.tesk.Refine                   # file search

        # ── Productivity & focus ──────────────────────────────────────────────
        com.rafaelmardojai.Blanket         # ambient sound player

        # ── Media ─────────────────────────────────────────────────────────────
        com.spotify.Client

        # ── Education / coding ────────────────────────────────────────────────
        org.thonny.Thonny                  # Python IDE for beginners

        # ── Web app wrapper ───────────────────────────────────────────────────
        net.codelogistics.webapps          # pin web apps as desktop apps
    )

    # Uncomment to include gaming/retro (probably not for education pilot):
    # net.retrodeck.retrodeck

    info "Installing ${#APPS[@]} apps — this may take a while..."
    local FAILED=()
    local SKIPPED=0

    for APP in "${APPS[@]}"; do
        # Strip inline comments if any (lines like "com.foo.bar  # comment")
        APP="${APP%% *}"
        [[ -z "$APP" ]] && continue

        if flatpak info --system "$APP" &>/dev/null 2>&1; then
            info "  [ok ] $APP"
            (( SKIPPED++ )) || true
        else
            info "  [dl ] $APP..."
            if flatpak install --system --noninteractive flathub "$APP" \
                    >/dev/null 2>&1; then
                ok "  [ok ] $APP"
            else
                warn "  [fail] $APP"
                FAILED+=("$APP")
            fi
        fi
    done

    if [[ ${#FAILED[@]} -gt 0 ]]; then
        warn "Failed to install (retry: sudo flatpak install --system flathub <id>):"
        for f in "${FAILED[@]}"; do warn "    $f"; done
    else
        ok "All Flatpak apps installed"
    fi
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    local DCONF_FILE="$DCONF_CONF_DIR/00-saved-defaults"
    local EXT_COUNT
    EXT_COUNT=$(find "$SKEL_EXT_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l || echo "?")

    echo ""
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║   Saved GP — system setup complete!               ║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  dconf defaults  →  $DCONF_FILE"
    echo -e "  Extensions skel →  $SKEL_EXT_DIR  ($EXT_COUNT staged)"
    echo -e "  Assets          →  $SAVED_ASSETS"
    echo ""
    echo -e "${BOLD}  What happens next for new users:${NC}"
    echo "  • On first login, GNOME reads the system dconf defaults"
    echo "    (wallpaper, panel layout, ArcMenu, extensions list)"
    echo "  • The skel extensions are already in their home directory"
    echo "    from account creation, so extensions activate immediately"
    echo "  • Flatpaks are system-wide — no per-user download needed"
    echo ""
    echo -e "${BOLD}${YELLOW}  Action required for your existing admin user:${NC}"
    echo "  Log in as that user and run:"
    echo "    bash 02-apply-to-user.sh"
    echo "  (This applies the same settings to an already-existing account)"
    echo ""
    echo -e "${BOLD}  Recommended: reboot before creating education user accounts.${NC}"
    echo ""
}

# ── Entry point ───────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║   Saved GP — Bluefin System Setup (01)       ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    preflight
    copy_assets
    write_dconf_defaults
    install_extensions

    if [[ "$ONLINE" == "true" ]]; then
        install_flatpaks
    else
        warn "Skipping Flatpak installs — no internet."
        warn "Once connected, run: sudo bash 01-setup.sh   (it will skip already-done steps)"
    fi

    print_summary
}

main "$@"
