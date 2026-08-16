#!/usr/bin/env bash
# ============================================================
#  EndeavourOS / Arch Hyprland Setup Script
#  Run after a fresh minimal install (no DE selected)
#  Usage: bash install.sh
# ============================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[DONE]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${CYAN}══════════════════════════════════════${NC}"; \
            echo -e "${CYAN}  $*${NC}"; \
            echo -e "${CYAN}══════════════════════════════════════${NC}"; }

# ── Preflight ────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && error "Do not run as root. Run as your user with sudo access."

# ── Chassis detection ────────────────────────────────────────
# This repo provisions more than one machine, so the laptop-only pieces (TLP
# power management, lid-close-to-suspend) are gated rather than removed. They
# were previously unconditional, which meant a desktop got a TLP config and a
# logind lid rule that could never fire.
if hostnamectl chassis 2>/dev/null | grep -qE '^(laptop|notebook|convertible|tablet)$'; then
    IS_LAPTOP=yes
elif [[ -d /sys/class/power_supply/BAT0 || -d /sys/class/power_supply/BAT1 ]]; then
    # hostnamectl reports "desktop" on some boards with a bad DMI chassis type;
    # the presence of a battery is the more reliable signal.
    IS_LAPTOP=yes
else
    IS_LAPTOP=no
fi
info "Chassis detected: $([[ $IS_LAPTOP == yes ]] && echo laptop || echo desktop)"

section "Checking network connectivity"
if ! ping -c 1 archlinux.org &>/dev/null; then
    warn "No internet. Connect with: nmtui"
    error "Network required. Re-run after connecting."
fi
success "Network OK"

# ── System update ────────────────────────────────────────────
section "System update"
sudo pacman -Syu --noconfirm
success "System updated"

# ── AUR helper (yay) ─────────────────────────────────────────
section "Installing yay (AUR helper)"

if ! command -v yay &>/dev/null; then
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    cd /tmp/yay-install && makepkg -si --noconfirm
    cd ~ && rm -rf /tmp/yay-install
    success "yay installed"
else
    success "yay already installed"
fi

# ── All packages (yay handles both pacman + AUR) ──────────────
section "Installing packages"

PKGS=(
    # Hyprland ecosystem
    hyprland
    waybar
    hyprpaper
    hyprlock
    # hypridle drives the idle lock, display-off, AND lock-on-suspend (via its
    # before_sleep_cmd). Without it the machine suspends straight to an unlocked
    # desktop — a systemd --user unit on sleep.target is NOT a substitute, since
    # sleep.target does not exist in the user manager.
    hypridle
    hyprshot
    wlogout
    xdg-desktop-portal-hyprland

    # Terminal + shell
    # kitty, not alacritty: switched for yazi's image previews, which need
    # the kitty graphics protocol.
    kitty
    zsh
    zsh-completions

    # Editor
    neovim

    # Launcher + file manager
    rofi
    yazi
    pcmanfm

    # Audio (pipewire stack)
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber

    # Theming
    # wallust (AUR, listed below) replaced pywal as the palette generator.
    # python-pywal is deliberately NOT installed: wallust's `backend = "wal"`
    # is its own reimplementation of that algorithm, not a shell-out to the
    # pywal binary, so nothing needs the original package.
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
    python-fonttools          # waybar/scripts/verify-glyphs.py

    # System tools
    # Both installed on every machine: ~/.local/bin/brightness picks whichever
    # one this machine's hardware actually needs at runtime (brightnessctl for
    # a real /sys/class/backlight panel, ddcutil/DDC-CI for an external monitor
    # that has none — see that script's header). Installing only one meant
    # years of a desktop with ddcutil and brightness keys that silently did
    # nothing on a laptop that had brightnessctl instead, or vice versa.
    brightnessctl
    ddcutil
    playerctl
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman

    # Utilities
    btop
    cava
    # fastfetch, not neofetch: neofetch was discontinued upstream and dropped
    # from the Arch repositories, so listing it aborts the whole install.
    # animated-neofetch.sh already prefers fastfetch and only falls back to
    # neofetch, so nothing else has to change.
    fastfetch
    trash-cli
    jq
    pacman-contrib           # checkupdates, for waybar's updates module
    wget
    curl
    rsync
    unzip
    zip

    # Browser
    firefox

    # Display manager
    sddm

    # Notifications
    # mako, not dunst. This system ran with NO notification daemon at all for
    # a long time because dunst was listed here but never actually installed.
    mako
    libnotify

    # Screenshot deps
    grim
    slurp

    # Fonts + cursor support
    xcursor-themes

    # Clipboard
    wl-clipboard
    cliphist                 # SUPER+V history picker

    # Desktop utilities
    hyprpicker               # SUPER+C colour picker
    pavucontrol

    # AUR packages
    wallust                  # palette generator (replaced pywal)
    bibata-cursor-theme
    zsh-theme-powerlevel10k-git
    # python-pywalfox, NOT pywalfox-native — the latter does not exist in the
    # AUR and made yay fail on this list. This is the package that actually
    # provides /usr/bin/pywalfox, used by the "Setting up pywalfox" step below.
    python-pywalfox
    tty-clock
    pipes.sh
)

