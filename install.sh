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
    hyprshot
    wlogout
    xdg-desktop-portal-hyprland

    # Terminal + shell
    alacritty
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
    python-pywal
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji

    # System tools
    brightnessctl
    playerctl
    networkmanager
    network-manager-applet
    tlp
    bluez
    bluez-utils
    blueman

    # Utilities
    btop
    cava
    neofetch
    trash-cli
    jq
    wget
    curl
    rsync
    unzip
    zip

    # Browser
    firefox

    # Display manager
    ly

    # Notifications
    dunst
    libnotify

    # Screenshot deps
    grim
    slurp

    # Fonts + cursor support
    xcursor-themes

    # Clipboard
    wl-clipboard

    # AUR packages
    bibata-cursor-theme
    zsh-theme-powerlevel10k-git
    spicetify-cli
    pywalfox-native
    tty-clock
    pipes.sh
)

yay -S --noconfirm --needed \
    --answerclean None --answerdiff None \
    --answeredit None --answerupgrade None \
    "${PKGS[@]}"
success "Packages installed"

# ── Services ─────────────────────────────────────────────────
section "Enabling services"

sudo systemctl enable NetworkManager
sudo systemctl enable tlp
# Display manager — try ly, fall back to greetd
if systemctl enable ly 2>/dev/null; then
    success "ly display manager enabled"
else
    warn "ly failed, installing greetd as fallback"
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

# Config directories to deploy
CONFIG_DIRS=(
    alacritty
    btop
    cava
    gtk-2.0
    gtk-3.0
    gtk-4.0
    hypr
    neofetch
    nvim
    nwg-look
    pcmanfm
    rofi
    spicetify
    wal
    waybar
    wlogout
    xsettingsd
)

mkdir -p "$HOME/.config"

for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$DOTFILES_DIR/.config/$dir" ]]; then
        cp -r "$DOTFILES_DIR/.config/$dir" "$HOME/.config/"
        info "Deployed .config/$dir"
    fi
done

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

# Copy wallpapers from dotfiles repo
if [[ -d "$DOTFILES_DIR/wallpapers" ]]; then
    cp "$DOTFILES_DIR/wallpapers/"*.png "$HOME/pics/wallpapers/" 2>/dev/null || true
    cp "$DOTFILES_DIR/wallpapers/"*.jpg "$HOME/pics/wallpapers/" 2>/dev/null || true
    [[ -d "$DOTFILES_DIR/wallpapers/upscale" ]] && \
        cp "$DOTFILES_DIR/wallpapers/upscale/"* "$HOME/pics/wallpapers/upscale/" 2>/dev/null || true
    info "Copied wallpapers from dotfiles repo"
fi

success "Wallpapers ready at ~/pics/wallpapers"

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

# Home Assistant token:
# export HOME_ASSISTANT_TOKEN="your_token_here"

# Jarvis-only aliases (add back on jarvis):
# alias gotop='gotop --nvidia -s -a -p'
# alias reload-grub='~/.local/bin/reload-grub.sh'
# alias rgb-default='openrgb -p DEFAULT'
# alias rgb-off='openrgb -p OFF'

ZSHLOCAL
    success "Created ~/.zshrc.local"
fi

# ── Spicetify initial setup ──────────────────────────────────
section "Configuring Spicetify"

# Set prefs_path to this user's spotify prefs
SPICETIFY_CFG="$HOME/.config/spicetify/config-xpui.ini"
if [[ -f "$SPICETIFY_CFG" ]]; then
    sed -i "s|^prefs_path.*|prefs_path             = $HOME/.config/spotify/prefs|" "$SPICETIFY_CFG"
    success "Spicetify prefs_path set (run 'spicetify backup apply' after installing Spotify)"
fi

# ── Initial pywal run ────────────────────────────────────────
section "Generating initial pywal colors"

FIRST_WALLPAPER=$(find "$HOME/pics/wallpapers" -maxdepth 1 \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -1)

if [[ -n "$FIRST_WALLPAPER" ]]; then
    wal -i "$FIRST_WALLPAPER" -n && success "Pywal colors generated from $FIRST_WALLPAPER"
    # Build initial waybar style
    cat "$HOME/.cache/wal/colors-waybar.css" "$HOME/.config/waybar/style-base.css" \
        > "$HOME/.config/waybar/style.css" 2>/dev/null || true
else
    warn "No wallpaper found — run 'wal -i ~/pics/wallpapers/<image>' after first boot"
fi

# ── TLP laptop config ────────────────────────────────────────
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

# ── Lid close → suspend ──────────────────────────────────────
section "Configuring lid switch behavior"

sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf

success "Lid close will suspend"

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

${YELLOW}Note:${NC} Spotify + Spicetify must be installed manually after reboot:
  ${CYAN}yay -S spotify${NC}
  ${CYAN}spicetify backup apply${NC}
"
