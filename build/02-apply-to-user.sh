#!/usr/bin/env bash
# =============================================================================
# Saved GP — 02-apply-to-user.sh
# Apply Saved GP settings to an EXISTING user account.
#
# Run this AFTER 01-setup.sh has completed. Run it as the user you want
# to configure (NOT as root / sudo).
#
# Usage:
#   bash 02-apply-to-user.sh
#
# Typical use cases:
#   • Your admin account (created during Bluefin initial setup)
#   • Any user that existed before 01-setup.sh was run
#
# For NEW accounts created after 01-setup.sh, this script is not needed —
# they inherit everything automatically from /etc/skel and the dconf defaults.
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()     { echo -e "${RED}[ERR ]${NC} $*"; }
heading() { echo -e "\n${BOLD}${BLUE}▶ $*${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKEL_EXT_DIR="/etc/skel/.local/share/gnome-shell/extensions"
USER_EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
DCONF_DEFAULTS="/etc/dconf/db/local.d/00-saved-defaults"

# ── Preflight ─────────────────────────────────────────────────────────────────
preflight() {
    heading "Preflight checks"

    if [[ $EUID -eq 0 ]]; then
        err "Do NOT run this as root. Run it as the user you want to configure:"
        err "  bash 02-apply-to-user.sh"
        exit 1
    fi

    ok "Running as: $USER ($(id -u))"

    if [[ ! -f "$DCONF_DEFAULTS" ]]; then
        err "$DCONF_DEFAULTS not found."
        err "Run 01-setup.sh first (as root), then come back to this script."
        exit 1
    fi

    command -v dconf >/dev/null 2>&1 || { err "dconf not found"; exit 1; }
}

# ── Copy extensions to user home ──────────────────────────────────────────────
# Skel is only copied at account creation time, so existing users miss out.
# This step manually copies the staged extensions into the current user's home.

copy_extensions() {
    heading "Copying extensions to your home directory"

    if [[ ! -d "$SKEL_EXT_DIR" ]]; then
        warn "$SKEL_EXT_DIR is empty — run 01-setup.sh first."
        warn "Skipping extension copy."
        return
    fi

    mkdir -p "$USER_EXT_DIR"

    local COUNT=0
    for EXT_PATH in "$SKEL_EXT_DIR"/*/; do
        [[ -d "$EXT_PATH" ]] || continue
        local UUID
        UUID="$(basename "$EXT_PATH")"
        if [[ -d "$USER_EXT_DIR/$UUID" ]]; then
            info "  [ok ] $UUID"
        else
            cp -r "$EXT_PATH" "$USER_EXT_DIR/$UUID"
            ok "  [cp ] $UUID"
        fi
        (( COUNT++ )) || true
    done

    ok "$COUNT extension(s) ready in $USER_EXT_DIR"
}

# ── Apply dconf settings to this user ─────────────────────────────────────────
# We load the same defaults file that the system uses, directly into this
# user's dconf database. This overrides any previous user-level settings.
#
# NOTE: dconf load reads the path relative to the argument. Using "/" means
# the section headers like [org/gnome/...] map to /org/gnome/... — correct.

apply_dconf() {
    heading "Applying dconf settings to your user account"

    info "Loading $DCONF_DEFAULTS into your dconf..."

    # Strip comment lines (lines starting with #) before loading,
    # as some dconf versions are strict about the keyfile format.
    grep -v '^\s*#' "$DCONF_DEFAULTS" | grep -v '^\s*$' | \
        dconf load / && ok "dconf settings applied" || {
        warn "dconf load encountered an issue."
        warn "Your settings may still be partially applied — log out and back in to check."
    }

    # Explicitly set the wallpaper in case dconf load missed it
    # (some versions need these set directly)
    if [[ -f "/var/lib/saved/assets/wallpaper.png" ]]; then
        dconf write /org/gnome/desktop/background/picture-uri \
            "'file:///var/lib/saved/assets/wallpaper.png'"
        dconf write /org/gnome/desktop/background/picture-uri-dark \
            "'file:///var/lib/saved/assets/wallpaper.png'"
        dconf write /org/gnome/desktop/screensaver/picture-uri \
            "'file:///var/lib/saved/assets/wallpaper.png'"
        ok "Wallpaper paths written"
    else
        warn "Wallpaper not found at /var/lib/saved/assets/wallpaper.png"
        warn "Run 01-setup.sh (as root) with assets/wallpaper.png on the USB."
    fi
}

# ── Reload GNOME Shell ────────────────────────────────────────────────────────
reload_shell() {
    heading "Reloading GNOME Shell"

    # Check if running under Wayland or X11
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        echo ""
        echo -e "${YELLOW}  You're on Wayland (Bluefin default).${NC}"
        echo "  GNOME Shell cannot be restarted in-place on Wayland."
        echo ""
        echo -e "${BOLD}  → Log out and log back in to see all changes.${NC}"
        echo ""
    else
        info "X11 session detected — restarting GNOME Shell..."
        nohup gnome-shell --replace >/dev/null 2>&1 &
        ok "GNOME Shell restarting (may flicker briefly)"
    fi
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║   Saved GP — user settings applied!          ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Extensions staged:  $USER_EXT_DIR"
    echo "  dconf settings:     loaded from system defaults"
    echo "  Wallpaper:          /var/lib/saved/assets/wallpaper.png"
    echo ""
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        echo -e "${BOLD}  → Log out and log back in to complete the setup.${NC}"
    fi
    echo ""
}

# ── Entry point ───────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║   Saved GP — Apply to User (02)              ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    preflight
    copy_extensions
    apply_dconf
    reload_shell
    print_summary
}

main "$@"