# Laptop-only power management; see the chassis check above.
if [[ "$IS_LAPTOP" == "yes" ]]; then
    PKGS+=(tlp)
fi

yay -S --noconfirm --needed \
    --answerclean None --answerdiff None \
    --answeredit None --answerupgrade None \
    "${PKGS[@]}"
success "Packages installed"

# ── Services ─────────────────────────────────────────────────
section "Enabling services"

sudo systemctl enable NetworkManager

# TLP is laptop power management; enabling it on a desktop does nothing useful
# and it is not installed there. See the chassis check further down.
if [[ "$IS_LAPTOP" == "yes" ]]; then
    sudo systemctl enable tlp
fi

# Display manager — try sddm, fall back to greetd.
#
# NOTE THE sudo. Without it `systemctl enable` fails with "Access denied ...
# requires interactive authentication", and because stderr is sent to /dev/null
# that failure was invisible: EVERY fresh install silently took the greetd
# fallback and never installed sddm at all. The fallback is meant for the case
# where sddm genuinely will not enable, not for a missing privilege.
if sudo systemctl enable sddm 2>/dev/null; then
    success "sddm display manager enabled"
else
    warn "sddm failed, installing greetd as fallback"
    yay -S --noconfirm --needed greetd greetd-tuigreet
    sudo mkdir -p /etc/greetd
    sudo tee /etc/greetd/config.toml > /dev/null <<'GREETEOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "greeter"
GREETEOF
    sudo systemctl enable greetd
    success "greetd display manager enabled"
fi

sudo systemctl enable bluetooth

success "Services enabled"

# ── RGB off during suspend ───────────────────────────────────
# systemd runs every executable in /usr/lib/systemd/system-sleep/ around a
# sleep transition, as root, with "pre|post suspend". Symlinked rather than
# copied so edits to the tracked script take effect without re-running this.
#
# This replaced an older openrgb.sh hook that loaded saved .orp profiles. That
# hook ran and reported success, but its profiles were snapshots of a PREVIOUS
# build and contained no entry for this machine's DDR5, so the RAM never went
# dark. Direct commands are used instead — never a stored profile.
section "Installing RGB sleep hook"

if [[ -x "$HOME/.local/bin/rgb-sleep" ]]; then
    sudo ln -sf "$HOME/.local/bin/rgb-sleep" /usr/lib/systemd/system-sleep/rgb-sleep
    success "RGB sleep hook installed"

    if [[ -e /usr/lib/systemd/system-sleep/openrgb.sh ]]; then
        warn "an old openrgb.sh sleep hook is still present — the two will fight"
        echo "    Review and remove it: /usr/lib/systemd/system-sleep/openrgb.sh"
    fi
