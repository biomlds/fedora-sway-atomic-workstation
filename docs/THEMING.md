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

Themed by this repository. "Official port" means the file is taken from the
[Catppuccin organisation](https://github.com/catppuccin) rather than written
here, so it tracks upstream instead of drifting; "local" means this repository
owns the values.

| Layer | Tool | Config | Source |
| --- | --- | --- | --- |
| Compositor | Sway (borders, focus, background) | `10-theme.conf` | local |
| Panel | Waybar | `style.css` | local |
| Launchers | Rofi | `config.rasi`, `catppuccin-mocha-sapphire.rasi` | local |
| Notifications | Dunst | `dunstrc` | local |
| Lock screen | Swaylock | `config` | local |
| Terminal | Foot | `foot.ini` | local, on the official palette |
| Terminal UI | tmux | `tmux.conf` | local |
| Shell | Zsh, FZF | `.zshrc` | local |
| Prompt | Starship | `starship.toml` | local |
| Editor | Neovim | `init.lua` + `lua/catppuccin/` | **official port**, vendored |
| File manager | Yazi | `theme.toml` | **official port** |
| File listing | eza | `~/.config/eza/theme.yaml` | **official port** |
| Pager | bat | `Catppuccin Mocha.tmTheme` | **official port** |
| Git | diff, status, branches | `.gitconfig` | local |
| Git TUI | LazyGit | `config.yml` | **official port** |
| Editor | VS Code | `.var/app/.../Code/User/settings.json` | **official port** |
| Qt (non-Flatpak) | any Qt5 application | `qt5ct/qt5ct.conf` + `colors/…` | **official port** |
| Qt (KDE apps) | any KDE application | `kdeglobals` | local |

### Official ports and the edits made to them

Five files are taken from upstream. Three needed a change to keep the
repository strictly palette-only; the rest are verbatim.

| File | Upstream | Change |
| --- | --- | --- |
| `lua/catppuccin/` | [catppuccin/nvim](https://github.com/catppuccin/nvim) @ `edefef77` | `groups/integrations/` dropped; see below |
| `theme.toml` (Yazi) | [catppuccin/yazi](https://github.com/catppuccin/yazi) | `syntect_theme` removed; `progress_label` white → `text` |
| `theme.yaml` (eza) | [catppuccin/eza](https://github.com/catppuccin/eza) | none; renamed, see below |
| `config.yml` (LazyGit) | [catppuccin/lazygit](https://github.com/catppuccin/lazygit) | none |
| `colors/…sapphire.conf` (qt5ct) | [catppuccin/qt5ct](https://github.com/catppuccin/qt5ct) | four values mapped onto the palette |

Four of these deserve spelling out.

**eza only parses one of its two theme filenames.** In
`src/options/theme.rs`, `ThemeConfig::deduce` probes `theme.yml` first and, if
it finds one, returns `ThemeConfig::default()` *without reading it*. Only the
`theme.yaml` branch calls `from_path` and actually loads the file. A perfectly
maintained `theme.yml` therefore renders as eza's stock colours and produces no
error anywhere, which is why the file here is `theme.yaml` even though the port
ships `.yml` and eza's own changelog treats `theme.yml` as canonical. Both names
are probed with `.yml` first, so a leftover `theme.yml` would shadow the real
theme rather than be ignored. `scripts/validate-repo.sh` rejects that name.

**Neovim is vendored, not installed.** The Toolbx image is built offline, so a
plugin manager fetching a colorscheme at build time would make the theme
depend on the network and on whatever version happened to be current. The core
is copied into `.config/nvim/lua/catppuccin/` at the commit recorded as
`CATPPUCCIN_NVIM_COMMIT` in `versions.env`, and it is byte-identical to
upstream; `lua/catppuccin/VENDORED.md` records the pin and the upgrade command.
`groups/integrations/` was deleted because no plugin that those files theme is
installed, and `init.lua` sets `auto_integrations = false` so they would never
be loaded anyway. That removes 288 KiB of dead code.

**qt5ct writes `#AARRGGBB`, not `#RRGGBBAA`.** Two hex digits of alpha come
first. The validator knows the difference, and four upstream values are not
Mocha colours, so they are mapped onto the nearest palette entry: pure white →
`text`, a desaturated `subtext0` → `overlay0`, and a desaturated `surface2` →
`surface1`. The one semi-transparent entry, alpha `80` over `overlay0`, is kept
as-is because the translucency is the point.

**Sway, Foot, tmux, Waybar and Rofi have no Sapphire port.** Upstream ships a
single blue-accent file for each of these, so adopting them wholesale would
replace the Sapphire accent that the rest of the desktop is built on. They stay
local, on the official palette, and adopt upstream values selectively where they
are genuinely better: `foot.ini` now carries upstream's `cursor`,
`search-box-*` and `jump-labels` entries. Upstream's Foot selection background
is off-palette and upstream's tmux port swaps `subtext0` and `subtext1`; both
are rejected.

Two palette definitions are checked for **drift** rather than merely for valid
colors, because a value swapped for a different palette member would otherwise
pass unnoticed: `10-theme.conf` and the `[palettes.catppuccin_mocha]` block in
`starship.toml` must both spell out all 26 names with the values above. The
vendored `lua/catppuccin/palettes/mocha.lua` is checked the same way, and must
carry all 26. Every other theme file is only checked for palette membership.

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

The palette for the qt5ct route now ships, at
`~/.config/qt5ct/colors/catppuccin-mocha-sapphire.conf` with
`~/.config/qt5ct/qt5ct.conf` selecting it. What is still missing is the wiring,
and that is deliberate. The likely route, **unverified on this configuration**,
is:

```bash
flatpak override --user \
  --env=QT_QPA_PLATFORMTHEME=qt6ct \
  --env=QT_STYLE_OVERRIDE=fusion \
  com.borgbase.Vorta
```

This depends on the `qt6ct` platform theme plugin being present in the
application's Qt runtime, which cannot be assumed, so it is deliberately not
wired into the bootstrap. Note also that the theme file is a **qt5ct** scheme;
whether a given application links Qt5 or Qt6 decides whether it can read it at
all, and that was not determined here. For KeePassXC, select its built-in
**Dark** theme instead; that is the reliable option.

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
4. Re-vendor the Neovim core, or accept that Neovim keeps the old flavor.
5. Update the four substituted values in the Yazi and qt5ct ports, which are
   hand-edited precisely so that they stay in-palette.
6. Run `./scripts/validate-repo.sh`.

Sway's `#rrggbb` values, `foot.ini` bare hex, `rgba()` decimals, the eight digit
`#rrggbbaa` form used by Rofi, and the eight digit `#aarrggbb` form used by
qt5ct are all understood by the validator, so a partial edit cannot pass.

## Related

- [Customization](CUSTOMIZATION.md) for hardware and snippet conventions
- [Architecture](ARCHITECTURE.md) for session ownership
- [Installation](INSTALL.md) for the VS Code extension step and the theme checks
  in the acceptance checklist
