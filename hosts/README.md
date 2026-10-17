# Per-machine overrides

The packages at the repo root (`i3/`, `alacritty/`, …) hold the config that is
the same everywhere. Anything that depends on the actual hardware — monitor
layout, brightness control, font size, audio device — lives here instead, under
a directory named after the machine's `hostname`.

```
hosts/
  ronaldo-20fwa023cd/          # ThinkPad T460p, eDP-1 1920x1080
    .config/dotfiles-host/
      i3.conf                  # brightness via `light`
      alacritty.toml           # font size 10
  desktop-hdmi/                # rename to that machine's hostname
    .config/dotfiles-host/
      i3.conf                  # xrandr HDMI-0 2560x1440, ddcutil, edid-check
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

So a machine with no `hosts/` directory of its own still gets a working setup
from the generic config alone — the overrides are purely additive.

The i3 include sits at the very **end** of the config on purpose: i3 lets a
later `bindsym` replace an earlier one, so a host can rebind any key. What a
host cannot do is *remove* an `exec` line — that is why the desktop's `xrandr`,
`edid-check` and `ddcutil` lines were moved out of the generic config into
`hosts/desktop-hdmi/` rather than being overridden in place.

polybar deliberately has no hook: it aborts on a missing `include-file`, and its
config already auto-adapts (`monitor =` empty picks the primary output,
`card = intel_backlight`, `battery = BAT0`).

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