else
    warn "~/.local/bin/rgb-sleep missing — skipping sleep hook"
fi

# ── Monitor brightness over DDC/CI ───────────────────────────
# Only relevant with an external monitor. ddcutil ships its own udev rule
# creating the i2c group and setting /dev/i2c-* to root:i2c, so no custom rule
# is needed — but the user still has to BE in that group. On a normal seat login
# systemd-logind also grants an ACL on the node, which is why this worked before
# a re-login on the machine it was developed on; the group is the fallback for
# sessions that get no seat ACL (SSH, some greeters).
section "Configuring DDC/CI monitor brightness"

if [[ -z "$(ls -A /sys/class/backlight/ 2>/dev/null)" ]]; then
    if getent group i2c >/dev/null; then
        if id -nG "$USER" | grep -qw i2c; then
            success "already in the i2c group"
        else
            sudo usermod -aG i2c "$USER"
            success "added $USER to the i2c group (takes effect at next login)"
        fi
    else
        warn "no i2c group — is ddcutil installed?"
    fi

    # Load now and at boot. Appended rather than overwritten: this machine's
    # i2c.conf also carries i2c-i801 (Intel SMBus), and a blind `tee` of just
    # i2c-dev would drop it.
    if sudo modprobe i2c-dev 2>/dev/null; then
        if grep -qsr "^i2c-dev$" /etc/modules-load.d/; then
            success "i2c-dev already set to load at boot"
        else
            echo i2c-dev | sudo tee -a /etc/modules-load.d/i2c.conf >/dev/null
            success "i2c-dev loaded and added to /etc/modules-load.d/i2c.conf"
        fi
    fi

    echo "    Verify with: ddcutil detect"
    echo "    If the monitor is not found, enable DDC/CI in its on-screen menu."
else
    echo "    Laptop backlight present — DDC/CI not needed, skipping."
fi

# ── Default shell → zsh ──────────────────────────────────────
section "Setting zsh as default shell"

if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s "$(which zsh)"
    success "Shell changed to zsh (takes effect on next login)"
else
    success "zsh already default shell"
fi

# ── Normalize powerlevel10k path ─────────────────────────────
# AUR package may install to a different location — ensure expected path exists
P10K_EXPECTED="/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme"
if [[ ! -f "$P10K_EXPECTED" ]]; then
    P10K_FOUND=$(find /usr/share -name "powerlevel10k.zsh-theme" 2>/dev/null | head -1)
    if [[ -n "$P10K_FOUND" ]]; then
        sudo mkdir -p "$(dirname "$P10K_EXPECTED")"
        sudo ln -sf "$P10K_FOUND" "$P10K_EXPECTED"
        success "powerlevel10k symlinked from $P10K_FOUND"
    else
        warn "powerlevel10k theme file not found — zsh prompt may not load"
    fi
fi

# ── Clone dotfiles ───────────────────────────────────────────
section "Cloning dotfiles"

DOTFILES_DIR="$HOME/projects/dotfiles-arch"
DOTFILES_REPO="https://github.com/boernerc20/dotfiles-arch.git"

mkdir -p "$HOME/projects"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
    info "Dotfiles repo already exists, pulling latest..."
    git -C "$DOTFILES_DIR" pull
else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

success "Dotfiles ready at $DOTFILES_DIR"

# ── Deploy dotfiles ──────────────────────────────────────────
section "Deploying dotfiles"

# Deploy everything the repo TRACKS under .config, rather than a hand-kept list.
#
# The previous hardcoded CONFIG_DIRS had drifted twice over: it still listed
# alacritty (no longer in the repo) and omitted eleven tracked directories —
# kitty, mako, yazi, firefox, wallust, systemd, xdg-desktop-portal, OpenRGB,
# htop, environment.d and the mimeapps.list. wallust is the entire theming
# engine, so a fresh install came up with no palette configuration at all and
# nothing to generate colours from.
#
# Enumerating from `git ls-files` rather than globbing the working tree means
# untracked scratch files in the clone are never deployed, and the list cannot
# fall out of date again.
mkdir -p "$HOME/.config"

