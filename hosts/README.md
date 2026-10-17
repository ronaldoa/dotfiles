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

The i3 include sits at the very **end** of the config on purpose: i3 lets a
later `bindsym` replace an earlier one, so a host can rebind any key. What a
host cannot do is *remove* an `exec` line — so the generic config only runs things
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
