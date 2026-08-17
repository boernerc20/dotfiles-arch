<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>

# Chris' dotfiles

<a name="about"/>

## <samp>About</samp>

Personal dotfiles for an Arch Linux desktop: Hyprland that re-themes itself from whatever wallpaper is on screen. Cyberpunk-leaning, built around a 3440x1440 ultrawide. This is what I actually run — a showcase of the setup, not a tutorial for building your own. Everyone's hardware, drivers and partition layout differ enough that a copy-paste install script would be irresponsible advice; see [Installation](#installation) for what that means in practice here.

Synced to one other machine — a laptop — via `dotfiles-sync`, so the desktop stays the source of truth and the laptop follows.

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

### In motion

`Super + W`, pick a new wallpaper, and the whole desktop repaints in one pass.

![demo](assets/demo.gif)

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
- **Custom waybar, hardware-aware** — CPU/RAM/temp plus GPU power draw or battery percentage, whichever the machine actually has (auto-detected, not hardcoded); disk, a live network sparkline (interface auto-detected too) and weather. The desktop and laptop run two different module layouts from the same repo — see `config.jsonc` vs `config-laptop.jsonc`
- **Single-instance lock** — `Super + L` goes through a `flock` wrapper so a double-press cannot spawn two lock clients (see [Security notes](#security))
- **Glyph verifier** — `waybar/scripts/verify-glyphs.py` fails the build if a Nerd Font icon has been stripped or has decayed to ASCII
- **Split config** — `hypr/conf.d/` is numbered and topic-scoped rather than one long file
- **Machine-local overrides** — `hyprland-local.conf` (now actually sourced — see its own comment in `hyprland.conf`) and `~/.config/shell/secrets.env` keep per-machine and secret values out of the repo
- **One-command sync** — `dotfiles-sync` pulls, redeploys every tracked config, and installs anything a pull newly depends on; see [Keeping machines in sync](#sync)

<a name="installation"/>

## <samp>Installation</samp>

This isn't written as a general install guide. No two systems agree on partitioning, drivers or desktop-environment assumptions closely enough for a copy-paste script to be responsible advice, and that's not what this repo is for — it's a record of one specific desktop, not a distro.

`install.sh` exists to keep this repo's one other machine — a laptop — in line with this one. See [Keeping machines in sync](#sync) for how that actually works day to day. If you're curious what a fresh run does, the script is meant to be read, not just executed — every step is commented with why it exists, not just what it does.

<a name="sync"/>

## <samp>Keeping machines in sync</samp>

```sh
dotfiles-sync
```

Pulls the latest commit, redeploys every tracked `.config/` entry, and installs anything a new commit newly depends on (`install.sh` is idempotent — re-running it never touches `secrets.env`, `weather.env`, `hyprland-local.conf` or `.zshrc.local`, and every package install is `--needed`). The desktop is the source of truth; the laptop pulls, it never pushes configuration back.

Two things stay genuinely per-machine and are never synced:

- **`hyprland-local.conf`** — monitor, touchpad, GPU env, machine-only autostart. Generated once by `install.sh`, gitignored, and sourced last so it overrides everything else — see the comment above its `source` line in `hyprland.conf`.
- **Secrets** — `~/.config/shell/secrets.env` and `~/.config/waybar/weather.env` both carry the same OpenWeatherMap key; waybar is launched by Hyprland rather than a login shell, so it never sees the shell's environment and needs its own copy. Rotating the key means editing **both**, on **every** machine. Never put a key in `.zshrc` — that file is tracked, and doing exactly that is how two live credentials sat in this public repo for four months.

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

`Super + Alt` is the only layout-preset prefix — every preset in one place, nothing to remember across two modifiers.

| Action | Bind |
|--------|------|
| Master / dwindle | `Super + O` / `Super + Shift + O` |
| Full width (1 column) | `Super + Alt + 1` |
| Half (50/50) | `Super + Alt + 2` |
| Thirds (3 columns) | `Super + Alt + 3` |
| Quarters (4 columns) | `Super + Alt + 4` |
| 66/33, main on left | `Super + Alt + E` |
| 33/66, main on right | `Super + Alt + R` |
| 25/50/25, focus centred | `Super + Alt + C` |
| Golden ratio (62/38) | `Super + Alt + G` |
| Reset to equal sizes | `Super + Alt + 0` |
| Add / remove master | `Super + [` / `Super + ]` |
| Swap with master | `Super + \` |
| Cycle master position | `Super + I` |

### Windows

| Action | Bind |
|--------|------|
| Toggle scratchpad | `Super + B` |
| Send window to scratchpad | `Super + Shift + B` |
| Toggle window group (tabs) | `Super + G` |
| Cycle group tabs | `Super + Shift + G` |
| Pin window (floating only) | `Super + H` |
| Dismiss top notification | `Super + Shift + =` |
| Dismiss all notifications | `Super + Shift + -` |

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

### Machine-specific hardware

Two things auto-detect at runtime rather than being hardcoded, so the same script runs correctly on both machines with no per-machine fork:

- **`hardware.sh`**'s fourth field — GPU power draw if `nvidia-smi` exists, battery percentage if `/sys/class/power_supply/BAT0` exists, nothing if neither does
- **`net-sparkline.py`** — reads the default-route interface out of `/proc/net/route` (`net-sparkline.py auto` in `config.jsonc`) rather than a hardcoded NIC name

**`~/.local/bin/brightness`** picks the right control path the same way: `brightnessctl` if `/sys/class/backlight` has an entry (a real laptop panel), DDC/CI over `~/.local/bin/monitor-brightness` if not (an external monitor with its own scaler — see that script's header for why a naive version is unusable: bus caching, a non-blocking lock, ~330ms per write).

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
│   │   ├── conf.d/              # numbered, topic-scoped config
│   │   └── hyprlock.conf        # generated from the wallust template
│   ├── waybar/
│   │   ├── config.jsonc         # desktop layout
│   │   ├── config-laptop.jsonc  # laptop layout — install.sh picks one by chassis
│   │   ├── style-base.css       # shared; style.css is built at runtime, gitignored
│   │   └── scripts/             # incl. verify-glyphs.py, hardware.sh, net-sparkline.py
│   ├── wallust/
│   │   ├── wallust.toml         # 14 templates -> ~/.cache/wal/
│   │   └── templates/
│   ├── wal/postrun              # palette post-processing (GTK/Qt/Kvantum)
│   ├── Kvantum/                 # LayanDark theme, patched per-palette by postrun
│   ├── shell/                   # secrets.env.example
│   ├── kitty/  rofi/  mako/  yazi/  nvim/  btop/  cava/
│   ├── neofetch/                # animated ASCII frames + recolour script
│   └── wlogout/  gtk-{2,3,4}.0/  qt6ct/
├── .local/bin/                  # wal-hypr.sh, lock, brightness, wallpaper-picker, ...
├── assets/                      # README screenshots
├── .zshrc_copy                  # deployed as ~/.zshrc
├── .p10k.zsh
└── install.sh
```

Everything under `.config/` that `install.sh` deploys is enumerated straight from `git ls-files` at run time — not a hand-kept list — so this tree is illustrative, not exhaustive; run `git ls-files .config/` for the real current set.

> `wallpapers/` is **not** tracked — large and personal. `install.sh` degrades gracefully with none present; drop some in `~/pics/wallpapers/` and `Super + W` picks them up.

<h2></h2>

<a name="credits"/>

## <samp>Credits</samp>

- `README.md` inspired by [HynDuf/dotfiles](https://github.com/HynDuf/dotfiles) and [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE)
- Rofi configurations based on [adi1090x/rofi](https://github.com/adi1090x/rofi)
- [r/unixporn](https://www.reddit.com/r/unixporn/) for inspiration and motivation
- [pewdiepie-archdaemon](https://github.com/pewdiepie-archdaemon) for the animated fetch frames

<h2 align="center"> ━━━━━━  ❖  ━━━━━━ </h2>
