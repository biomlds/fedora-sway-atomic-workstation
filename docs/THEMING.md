# Theming

The visual system is **Catppuccin Mocha** with **Sapphire** (`#74c7ec`) as the
principal accent, paired with **JetBrains Mono Nerd Font**. The palette and
accent are not a matter of taste here: they are enforced by
`scripts/validate-repo.sh`, so a color that is not a Mocha member fails
validation instead of quietly reaching your desktop.

## The palette

| Role | Name | Value | Role | Name | Value |
| --- | --- | --- | --- | --- | --- |
| Accent | sapphire | `#74c7ec` | Text | text | `#cdd6f4` |
| Accent alt | blue | `#89b4fa` | Muted text | subtext1 | `#bac2de` |
| Accent alt | mauve | `#cba6f7` | Muted text | subtext0 | `#a6adc8` |
| Accent alt | lavender | `#b4befe` | Dimmed | overlay2 | `#9399b2` |
| Accent alt | teal | `#94e2d5` | Dimmed | overlay1 | `#7f849c` |
| Accent alt | sky | `#89dceb` | Dimmed | overlay0 | `#6c7086` |
| Success | green | `#a6e3a1` | Raised surface | surface2 | `#585b70` |
| Warning | yellow | `#f9e2af` | Raised surface | surface1 | `#45475a` |
| Attention | peach | `#fab387` | Surface | surface0 | `#313244` |
| Danger | red | `#f38ba8` | Background | base | `#1e1e2e` |
| Danger alt | maroon | `#eba0ac` | Background | mantle | `#181825` |
| Warm | pink | `#f5c2e7` | Foreground on accent | crust | `#11111b` |
| Warm | flamingo | `#f2cdcd` | Highlight | rosewater | `#f5e0dc` |

Sapphire is the accent because it is the only hue that stays legible as a
foreground on `base`, `surface0`, and `crust` at once, which is what lets the
window border, the Waybar workspace pill, and Rofi's selected row all share one
color without adjusting contrast.

## Coverage

Themed by this repository:

| Layer | Tools | Config |
| --- | --- | --- |
| Compositor | Sway (borders, focus, background) | `10-theme.conf` |
| Panel | Waybar | `style.css` |
| Launchers | Rofi | `config.rasi`, `catppuccin-mocha-sapphire.rasi` |
| Notifications | Dunst | `dunstrc` |
| Lock screen | Swaylock | `config` |
| Terminal | Foot | `foot.ini` |
| Terminal UI | tmux | `tmux.conf` |
| Shell | Zsh, FZF | `.zshrc` |
| Prompt | Starship | `starship.toml` |
| Editor | Neovim | `init.lua` |
| File manager | Yazi | `theme.toml` |
| Pager | bat | `Catppuccin Mocha.tmTheme` |
| Git | diff, status, branches | `.gitconfig` |
| Git TUI | LazyGit | `config.yml` |
| Editor | VS Code | `.var/app/.../Code/User/settings.json` |
| Qt (non-Flatpak) | any Qt application | `kdeglobals` |

Two palette definitions are checked for **drift** rather than merely for valid
colors, because a value swapped for a different palette member would otherwise
pass unnoticed: `10-theme.conf` and the `[palettes.catppuccin_mocha]` block in
`starship.toml` must both spell out all 26 names with the values above.
Neovim's `mocha` table is checked the same way but may carry a subset.

## Gaps

Three things are honestly not themed, and no configuration file in this
repository can change that.

### Vorta and KeePassXC

Both are required Flatpaks and both are Qt applications, so neither picks up
`kdeglobals`:

- Flatpak redirects `XDG_CONFIG_HOME` to `~/.var/app/<app-id>/config`, so the
  file at `~/.config/kdeglobals` is not even inside the sandbox's view.
- Non-KDE Qt applications do not read `kdeglobals` at all. They need a
  `qt6ct` color scheme plus `QT_QPA_PLATFORMTHEME` set in the environment, and
  Flatpak sanitizes the environment, so the variable has to be injected per
  application.

KeePassXC additionally ships only Light, Dark, and System; it has no
Catppuccin theme and no color customization. Vorta has no dark mode at all.

The likely route, **unverified on this configuration**, is a color scheme plus:

```bash
flatpak override --user \
  --env=QT_QPA_PLATFORMTHEME=qt6ct \
  --env=QT_STYLE_OVERRIDE=fusion \
  com.borgbase.Vorta
```

This depends on the `qt6ct` platform theme plugin being present in the
application's Qt runtime, which cannot be assumed, so it is deliberately not
wired into the bootstrap. For KeePassXC, select its built-in **Dark** theme
instead; that is the reliable option.

### Brave and Obsidian

Both store their theme inside their own profile or vault, not in the home
directory, so they cannot be tracked here:

- Brave: install the [Catppuccin Mocha Brave theme](https://github.com/catppuccin/brave)
  from the extensions page for the profile in use.
- Obsidian: Settings → Appearance → Theme → browse **Catppuccin** in each vault.

## VS Code

VS Code is a Flatpak, so its user settings live at
`~/.var/app/com.visualstudio.code/config/Code/User/settings.json`. A file at
`~/.config/Code/User/settings.json` would never be read; this is the single
easiest thing to get wrong.

The theme is **not built into VS Code**. The settings file requests the theme,
but the extension must be installed once:

```bash
flatpak run com.visualstudio.code \
  --install-extension catppuccin.catppuccin-vsc
```

Until that is done, VS Code shows a warning that the requested theme is missing
and falls back to its default dark colors. The terminal palette in `settings.json`
is written out explicitly and matches `foot.ini`, so the integrated terminal is
on-palette even before the extension is present.

`catppuccin.workbenchMode` is set to `default`, which uses all three background
shades: `base` for the editor, `mantle` for the sidebar, and `crust` for the
activity and status bars. Use `flat` for two shades or `minimal` for one.

## Changing the palette

Mocha is not the only Catppuccin flavor, but substituting one means editing
every file above, and the validator will reject the result until the new
palette is recorded. To switch flavor deliberately:

1. Update the expected values in the `MOCHA` table in `scripts/validate-repo.sh`,
   renaming it to match, for example `FRAPPE`.
2. Update the `set $name` block in `10-theme.conf`.
3. Update `[palettes.catppuccin_mocha]` in `starship.toml`.
4. Update the `mocha` table in `init.lua`.
5. Run `./scripts/validate-repo.sh`.

Sway's `#rrggbb` values, `foot.ini` bare hex, `rgba()` decimals, and the eight
digit `#rrggbbaa` form used by Rofi are all understood by the validator, so a
partial edit cannot pass.

## Related

- [Customization](CUSTOMIZATION.md) for hardware and snippet conventions
- [Architecture](ARCHITECTURE.md) for session ownership
- [Installation](INSTALL.md) for the VS Code extension step and the theme checks
  in the acceptance checklist
