# Hardware customization

The committed Kanshi profile is intentionally hardware-neutral and enables every connected output. Keep a working fallback while adding serial-specific profiles.

## Discover output identifiers

From Sway:

```bash
swaymsg -t get_outputs
kanshictl list
```

Prefer make, model, and serial criteria over connector names when docking changes connector numbering. Do not commit organizational asset identifiers to a public repository.

## Example personal Kanshi profile

Add a private yadm alternate or an untracked local include based on the actual output criteria:

```text
profile mobile {
    output "Laptop Panel Description" mode 1920x1200@60Hz position 0,0 scale 1.25
}

profile desk {
    output "Laptop Panel Description" disable
    output "External Display Description" mode 2560x1440@60Hz position 0,0 scale 1.0
}
```

Validate with `kanshi -c ~/.config/kanshi/config` in a graphical session. Keep a terminal available before disabling an internal panel.

## Keyboard layout

The tracked layout is US. Change `xkb_layout`, and optionally `xkb_variant` and `xkb_options`, in `.config/sway/config.d/20-input.conf`. Reload Sway with `Super+Shift+C`.

## Idle and screen-lock timeouts

Change `$lock_timeout` and `$screen_timeout` in `.config/sway/config.d/15-timeouts-fsa.conf`, then reload Sway. Fedora's `/etc/sway/config.d/90-swayidle.conf` reads them and falls back to 300/60 when they are unset.

Do not create `~/.config/swayidle/config`. Fedora passes the timeouts on the swayidle command line, so that file is never read. `./scripts/validate-repo.sh` fails if it reappears.

## Sway snippet conventions

User snippets live in `~/.config/sway/config.d` and are merged by Fedora's
`layered-include` helper after `/etc/sway/config.d`. Two rules follow from that:

- Name every snippet `*.conf`. The helper's glob matches nothing else and the file is dropped without any error.
- `unbindsym` only removes a binding created with the same flags. Mirror `--locked` when unbinding a `--locked` binding.

If a setting appears to have no effect, check which component owns it first: Waybar, swayidle, and the Alt/Ctrl+Print screenshots are owned by Fedora. See the ownership table in [Architecture](ARCHITECTURE.md).

## Scaling and font size

- Sway output scale belongs in Kanshi.
- Waybar font size is in `.config/waybar/style.css`.
- Foot font size is in `.config/foot/foot.ini`.
- Rofi font size is in `.config/rofi/config.rasi`.

Change related values together and verify Nerd Font icons remain aligned.

## Colors and theme

The palette is Catppuccin Mocha with the Sapphire accent, and it is enforced by
`./scripts/validate-repo.sh`. Any color literal that is not a Mocha member fails
validation, so a hex typo in a snippet is caught before it reaches the desktop
rather than after.

This also constrains what you can do. A new snippet that needs a color has to
reuse a palette member, and `10-theme.conf` must keep defining all 26 names with
their canonical values. Substituting a different Catppuccin flavor means
editing the validator's expected table along with the configs, which
[Theming](THEMING.md) walks through.

Several tools use the official Catppuccin ports rather than local files. Those
should not be restyled here: edit them only where
[Theming](THEMING.md#official-ports-and-the-edits-made-to-them) already lists a
documented substitution, because every other color in them is upstream's and is
expected to change when the upstream port does. The Neovim port is byte-pinned,
so its only editable file is `.config/nvim/init.lua`.

## Optional Flatpaks

Review `.config/fedora-sway-atomic/flatpaks-optional.txt`, remove applications you do not want, then run:

```bash
workstation-bootstrap plan --with-optional
workstation-bootstrap apply --with-optional
```

The required manifest should remain small and recovery-focused.
