<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>

# Chris' dotfiles

<a name="about"/>

## <samp>About</samp>

Personal dotfiles for an EndeavourOS / Arch Linux setup featuring a fully customized Hyprland environment with Pywal dynamic theming.

- Window Manager: [`hyprland`](https://github.com/hyprwm/Hyprland)
- Terminal: [`alacritty`](https://github.com/alacritty/alacritty)
- Shell: [`zsh`](https://www.zsh.org/) with [`powerlevel10k`](https://github.com/romkatv/powerlevel10k/)
- Editor: [`neovim`](https://github.com/neovim/neovim)
- Panel: [`waybar`](https://github.com/Alexays/Waybar)
- Application Launcher: [`rofi`](https://github.com/davatorium/rofi)
- File Manager: [`pcmanfm`](https://github.com/lxde/pcmanfm) + [`yazi`](https://github.com/sxyazi/yazi)
- Display Manager: [`ly`](https://github.com/fairyglade/ly)
- Notifications: [`dunst`](https://github.com/dunst-project/dunst)
- Theme Manager: [`pywal`](https://github.com/dylanaraps/pywal)

<a name="showcase"/>

## <samp>Showcase</samp>

The colorschemes (using Pywal) are based on wallpapers in `~/pics/wallpapers/`. The colorscheme automatically changes depending on the wallpaper using the wal scripts in `.local/bin/`:

![example](assets/example.png)

<h2></h2>

### Rofi

These rofi configurations are highly based on [adi1090x/rofi](https://github.com/adi1090x/rofi)

![rofi](assets/rofi.png)

<h2></h2>

### Animated Neofetch

Used Pewdiepie's animated neofetch ASCII frames combined with static hardware descriptors:

![neo](assets/neofetch.gif)

<h2></h2>

<a name="features"/>

## <samp>Key Features</samp>

- **Dynamic Theming**: Automatic color scheme generation using Pywal — terminal, waybar, rofi, alacritty, Firefox, and cava all update together
- **Custom Waybar**: Hardware monitoring (CPU, GPU, RAM, temps), network stats, weather widget
- **Hyprland Optimizations**: VRR support, custom animations, window rules
- **Multiple Wallpaper Presets**: Quick-switch between presets via `Super+Ctrl+[1-8]`
- **Machine-local overrides**: `hyprland-local.conf` and `.zshrc.local` keep machine-specific config out of the repo
- **Laptop-ready**: TLP power management, lid-close suspend, and Bluetooth configured out of the box
- **Modern Tools**: Animated neofetch, btop, cava visualizer, yazi file manager

<a name="installation"/>

## <samp>Installation</samp>

### Prerequisites

- A fresh **EndeavourOS** install (select **no desktop environment** on the installer — minimal base is fine)
- Internet connection
- A non-root user with `sudo` access (EndeavourOS sets this up automatically)

---

### One-command install

From your fresh EndeavourOS shell, run:

```sh
bash <(curl -s https://raw.githubusercontent.com/boernerc20/dotfiles-arch/main/install.sh)
```

Or clone first and run locally:

```sh
git clone https://github.com/boernerc20/dotfiles-arch.git ~/projects/dotfiles-arch
bash ~/projects/dotfiles-arch/install.sh
```

> Do **not** run as root. The script uses `sudo` internally where needed.

---

### What the install script does

The script is fully automated and handles everything in order:

| Step | What happens |
|------|-------------|
| Network check | Verifies internet is available (`nmtui` to connect if not) |
| System update | `pacman -Syu` |
| yay | Installs the AUR helper if not present |
| Packages | Installs all packages (pacman + AUR) via `yay` |
| Services | Enables `NetworkManager`, `TLP`, `bluetooth`, and `ly` (display manager) |
| Shell | Sets `zsh` as your default shell |
| Dotfiles | Clones this repo to `~/projects/dotfiles-arch` and deploys all configs |
| Wallpapers | Copies wallpapers to `~/pics/wallpapers/` |
| hyprland-local.conf | Creates a machine-local config file for monitor + GPU overrides |
| .zshrc.local | Creates a machine-local env var file (not tracked by git) |
| Pywal | Runs an initial `wal` pass to generate color cache |
| TLP | Configures performance on AC / powersave on battery |
| Lid switch | Configures suspend on lid close |
| Pywalfox | Installs the native connector for Firefox theming |

---

### After the install — required steps

**1. Set your monitor name**

The script creates `~/.config/hypr/hyprland-local.conf` with a default laptop entry (`eDP-1`). You need to update this for your display:

```sh
nvim ~/.config/hypr/hyprland-local.conf
```

After your first Hyprland boot, run `hyprctl monitors` to find the exact display name and resolution, then update accordingly:

```
monitor=DP-1, 2560x1440@144, 0x0, 1
```

**2. Reboot**

```sh
sudo reboot
```

Log in via the `ly` display manager and select Hyprland.

**3. Apply a wallpaper theme (first boot)**

Press `Super+Ctrl+1` through `Super+Ctrl+8` to apply a preset theme. This runs Pywal, sets the wallpaper, and reloads waybar, alacritty, rofi, cava, and the terminal colors.

**4. Set machine-specific env vars (optional)**

```sh
nvim ~/.zshrc.local
```

Uncomment NVIDIA env vars if you have an NVIDIA GPU, or add a Home Assistant token, etc. This file is not tracked by git.

---

### Manual steps (post-reboot)

These cannot be automated and must be done after first boot:

**Pywalfox (Firefox theming)**

Open Firefox at least once, then:

```sh
pywalfox install
```

Install the [Pywalfox browser extension](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) from the Firefox Add-ons store.

**Weather widget**

Edit the weather script and add your [OpenWeatherMap](https://openweathermap.org/api) API key and city:

```sh
nvim ~/.config/waybar/scripts/weather.sh
```

---

### NVIDIA GPU

If you have a discrete NVIDIA GPU, uncomment the relevant lines in `~/.config/hypr/hyprland-local.conf`:

```
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GL_GSYNC_ALLOWED,1
env = __GL_VRR_ALLOWED,1
```

And in `~/.zshrc.local`:

```sh
export WLR_NO_HARDWARE_CURSORS=1
```

You will also need to install the NVIDIA driver:

```sh
yay -S nvidia-dkms nvidia-utils
```

<h2></h2>

<a name="keybindings"/>

## <samp>Hyprland Keybindings</samp>

| Action | Keybinding |
|--------|-----------|
| App launcher | `Super + D` |
| Terminal | `Super + Return` |
| Close window | `Super + Q` |
| Toggle floating | `Super + T` |
| Fullscreen | `Super + F` |
| Exit Hyprland | `Super + M` |
| File manager | `Super + E` |
| Power off | `Super + P` |
| Reboot | `Super + R` |
| Suspend | `Super + Shift + S` |
| Lock screen | `Super + L` |
| Switch wallpaper theme | `Super + Ctrl + [1-8]` |
| Screenshot region | `Print` |
| Screenshot monitor | `Super + Print` |

<h2></h2>

<a name="customization"/>

## <samp>Customization</samp>

### Changing Themes

Use `Super+Ctrl+[1-8]` to switch between wallpaper presets. Each preset runs `wal-hypr.sh` which:

1. Sets the wallpaper via `hyprpaper`
2. Generates a color palette with Pywal
3. Reloads waybar, alacritty, rofi, cava, and ly colors

To use a custom wallpaper:

```sh
~/.local/bin/wal-hypr.sh /path/to/wallpaper.png
```

### Monitor Configuration

Edit `~/.config/hypr/hyprland-local.conf` (this file is not tracked by git):

```
monitor=DP-1, 2560x1440@144, 0x0, 1
```

Run `hyprctl monitors` inside a Hyprland session to list connected displays.

### Waybar Modules

- `~/.config/waybar/config.jsonc` — module layout and configuration
- `~/.config/waybar/style-base.css` — base styles (Pywal overlays on top)
- `~/.config/waybar/scripts/` — custom scripts (weather, hardware stats, etc.)

Update the network interface name in `config.jsonc` if needed (default: `eno1` ethernet, `wlp4s0` wifi).

<h2></h2>

<a name="notes"/>

## <samp>Important Notes</samp>

- **ly display manager**: If `ly` fails to enable (rare), the script automatically installs `greetd` + `tuigreet` as a fallback
- **GPU Monitoring**: The hardware waybar script uses `nvidia-smi`. For AMD GPUs, modify `~/.config/waybar/scripts/hardware.sh`
- **Wallpaper path**: Wallpapers live at `~/pics/wallpapers/` (not `~/Pictures/Wallpapers/`)
- **Machine-local files**: `~/.config/hypr/hyprland-local.conf` and `~/.zshrc.local` are generated by the install script and are not tracked by git — safe to customize freely

<h2></h2>

<a name="structure"/>

## <samp>Repository Structure</samp>

```
dotfiles-arch/
├── .config/
│   ├── hypr/           # Hyprland configuration
│   ├── waybar/         # Waybar config and scripts
│   ├── alacritty/      # Terminal config
│   ├── rofi/           # App launcher themes
│   ├── neofetch/       # Animated neofetch config
│   ├── btop/           # System monitor
│   ├── cava/           # Audio visualizer
│   ├── nvim/           # Neovim configuration
│   ├── wal/            # Pywal templates
│   ├── wlogout/        # Logout screen
│   ├── gtk-{2,3,4}.0/  # GTK theming
│   └── nwg-look/       # GTK appearance tool
├── .local/bin/         # Custom scripts (wal-hypr, wal-rofi, etc.)
├── wallpapers/         # Bundled wallpapers
├── assets/             # README screenshots
├── .zshrc_copy         # Zsh configuration (deployed as ~/.zshrc)
├── .p10k.zsh           # Powerlevel10k prompt config
├── .gtkrc-2.0          # GTK2 theming
└── install.sh          # Automated setup script
```

<h2></h2>

<a name="credits"/>

## <samp>Credits</samp>

- `README.md` inspired by [HynDuf/dotfiles](https://github.com/HynDuf/dotfiles) and [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE)
- Rofi configurations based on [adi1090x/rofi](https://github.com/adi1090x/rofi)
- [r/unixporn](https://www.reddit.com/r/unixporn/) for inspiration and motivation
- [pewdiepie/archdaemon](https://github.com/pewdiepie-archdaemon) for the animated Neofetch

<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>
