# Per-machine overrides

The packages at the repo root (`i3/`, `alacritty/`, …) detect hardware at runtime:
monitor modes, CPU/GPU sensors, batteries, backlights and the active network route.
This directory is for preferences detection cannot infer — for example terminal
font size or a preferred monitor arrangement — under the machine's `hostname`.

```
hosts/
  ronaldo-20fwa023cd/          # ThinkPad T460p, eDP-1 1920x1080
    .config/dotfiles-host/
      i3.conf                  # optional i3 preferences
      alacritty.toml           # font size 10
      appimage.env             # AppImages in ~/Tools (no /mnt/data disk)
  ronaldo-ms7c94/              # desktop, HDMI-0 2560x1440
    .config/dotfiles-host/
      i3.conf                  # optional i3 preferences
      alacritty.toml           # font size 14
```

## How it works

`bin/dotfiles-bootstrap` stows the generic packages into `$HOME`, then stows
`hosts/$(hostname)` on top. Both end up pointing at this repo, so a change on
any machine is a normal commit.

Everything a host can override is funnelled through one directory,
`~/.config/dotfiles-host/`, which each generic config pulls in at the end:

| Config | Hook | Behaviour when the file is absent |
|---|---|---|
| `i3/.config/i3/config` | `include ~/.config/dotfiles-host/i3.conf` | silently skipped (verified on i3 4.25) |
| `alacritty/…/alacritty.toml` | last entry of `general.import` | silently skipped |
| `mpd/.config/mpd/mpd.conf` | `include_optional "…/mpd.conf"` | silently skipped (needs mpd ≥ 0.22) |
| `zsh/.zshrc` | `[[ -r … ]] && source` | silently skipped |
| `i3/.config/i3/bin/i3bar` | sources `~/.config/dotfiles-host/bar.env` | silently skipped; built-in `BAR_LEFT` default applies |
| `i3/.config/i3/bin/appimage`, `appimage-menu` | source `~/.config/dotfiles-host/appimage.env` | silently skipped; `APPIMAGE_DIR` defaults to `/mnt/data/Tools` |

`appimage.env` works the same way: it sets `APPIMAGE_DIR`, the directory that
`bin/appimage` searches for the `Alt+Ctrl+…` AppImage key bindings. The desktop keeps
its AppImages on `/mnt/data/Tools` and has no `appimage.env`; the ThinkPad has no
`/mnt/data` disk and points it at `$HOME/Tools`. Use this rather than rebinding
the keys in a host `i3.conf` (which i3 would reject as duplicates, see below).

`bar.env` is a shell fragment, not a Polybar config: Polybar aborts on a missing
`include-file`, so the bar is customised through the environment instead.
`modules-left/center/right` all read `${env:BAR_*:default}`, and `bin/i3bar`
exports them. A host sets `BAR_LEFT` there to change the left-hand modules --
the ThinkPad swaps `gpu_temp` for `gpu`, because its Skylake iGPU has no hwmon
directory, so `hardware gpu-temp` prints nothing, Polybar renders no module, and
the click target that opens the GPU card disappears with it.

### The alacritty trap

`import` does **not** work like i3's `include`: the importing file is resolved
last, so a key set in `alacritty.toml` beats the same key in an imported file.
Verified on 0.17 — with `window.title` set in both, the main file's value is the
one the window gets; comment it out and the import's value appears.

So for alacritty a key is overridable from `hosts/` **only if the generic config
does not set it at all**. That is why `alacritty.toml` carries no `[font] size`
(it lives in the host files) and no palette (it lives in `colors.toml`).
Adding `size = …` back to the generic file would silently disable every host's
font size.

So a machine with no `hosts/` directory of its own still gets a working setup
from the generic config alone — the overrides are purely additive.

The i3 include sits at the very **end** of the config, but a host **cannot rebind** a
key the generic config already binds: i3 does not let a later `bindsym` replace an
earlier one, it reports a duplicate keybinding as a config error (`i3 -C` prints
`ERROR: Duplicate keybinding`, verified on 4.25.1) and shows the error bar. So a
host `i3.conf` may only bind keys that are free in the generic config. When a key
has to behave differently per machine, decide at run time inside the generic binding
instead — e.g. `Alt+Ctrl+D` runs `doublecmd` when the package is installed and falls
back to the AppImage otherwise, and the AppImage keys read the host's `appimage.env`.
Nor can a host *remove* an `exec` line — so the generic config only runs things
that are right (or harmless) everywhere: `bin/display` picks each monitor's preferred
mode at its highest refresh rate, and `edid-check` exits silently without the
pinned-EDID xorg file. Brightness keys use the generic `bin/brightness`: an
automatically detected internal panel via brightnessctl/light, otherwise DDC/CI.

Polybar deliberately has no host include: it aborts on a missing `include-file`.
`bin/i3bar` starts it for every distinct active screen area, with media and the
tray on the primary output. `bin/hardware` supplies a shared, cached snapshot to
all bars and Conky. There are no fixed battery, adapter, network or backlight IDs.
Unsupported readings disappear; sleeping GPUs are not queried. No host package
is needed when moving these configs to another CPU/GPU or laptop.

## Adding a machine

```sh
mkdir -p hosts/$(hostname)/.config/dotfiles-host
# write i3.conf / alacritty.toml / mpd.conf / zshrc as needed
bin/dotfiles-bootstrap -R
```

`DOTFILES_HOST=other-box bin/dotfiles-bootstrap -n` dry-runs another host's
setup without touching anything.

## Why there is no `.stowrc`

It used to contain `--target=/home/ronaldo`, which breaks under any other
username or clone path. `bin/dotfiles-bootstrap` resolves both `$HOME` and the
repo location at run time instead. Use the script rather than calling `stow`
directly.
