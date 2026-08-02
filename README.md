<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>

# Chris' dotfiles

<a name="about"/>

## <samp>About</samp>

Personal dotfiles for an Arch Linux setup: a Hyprland desktop that re-themes itself from whatever wallpaper is on screen. Cyberpunk-leaning, ultrawide-first (3440x1440).

| | |
|---|---|
| Window Manager | [`hyprland`](https://github.com/hyprwm/Hyprland) |
| Terminal | [`kitty`](https://github.com/kovidgoyal/kitty) |
| Shell | [`zsh`](https://www.zsh.org/) + [`powerlevel10k`](https://github.com/romkatv/powerlevel10k/) |
| Editor | [`neovim`](https://github.com/neovim/neovim) |
| Panel | [`waybar`](https://github.com/Alexays/Waybar) |
| Launcher | [`rofi`](https://github.com/davatorium/rofi) |
| File Manager | [`yazi`](https://github.com/sxyazi/yazi) (+ [`pcmanfm`](https://github.com/lxde/pcmanfm) for GUI drag-and-drop) |
| Notifications | [`mako`](https://github.com/emersion/mako) |
| Lock Screen | [`hyprlock`](https://github.com/hyprwm/hyprlock) |
| Wallpaper | [`hyprpaper`](https://github.com/hyprwm/hyprpaper) |
| Theme Engine | [`wallust`](https://codeberg.org/explosion-mental/wallust) |

<a name="showcase"/>

## <samp>Showcase</samp>

Every colour on the desktop is derived from the current wallpaper. Pick one with `Super + W` and the bar, terminal, launcher, lock screen, notifications, GTK/Qt apps, cava and yazi all follow in one pass.

![example](assets/example.png)

<h2></h2>

### Waybar

Clipped-corner "plating" geometry, one typeface at one size, and per-module accent colours pulled from the palette. Icons are bound to their values with a size-scaled space rather than a literal one, so nothing floats.

![waybar](assets/waybar.png)

<h2></h2>

### Rofi

Based on [adi1090x/rofi](https://github.com/adi1090x/rofi). The same theme drives the app launcher, the clipboard history and the wallpaper picker — the picker only overrides row count and icon size.

![rofi](assets/rofi.png)

<h2></h2>

### Lock screen

`hyprlock`, themed from the same palette as the bar. Password only — see [Security notes](#security).

![lockscreen](assets/lockscreen.png)

<h2></h2>

### Animated fetch

PewDiePie's animated ASCII frames, recoloured to the live palette, with `fastfetch` supplying the system info. Run it with `neo`.

![neo](assets/neofetch.gif)

<h2></h2>

<a name="features"/>

## <samp>Key Features</samp>

- **Dynamic theming** — one dispatcher (`~/.local/bin/wal-hypr.sh`) runs wallust and propagates the palette to waybar, kitty, rofi, hyprlock, mako, cava, yazi, nvim, Firefox, GTK 2/3/4 and Qt/Kvantum
- **Wallpaper picker** — `Super + W` opens a rofi thumbnail grid over `~/pics/wallpapers`; drop a file in the folder and it appears, no config
- **Custom waybar** — CPU/RAM/GPU/temps, disk, a live network sparkline, weather, clipboard, update count and notification state
- **Single-instance lock** — `Super + L` goes through a `flock` wrapper so a double-press cannot spawn two lock clients (see [Security notes](#security))
- **Glyph verifier** — `waybar/scripts/verify-glyphs.py` fails the build if a Nerd Font icon has been stripped or has decayed to ASCII
- **Split config** — `hypr/conf.d/` is numbered and topic-scoped rather than one long file
- **Machine-local overrides** — `hyprland-local.conf` and `~/.config/shell/secrets.env` keep per-machine and secret values out of the repo

<a name="installation"/>

## <samp>Installation</samp>

### Prerequisites

- A fresh **Arch** or **EndeavourOS** install (no desktop environment needed)
- Internet connection
- A non-root user with `sudo`

### One-command install

```sh
bash <(curl -s https://raw.githubusercontent.com/boernerc20/dotfiles-arch/main/install.sh)
```

Or clone first:

```sh
git clone https://github.com/boernerc20/dotfiles-arch.git ~/projects/dotfiles-arch
bash ~/projects/dotfiles-arch/install.sh
```

> Do **not** run as root. The script uses `sudo` internally where needed.

### What the install script does

| Step | What happens |
|------|-------------|
| Network check | Verifies internet is available |
| System update | `pacman -Syu` |
| yay | Installs the AUR helper if not present |
| Packages | Installs everything (pacman + AUR) |
| Services | Enables NetworkManager, bluetooth, and the display manager |
| Shell | Sets `zsh` as the default shell |
| Dotfiles | Deploys all configs |
| hyprland-local.conf | Creates the machine-local monitor/GPU override file |
| Secrets | Creates `secrets.env` and `weather.env`, both empty and `0600` |
| Initial palette | Runs `wal-hypr.sh` against the first wallpaper it finds, or tells you what to run if there are none |
| Pywalfox | Installs the Firefox native connector |

Re-running it is safe: existing `secrets.env`, `weather.env`, `hyprland-local.conf` and `.zshrc.local` are left untouched.

### After the install

**1. Add wallpapers.** They are **not** bundled — they are large and personal. Put some in `~/pics/wallpapers/`, then:

```sh
~/.local/bin/wal-hypr.sh ~/pics/wallpapers/your-image.png
```

From then on `Super + W` handles it. If you install with an empty wallpaper folder the script says so and skips the palette pass rather than failing.

**2. Set your monitor.**

```sh
hyprctl monitors                              # find the name
nvim ~/.config/hypr/hyprland-local.conf       # e.g. monitor=DP-3, 3440x1440@120, 0x0, 1
```

**3. Add your secrets.** The install script creates both files empty and `0600`; you just fill them in.

```sh
nvim ~/.config/shell/secrets.env     # OPENWEATHER_API_KEY, and anything else private
nvim ~/.config/waybar/weather.env    # the SAME OpenWeatherMap key
```

**Never put a key in `.zshrc`** — that file is tracked, and doing exactly that is how two live credentials sat in this public repo for four months.

> Two files, one key. waybar is launched by Hyprland rather than from a login shell, so it never sees the shell's environment and needs its own copy. Rotating means editing **both**.

> A freshly generated OpenWeatherMap key returns `401 Invalid API key` for up to a couple of hours before it activates. That is normal — the weather module shows its alert glyph until then.

**4. Reboot**, log in, and select Hyprland.

### Manual steps

**Pywalfox** — open Firefox once, then `pywalfox install`, and add the [browser extension](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/).

**NVIDIA** — uncomment the relevant block in `~/.config/hypr/hyprland-local.conf` and install `nvidia-dkms nvidia-utils`.

<h2></h2>

<a name="keybindings"/>

## <samp>Keybindings</samp>

`Super` is the modifier throughout. Destructive actions are all on `Super + Shift` so a fat-finger cannot trigger them.

### Core

| Action | Bind |
|--------|------|
| Terminal | `Super + Return` |
| App launcher | `Super + D` |
| File manager (yazi) | `Super + E` |
| Close window | `Super + Q` |
| Toggle floating | `Super + T` |
| Fullscreen | `Super + F` |
| Clipboard history | `Super + V` |
| Colour picker | `Super + C` |
| **Wallpaper picker** | `Super + W` |
| Lock screen | `Super + L` |
| Power menu | `Super + X` |

### Power

| Action | Bind |
|--------|------|
| Power off | `Super + Shift + P` |
| Reboot | `Super + Shift + R` |
| Suspend | `Super + Shift + S` |
| Exit Hyprland | `Super + Shift + L` |

### Windows and workspaces

| Action | Bind |
|--------|------|
| Move focus | `Super + ←↑↓→` |
| Move window | `Super + Shift + ←↑↓→` |
| Resize window | `Super + Ctrl + ←↑↓→` |
| Preselect split | `Super + Alt + ←↑↓→` |
| Switch workspace | `Super + 1-0` / `Super + scroll` |
| Send to workspace | `Super + Shift + 1-0` |
| Move / resize by mouse | `Super + LMB` / `Super + RMB` |

### Layouts

| Action | Bind |
|--------|------|
| Master / dwindle | `Super + O` / `Super + Shift + O` |
| Thirds (3 columns) | `Super + G` |
| Half (50/50) | `Super + H` |
| Big + sidebar (66/33) | `Super + B` |
| Reset sizes | `Super + Shift + =` |
| Add / remove master | `Super + [` / `Super + ]` |
| Swap with master | `Super + \` |
| Cycle master position | `Super + I` |

### Screenshots

| Action | Bind |
|--------|------|
| Region → clipboard | `Print` |
| Region → file | `Super + Print` |
| Whole output → file | `Super + Shift + Print` |

<h2></h2>

<a name="customization"/>

## <samp>Customization</samp>

### Theming

`~/.local/bin/wal-hypr.sh <image>` is the single entry point. It runs wallust, then walks every consumer in order. To change what a palette colour means for a given app, edit that app's template in `~/.config/wallust/templates/` — never the rendered file in `~/.cache/wal/`, which is overwritten on every switch.

Two things to know before editing templates:

- Templates render **before** `~/.config/wal/postrun` runs. postrun clamps `color0` to near-black, so `{{color0}}` inside a template is the *unclamped* mid-grey. Use `{{background}}` for dark plates.
- An unknown `{{variable}}` renders as an **empty string** and wallust still exits 0. After editing, grep the rendered file in `~/.cache/wal/` for `:\s*;` to catch typos.

### Waybar

- `config.jsonc` — module layout
- `style-base.css` — all styling; the wallust half is prepended at runtime to build `style.css`
- `scripts/` — the custom modules

The shared plate in `style-base.css` owns padding, border, tracking and shadow. Per-module rules should set only `color` and `text-shadow`, or the pills stop reading as one bar.

Run `scripts/verify-glyphs.py` after touching any icon. It fails on stripped glyphs, missing font coverage, and icons that have decayed into ASCII.

### Network interface

The sparkline module in `config.jsonc` is pinned to an interface name — update it for your machine.

<h2></h2>

<a name="security"/>

## <samp>Security notes</samp>

**The lock screen is password-only, deliberately.** `pam_usb` is used for `sudo` and `su` on this machine, but it is explicitly *not* in `/etc/pam.d/hyprlock`. hyprlock opens its PAM conversation the moment it starts, so with `pam_usb` in that stack and the key in the port, it was granted access before it could draw the password box — the screen locked and instantly unlocked itself.

That file is owned by the hyprlock package and is in its pacman backup array, so an update ships a `.pacnew` whose pristine contents (`auth include login`) reach `pam_usb` again through `system-auth`. **Delete that `.pacnew`, do not merge it.** `~/.local/bin/lock` refuses to lock if it detects either condition.

**Always lock through `~/.local/bin/lock`**, never bare `hyprlock`. It holds a `flock` mutex for exactly hyprlock's lifetime, which is the only way to make the check atomic with the launch — a `pidof` test cannot be, because hyprlock takes about a second to appear in the process table, and two fast presses both read "not running". Two lock clients means one owns the session lock, exits, and the survivor has nothing to release.

`lock --check` runs preflight only; `lock --self-test` proves the mutex serialises. Escape hatch is `Super + Shift + L`.

<h2></h2>

<a name="structure"/>

## <samp>Repository Structure</samp>

```
dotfiles-arch/
├── .config/
│   ├── hypr/
│   │   ├── conf.d/         # numbered, topic-scoped config
│   │   └── hyprlock.conf   # generated from the wallust template
│   ├── waybar/
│   │   ├── config.jsonc
│   │   ├── style-base.css  # style.css is built at runtime, gitignored
│   │   └── scripts/        # incl. verify-glyphs.py
│   ├── wallust/
│   │   ├── wallust.toml    # 12 templates -> ~/.cache/wal/
│   │   └── templates/
│   ├── wal/postrun         # palette post-processing (GTK/Qt/Kvantum)
│   ├── shell/              # secrets.env.example
│   ├── kitty/  rofi/  mako/  yazi/  nvim/  btop/  cava/
│   ├── neofetch/           # animated ASCII frames + recolour script
│   └── wlogout/  gtk-{2,3,4}.0/  qt6ct/
├── .local/bin/             # wal-hypr.sh, lock, wallpaper-picker, ...
├── assets/                 # README screenshots
├── .zshrc_copy             # deployed as ~/.zshrc
├── .p10k.zsh
└── install.sh
```

> `wallpapers/` is **not** tracked — see [After the install](#installation).

<h2></h2>

<a name="credits"/>

## <samp>Credits</samp>

- `README.md` inspired by [HynDuf/dotfiles](https://github.com/HynDuf/dotfiles) and [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE)
- Rofi configurations based on [adi1090x/rofi](https://github.com/adi1090x/rofi)
- [r/unixporn](https://www.reddit.com/r/unixporn/) for inspiration and motivation
- [pewdiepie-archdaemon](https://github.com/pewdiepie-archdaemon) for the animated fetch frames

<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>
