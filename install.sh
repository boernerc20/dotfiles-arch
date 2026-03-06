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

# ── Core packages ────────────────────────────────────────────
section "Installing core packages"

PACMAN_PKGS=(
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
    git
    base-devel
    jq
    wget
    curl
    rsync
    unzip
    zip

    # Display manager
    ly

    # Notifications
    dunst
    libnotify

    # Screenshot deps
    grim
    slurp
)

sudo pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}"
success "Core packages installed"

# ── AUR helper (yay) ─────────────────────────────────────────
section "Installing yay (AUR helper)"

if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    cd /tmp/yay-install && makepkg -si --noconfirm
    cd ~ && rm -rf /tmp/yay-install
    success "yay installed"
else
    success "yay already installed"
fi

# ── AUR packages ─────────────────────────────────────────────
section "Installing AUR packages"

AUR_PKGS=(
    bibata-cursor-theme
    powerlevel10k
    spicetify-cli
    pywalfox-native
    tty-clock
    pipes.sh
)

yay -S --noconfirm --needed "${AUR_PKGS[@]}"
success "AUR packages installed"

# ── Services ─────────────────────────────────────────────────
section "Enabling services"

sudo systemctl enable NetworkManager
sudo systemctl enable tlp
sudo systemctl enable ly
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

mkdir -p "$HOME/pics/wallpapers"

# Copy rofi wallpapers from dotfiles
if [[ -d "$DOTFILES_DIR/.config/rofi/img" ]]; then
    cp "$DOTFILES_DIR/.config/rofi/img/"* "$HOME/pics/wallpapers/"
    info "Copied wallpapers from dotfiles"
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

ZSHLOCAL
    success "Created ~/.zshrc.local"
fi

# ── Initial pywal run ────────────────────────────────────────
section "Generating initial pywal colors"

FIRST_WALLPAPER=$(find "$HOME/pics/wallpapers" -name "*.png" -o -name "*.jpg" | head -1)

if [[ -n "$FIRST_WALLPAPER" ]]; then
    wal -i "$FIRST_WALLPAPER" -n 2>/dev/null && success "Pywal colors generated from $FIRST_WALLPAPER"
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

# ── Done ─────────────────────────────────────────────────────
section "Installation complete!"

echo -e "
${GREEN}Next steps:${NC}

  1. Edit your monitor line:
     ${CYAN}nvim ~/.config/hypr/hyprland-local.conf${NC}
     Run ${CYAN}hyprctl monitors${NC} after first Hyprland boot to get the right name

  2. Set your HA token and any machine env vars:
     ${CYAN}nvim ~/.zshrc.local${NC}

  3. Reboot and Hyprland will start via ly:
     ${CYAN}sudo reboot${NC}

  4. After first boot, set a wallpaper to generate full theme:
     ${CYAN}Super+Ctrl+1${NC} through ${CYAN}Super+Ctrl+8${NC}

${YELLOW}Note:${NC} Spotify + Spicetify must be installed manually from AUR after reboot:
  ${CYAN}yay -S spotify${NC}
  ${CYAN}spicetify backup apply${NC}
"
