# assets — README images

Drop files here with these **exact names**; the root `README.md` references them by path.
Anything not listed here is unused.

| File | Status | What it should show |
|---|---|---|
| `example.png` | present, **stale** | Full desktop. Current file is from Nov 2025 and predates the redesign — wrong bar entirely. |
| `waybar.png` | **missing** | The bar on its own. |
| `rofi.png` | present, **stale** | App launcher (`Super + D`). Current file is Nov 2025 and predates the theme. |
| `lockscreen.png` | **missing** | `hyprlock`. |
| `neofetch.gif` | present, ok | `neo` running. Accurate, just an older palette. |

## Capturing

Everything below is `grim`, already installed. Sizes assume 3440x1440 — adjust the crops if yours differs.

**Do it on an empty workspace.** Whatever is behind a window ends up in a public repo; a stray
terminal will publish your filenames and command output. `Super + 7` (or any unused workspace) first.

```sh
# Full desktop — example.png
grim assets/example.png

# The bar alone — waybar.png. The bar is 44px tall in a 46px strip.
grim -g "0,0 3440x46" assets/waybar.png
```

The full 3440px-wide bar renders very small in a README column. A left/right pair reads better:

```sh
grim -g "0,0 1400x46"    assets/waybar-left.png
grim -g "2600,0 840x46"  assets/waybar-right.png
```

If you do that, update the root README to reference both instead of `waybar.png`.

```sh
# Launcher — rofi.png. Backgrounded so grim runs while it is up.
rofi -show drun -config ~/.config/rofi/colors-rofi.rasi & sleep 2; grim assets/rofi.png; pkill -x rofi
```

**Lock screen.** You cannot screenshot it from inside the locked session — the compositor is showing
a lock surface and `grim` will not capture past it. Two options:

1. Lock with `Super + L` and photograph the screen, then crop.
2. Render it in a nested compositor, which never locks your real session:

```sh
AQ_BACKENDS=wayland Hyprland -c /tmp/nested.conf   # exec-once = hyprlock --config ~/.config/hypr/hyprlock.conf
grim -o WAYLAND-1 assets/lockscreen.png
pkill -f "Hyprland -c /tmp/nested.conf"
```

Vertical spacing and font sizes are true to scale in the nested render; horizontal centring is not,
because the outer WM tiles the nested window narrower than the real output.

## GIFs

There is **no screen recorder installed**. Easiest fix:

```sh
sudo pacman -S wf-recorder
wf-recorder -g "$(slurp)" -f /tmp/clip.mp4     # Ctrl-C to stop
ffmpeg -i /tmp/clip.mp4 -vf "fps=15,scale=900:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" assets/out.gif
```

Without it, loop `grim` into frames and stitch them — fine for `neo`, which is just ASCII:

```sh
for i in $(seq 1 40); do grim -g "0,0 1200x800" /tmp/f$(printf %03d $i).png; sleep 0.1; done
ffmpeg -framerate 10 -i /tmp/f%03d.png -vf "scale=900:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" assets/neofetch.gif
```

Keep GIFs under ~2MB. The existing `neofetch.gif` is 1.3MB, which is a reasonable ceiling — GitHub
serves them uncompressed and they load on every page view.

## Before committing

- Confirm no window behind the shot leaks filenames, tokens, message content or window titles.
- `example.png` is currently ~3MB. Consider `magick assets/example.png -quality 85 assets/example.png`
  or resizing to 2000px wide; nothing in a README needs 3440px.