mapfile -t CONFIG_ENTRIES < <(
    git -C "$DOTFILES_DIR" ls-files .config/ | cut -d/ -f2 | sort -u
)

[[ ${#CONFIG_ENTRIES[@]} -eq 0 ]] && error "No tracked .config entries found in $DOTFILES_DIR"

for entry in "${CONFIG_ENTRIES[@]}"; do
    src="$DOTFILES_DIR/.config/$entry"
    if [[ -d "$src" ]]; then
        # Copy CONTENTS into the target dir. Plain `cp -r src dest/` would nest
        # as dest/entry/entry when the directory already exists, which made
        # re-running this script produce a broken tree.
        mkdir -p "$HOME/.config/$entry"
        cp -r "$src/." "$HOME/.config/$entry/"
    elif [[ -f "$src" ]]; then
        cp "$src" "$HOME/.config/"
    else
        continue
    fi
    info "Deployed .config/$entry"
done

# ── Waybar config: desktop vs laptop ─────────────────────────
# The loop above deploys BOTH config.jsonc and config-laptop.jsonc, since it
# copies everything the repo tracks — that's fine, the unused one is just a
# few KB sitting there. What matters is which one is actually live: waybar
# only ever reads ~/.config/waybar/config.jsonc, so on a laptop chassis that
# path needs to become the trimmed variant (no updates/notification/cliphist
# widgets, native backlight instead of DDC/CI — see config-laptop.jsonc's own
# header for the full reasoning).
#
# `hostnamectl chassis` is what's checked, not a hostname pattern — chassis
# comes from DMI/ACPI data the firmware reports, so it can't drift out of sync
# with a rename the way matching on "laptop" in $HOSTNAME could.
CHASSIS=$(hostnamectl chassis 2>/dev/null || echo "")
if [[ "$CHASSIS" =~ ^(laptop|convertible|tablet|handset)$ ]]; then
    if [[ -f "$HOME/.config/waybar/config-laptop.jsonc" ]]; then
        cp "$HOME/.config/waybar/config-laptop.jsonc" "$HOME/.config/waybar/config.jsonc"
        success "Waybar: using the laptop layout (chassis: $CHASSIS)"
    else
        warn "chassis is '$CHASSIS' but config-laptop.jsonc is missing — keeping the desktop layout"
    fi
else
    info "Waybar: using the desktop layout (chassis: ${CHASSIS:-unknown})"
fi

# Deploy home dotfiles
[[ -f "$DOTFILES_DIR/.zshrc_copy" ]]  && cp "$DOTFILES_DIR/.zshrc_copy" "$HOME/.zshrc"
[[ -f "$DOTFILES_DIR/.p10k.zsh" ]]    && cp "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
[[ -f "$DOTFILES_DIR/.gtkrc-2.0" ]]   && cp "$DOTFILES_DIR/.gtkrc-2.0" "$HOME/.gtkrc-2.0"

# Deploy local bin scripts
mkdir -p "$HOME/.local/bin"
if [[ -d "$DOTFILES_DIR/.local/bin" ]]; then
    cp "$DOTFILES_DIR/.local/bin/"* "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/"*
    info "Deployed .local/bin scripts"
fi

success "Dotfiles deployed"

# ── Wallpapers ───────────────────────────────────────────────
section "Setting up wallpapers"

mkdir -p "$HOME/pics/wallpapers/upscale"
mkdir -p "$HOME/pics/screenshots"

# Wallpapers are NOT tracked in this repo — they are large and personal, so a
# fresh clone has no wallpapers/ directory and this block is skipped. It is kept
# for anyone who adds their own wallpapers/ to a fork.
if [[ -d "$DOTFILES_DIR/wallpapers" ]]; then
    cp "$DOTFILES_DIR/wallpapers/"*.png "$HOME/pics/wallpapers/" 2>/dev/null || true
    cp "$DOTFILES_DIR/wallpapers/"*.jpg "$HOME/pics/wallpapers/" 2>/dev/null || true
    [[ -d "$DOTFILES_DIR/wallpapers/upscale" ]] && \
        cp "$DOTFILES_DIR/wallpapers/upscale/"* "$HOME/pics/wallpapers/upscale/" 2>/dev/null || true
    info "Copied wallpapers from dotfiles repo"
fi

# Say what is actually true. The old unconditional "Wallpapers ready" was
# reassuring nonsense on a fresh install, where the folder is empty and the
# palette step further down has nothing to work from.
WP_COUNT=$(find "$HOME/pics/wallpapers" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | wc -l)

if (( WP_COUNT > 0 )); then
    success "Wallpapers ready at ~/pics/wallpapers ($WP_COUNT found)"
else
    warn "No wallpapers yet. Put some in ~/pics/wallpapers, then run:"
    warn "    ~/.local/bin/wal-hypr.sh ~/pics/wallpapers/<image>"
    warn "  After that, Super+W opens the picker. Until a palette exists the bar"
    warn "  and lock screen fall back to unstyled defaults."
fi

# ── Machine-local config ─────────────────────────────────────
section "Setting up machine-local config"

LOCAL_CONF="$HOME/.config/hypr/hyprland-local.conf"

if [[ ! -f "$LOCAL_CONF" ]]; then
    cat > "$LOCAL_CONF" <<'LOCALEOF'
##############################################
# hyprland-local.conf — machine-specific overrides
# Generated by install.sh — edit for this machine
##############################################

# ── MONITOR ──────────────────────────────────────────────────
# Run: hyprctl monitors   to find your display name and resolution
# Laptop example:
monitor=eDP-1, preferred, 0x0, 1

# ── GPU ENV (uncomment as needed) ────────────────────────────
# NVIDIA discrete:
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
# env = GBM_BACKEND,nvidia-drm
# env = __GL_GSYNC_ALLOWED,1
# env = __GL_VRR_ALLOWED,1

# ── MACHINE-SPECIFIC AUTOSTART ───────────────────────────────
# Jarvis only (RGB):
# exec-once = openrgb -p DEFAULT

LOCALEOF
    success "Created $LOCAL_CONF — edit monitor line after first boot"
else
    info "hyprland-local.conf already exists, skipping"
fi

# zshrc.local for machine-specific env vars
ZSHRC_LOCAL="$HOME/.zshrc.local"
if [[ ! -f "$ZSHRC_LOCAL" ]]; then
    cat > "$ZSHRC_LOCAL" <<'ZSHLOCAL'
# ~/.zshrc.local — machine-specific env vars (not in dotfiles repo)

# NVIDIA (jarvis only):
# export __GLX_VENDOR_LIBRARY_NAME=nvidia
# export GBM_BACKEND=nvidia-drm
# export __GL_GSYNC_ALLOWED=1
# export __GL_VRR_ALLOWED=1
# export WLR_NO_HARDWARE_CURSORS=1

# Secrets (API keys, tokens) do NOT belong here — .zshrc.local is a sibling of
# tracked files and this is exactly how a Home Assistant token and an
# OpenWeatherMap key ended up public in this repo for four months.
# Put them in ~/.config/shell/secrets.env instead, which *.env gitignores:
#   cp .config/shell/secrets.env.example ~/.config/shell/secrets.env
#   chmod 600 ~/.config/shell/secrets.env
# ~/.zshrc sources it automatically when present.

# Jarvis-only aliases (add back on jarvis):
# alias gotop='gotop --nvidia -s -a -p'
# alias reload-grub='~/.local/bin/reload-grub.sh'
# alias rgb-default='openrgb -p DEFAULT'
# alias rgb-off='openrgb -p OFF'

ZSHLOCAL
    success "Created ~/.zshrc.local"
fi

# ── Secrets ──────────────────────────────────────────────────
section "Setting up secrets"

# The deploy step above copies secrets.env.example (it is tracked), but the real
# file has to be created here or nothing ever reads a key: ~/.zshrc sources
# ~/.config/shell/secrets.env only `if` it exists, so its absence is silent.
#
# Created empty and 0600 rather than prompting. An unset key degrades visibly —
# the waybar weather module falls to its alert glyph — which is a better failure
# than a half-configured install that looks fine.
SECRETS="$HOME/.config/shell/secrets.env"
mkdir -p "$HOME/.config/shell"

if [[ ! -f "$SECRETS" ]]; then
    if [[ -f "$DOTFILES_DIR/.config/shell/secrets.env.example" ]]; then
        cp "$DOTFILES_DIR/.config/shell/secrets.env.example" "$SECRETS"
    else
        printf '%s\n' 'export HOME_ASSISTANT_TOKEN=""' 'export OPENWEATHER_API_KEY=""' > "$SECRETS"
    fi
    chmod 600 "$SECRETS"
    success "Created ~/.config/shell/secrets.env (0600) — add your keys"
else
    chmod 600 "$SECRETS"
    info "~/.config/shell/secrets.env already exists, left untouched"
fi

# waybar's weather module reads its OWN copy and does not see the shell's
# environment, because waybar is started by Hyprland rather than from a login
# shell. Two files, one key — rotating it means editing both, which is called
# out in the README and in secrets.env.example.
WEATHER_ENV="$HOME/.config/waybar/weather.env"
if [[ ! -f "$WEATHER_ENV" ]]; then
    mkdir -p "$HOME/.config/waybar"
    echo 'OPENWEATHER_API_KEY=""' > "$WEATHER_ENV"
    chmod 600 "$WEATHER_ENV"
    success "Created ~/.config/waybar/weather.env (0600) — add the same key here"
else
    chmod 600 "$WEATHER_ENV"
fi

# ── Initial palette run ──────────────────────────────────────
section "Generating initial colours (wallust)"

# wal-hypr.sh is the single dispatcher: it runs wallust, then propagates the
# result to hyprland, waybar, rofi, mako, kitty, cava, yazi, GTK, Qt and
# Firefox. Calling it here rather than invoking the palette generator directly
# means a fresh install lands in exactly the same state as a wallpaper switch,
# instead of a half-themed one that only looks right after the first SUPER+W.
FIRST_WALLPAPER=$(find "$HOME/pics/wallpapers" -maxdepth 1 \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -1)

if [[ -n "$FIRST_WALLPAPER" ]]; then
    if [[ -x "$HOME/.local/bin/wal-hypr.sh" ]]; then
        "$HOME/.local/bin/wal-hypr.sh" "$FIRST_WALLPAPER" \
            && success "Theme generated from $(basename "$FIRST_WALLPAPER")" \
            || warn "wal-hypr.sh reported an error — re-run it after first login"
    else
        # Fallback: at least populate the cache so nothing reads an empty palette.
        wallust run "$FIRST_WALLPAPER" && success "wallust palette generated"
        cat "$HOME/.cache/wal/colors-waybar.css" "$HOME/.config/waybar/style-base.css" \
            > "$HOME/.config/waybar/style.css" 2>/dev/null || true
    fi
else
    warn "No wallpaper found — run '~/.local/bin/wal-hypr.sh <image>' after first boot"
fi

# ── Laptop-only power configuration ──────────────────────────
# Both blocks below are gated on the chassis check at the top of this script.
# Previously they ran unconditionally, so a desktop got /etc/tlp.d written for
# a package it does not have installed, plus a logind lid rule for a lid that
# does not exist.
if [[ "$IS_LAPTOP" == "yes" ]]; then
    section "Configuring TLP power management"

    sudo tee /etc/tlp.d/01-laptop.conf > /dev/null <<'TLPEOF'
# Laptop power management overrides
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
TLPEOF

    success "TLP configured"

    section "Configuring lid switch behavior"

    sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/' /etc/systemd/logind.conf
    sudo sed -i 's/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf

    success "Lid close will suspend"
else
    info "Desktop chassis — skipping TLP and lid-switch configuration"
fi

# ── XDG user dirs ────────────────────────────────────────────
section "Creating XDG user directories"

sudo pacman -S --noconfirm --needed xdg-user-dirs
xdg-user-dirs-update
mkdir -p "$HOME/pics/wallpapers" "$HOME/pics/screenshots" "$HOME/projects"
success "User directories created"

# ── Ensure ~/.local/bin in PATH for this session ─────────────
export PATH="$HOME/.local/bin:$PATH"

# ── pywalfox native setup ────────────────────────────────────
section "Setting up pywalfox"

if command -v pywalfox &>/dev/null; then
    pywalfox install 2>/dev/null || warn "pywalfox install failed — run manually after opening Firefox once"
    success "pywalfox configured"
fi

# ── Firefox start page prefs ─────────────────────────────────
# user.js sets the homepage to the truenas mirror. It cannot simply be copied to
# a fixed path: Firefox generates a RANDOM profile directory name per machine
# (e.g. zjiy2i9a.default-release-...), so the default profile has to be resolved
# out of profiles.ini at install time.
#
# Firefox must have been launched at least once for the profile to exist, which
# will not be true on a fresh box — hence the skip-with-instructions path rather
# than a hard failure.
section "Configuring Firefox start page"

ff_ini="$HOME/.mozilla/firefox/profiles.ini"
if [[ -f "$ff_ini" ]]; then
    # Prefer the Install* section's Default= (an absolute-ish profile path,
    # what Firefox actually launches) over any [ProfileN] Default=1, which is
    # the legacy marker and frequently points at a stale unused profile.
    ff_rel=$(awk -F= '/^\[Install/{ini=1;next} /^\[/{ini=0} ini&&$1=="Default"{print $2;exit}' "$ff_ini")
    [[ -z "$ff_rel" ]] && ff_rel=$(awk -F= '
        /^\[Profile/{p="";d=""} $1=="Path"{p=$2} $1=="Default"&&$2=="1"{d=1}
        p&&d{print p;exit}' "$ff_ini")

    ff_profile="$HOME/.mozilla/firefox/$ff_rel"
    if [[ -n "$ff_rel" && -d "$ff_profile" ]]; then
        cp "$DOTFILES_DIR/.config/firefox/user.js" "$ff_profile/user.js"
        success "Firefox start page configured ($ff_rel)"
    else
        warn "Firefox profile not found — launch Firefox once, then copy:"
        echo "    cp $DOTFILES_DIR/.config/firefox/user.js ~/.mozilla/firefox/<profile>/user.js"
    fi
else
    warn "Firefox has never been run — launch it once, then copy:"
    echo "    cp $DOTFILES_DIR/.config/firefox/user.js ~/.mozilla/firefox/<profile>/user.js"
fi

# ── Done ─────────────────────────────────────────────────────
section "Installation complete!"

echo -e "
${GREEN}Next steps:${NC}

  1. Edit your monitor line:
     ${CYAN}nvim ~/.config/hypr/hyprland-local.conf${NC}
     Run ${CYAN}hyprctl monitors${NC} after first Hyprland boot to get the right name

  2. Set your HA token and any machine env vars:
     ${CYAN}nvim ~/.zshrc.local${NC}

  3. Reboot into Hyprland via ly:
     ${CYAN}sudo reboot${NC}

  4. After first boot, set a wallpaper to generate the full theme:
     ${CYAN}Super+Ctrl+1${NC} through ${CYAN}Super+Ctrl+8${NC}

"
