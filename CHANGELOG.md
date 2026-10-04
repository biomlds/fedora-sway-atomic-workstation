# Changelog

All notable changes are documented here. The project follows Semantic Versioning.

## Unreleased

### Fixed

- Volume, mute, and brightness keys lost their on-screen display. The repository
  rebound all six keys to bare `brightnessctl` and `wpctl` calls with a hardcoded
  5% step, replacing Fedora's `volume-helper` and brightness snippets. Those
  snippets show the level on screen and read `$volume_limit`, `$volume_step`, and
  `$brightness_step`, none of which this repository defined. Volume and brightness
  are now delegated to `/etc/sway/config.d/60-bindings-volume.conf` and
  `60-bindings-brightness.conf`. Media keys stay rebound, since they gain the
  `--locked` workaround and have no equivalent upstream behaviour to lose.
- The volume and Waybar bindings called `wpctl`, which ships with WirePlumber.
  Nothing in `sway-config-fedora` requires WirePlumber, while `pulseaudio-utils`
  is a hard requirement, so those commands could be absent on a stock image.
  Both now use `pactl`, matching Fedora's own volume snippet.
- First installation could not complete. `host-packages.txt` listed `yadm` as a
  host package, but Fedora ships no `yadm` package in Fedora or Fedora EPEL, so
  `rpm-ostree install yadm` failed and `rpm-ostree` rejected the whole host-layer
  transaction. Because `apply` ran it unguarded under `set -e`, one bad name
  aborted the run before Flatpaks, the font, and Toolbx were reached. `yadm` is
  removed from the manifest, and `apply` now probes each name first, reports
  unresolvable packages individually, layers the remainder, and exits non-zero.
- yadm is installed as a single script pinned by commit and SHA-256 in
  `.config/fedora-sway-atomic/versions.env` instead of from a package. `apply`
  verifies the installed script against that digest and reinstalls it when it is
  missing or has drifted; `check` reports a mismatched or absent yadm.
- Documentation no longer instructs `sudo rpm-ostree install yadm`.

### Added

- Volume and brightness rows in the Architecture ownership table, plus the
  rationale for delegating them instead of restating Fedora's OSD and step
  handling locally.
- A note in Hardening and in the manifest explaining that packages the
  `sway-config-fedora` spec hard-Requires are deliberately absent, and why
  `foot`, `libnotify`, `rofi-wayland`, `dunst`, and `kanshi` still need layering.
- Pre-clone yadm installation steps in `docs/INSTALL.md` and `docs/RECOVERY.md`,
  including the digest check and the reason Fedora cannot supply yadm.
- Repository checks that reject `yadm` in the host package manifest, a stale
  `rpm-ostree install yadm` instruction, malformed yadm pins, and host manifest
  entries that are not plausible Fedora package names.

### Removed

- Seven host packages that can never be layered: `sway`, `brightnessctl`,
  `grimshot`, `playerctl`, `swayidle`, `swaylock`, and `waybar`. All seven are
  hard `Requires` of `sway-config-fedora`, so `rpm -q` always reported them as
  present. The manifest now describes 14 real layers instead of claiming 21.

## 1.1.0 - 2026-10-03

Fix a set of Sway session defects where this repository and Fedora's own Sway
snippets both claimed ownership of the same behaviour. User snippets are merged
after `/etc/sway/config.d` by Fedora's `layered-include`, so a user snippet that
rebinds without unbinding does not replace the Fedora binding; it adds to it.

### Fixed

- Media and brightness keys fired twice per press. All nine volume, mute, media,
  and brightness bindings are now preceded by an `unbindsym` that mirrors the
  flags of the Fedora binding it replaces. `sway(5)` only removes a binding
  created with the same flags, so `--locked` is mirrored where required.
- `Print` triggered both the repository's screenshot script and Fedora's
  `grimshot`. `Print` and `Super+Print` are now explicitly unbound and rebound.
- Waybar and swayidle were each started twice: once by Fedora's `90-bar.conf`
  and `90-swayidle.conf`, and again from `90-autostart-fsa.conf` after a `pkill`
  on every reload. Both are now owned by Fedora only.
- `~/.config/swayidle/config` was silently ignored, because Fedora passes idle
  timeouts on the swayidle command line. The policy is now expressed as
  `$lock_timeout` and `$screen_timeout` in a new `15-timeouts-fsa.conf`, which
  keeps the previous 5-minute lock and 10-minute screen-off behaviour.
- The Nerd Font never installed. The installer requested `SHA256SUMS`, but the
  release publishes its digests as `SHA-256.txt`, so `curl --fail` aborted the
  whole font stage.
- `stage_verify` validated `/etc/sway/config` unconditionally. It now resolves
  the effective user config when one exists, and warns when Fedora's
  `layered-include` helper is absent.
- The ShellCheck gate failed on `note`-severity findings, so the CI static job
  was red before any of these changes. The flagged patterns are rewritten.

### Changed

- The font installer verifies the archive against `NERD_FONT_SHA256` pinned in
  the repository, replacing the release-supplied checksum file it previously
  trusted. A digest published next to the artifact it protects does not protect
  it.
- `zinit` and `zsh-syntax-highlighting` are fetched by commit SHA rather than by
  tag, since a tag can be moved to point at different content.
- Toolbx pins are single-sourced in `versions.env`. CI derives its build
  arguments from that file, and `./scripts/validate-repo.sh` fails if the
  Containerfile `ARG` defaults drift from it.
- Flatpaks are installed system-wide from the Flathub system remote that Atomic
  provides by default, replacing a second per-user Flathub remote. An existing
  per-user remote is now reported as a warning.
- `grimshot` added to the host package manifest, because Fedora binds
  `Alt+Print` and `Ctrl+Print` to it and it was not installed.
- `apply` fails early with a clear message when `sudo` is unavailable.
- Theme coverage is now enforced rather than assumed. `validate-repo.sh` rejects
  any color literal that is not a Catppuccin Mocha member, and separately rejects
  a palette that still uses Mocha names but has drifted to the wrong value,
  which a membership check cannot detect. The scan understands Sway `#rrggbb`,
  `foot.ini` bare hex, `rgba()` decimals, the eight digit Rofi form, and three
  digit shorthand outside CSS.
- `README.md` no longer claims the theme applies "throughout"; it names the tools
  that cannot be themed and links to the coverage matrix.
- Neovim's colorscheme is now the official Catppuccin port instead of 15
  hand-written `nvim_set_hl` calls. The core is vendored at a pinned commit
  rather than fetched by a plugin manager, because the Toolbx image builds
  offline and a fetched theme would depend on the network and on whatever
  version happened to be current.
- Yazi's theme is now the official Catppuccin port. The previous file used
  yazi's older theme schema, which current yazi does not read, so parts of it
  were already inert; the official port uses the current schema and brings the
  full filetype and Nerd Font icon set with it.
- eza gained the official Catppuccin port at `~/.config/eza/theme.yml`, which is
  the path eza reads by default. eza was previously unthemed.
- qt5ct gained the official Catppuccin Sapphire scheme. This is the color scheme
  half of the Vorta/KeePassXC story; the environment wiring is still not applied.
- Foot now carries the `cursor`, `search-box-*` and `jump-labels` entries from
  the upstream Foot port. Upstream's off-palette selection background and its
  blue URLs are still rejected, since the accent is Sapphire.
- The palette validator understands qt5ct's `#aarrggbb` ordering, which is the
  reverse of the `#rrggbbaa` form Rofi uses. Reading it as the Rofi form turned
  every legal alpha value in the scheme into a false failure.

### Added

- `lua/catppuccin/VENDORED.md` recording the pinned Neovim commit, what was
  removed from it and why, and the command to re-vendor on upgrade.
- `CATPPUCCIN_NVIM_COMMIT` in `versions.env`, checked by the validator against
  both a full 40-character commit sha and the pin recorded in `VENDORED.md`.
- Validation that the vendored Neovim tree is still core-only and still matches
  its pin: `groups/integrations/` must be absent, `auto_integrations` must not
  be enabled without it, and `palettes/mocha.lua` must spell out all 26 Mocha
  values. The vendored files are excluded from the repository hygiene gates,
  because rewriting third-party code to satisfy a whitespace rule would make the
  pin meaningless; they are covered by the palette and pin gates instead.
- `docs/INSTALL.md` covering media verification, Secure Boot, LUKS, yadm,
  deployment, and an acceptance checklist.
- `docs/HARDENING.md` covering platform guarantees, host-footprint policy,
  sandbox review, verified supply chain, screen lock, and deliberate omissions.
- `docs/TESTED-HARDWARE.md` with a verification checklist and matrix.
- Validation that rejects Sway snippets without a `.conf` extension, which
  `layered-include` would otherwise drop without warning, and that rejects a
  reintroduced `~/.config/swayidle/config`.
- A CI secret scan over the repository history.
- An ownership table in `docs/ARCHITECTURE.md` recording which component owns
  Waybar, swayidle, screenshots, and idle timeouts, and why.
- `docs/THEMING.md` recording the palette, per-tool coverage, and the tools that
  cannot be themed from a dotfiles repository.
- `~/.gitconfig` with Mocha colors for `git diff`, `git status`, and branches.
  Git otherwise applies its own dark red and dark green defaults, which are not
  palette members.
- `~/.config/lazygit/config.yml`, taken from the official Catppuccin port at its
  Sapphire accent, plus `colorArg: always` so the Git colors survive paging
  inside LazyGit.
- VS Code settings at the path a Flatpak actually reads,
  `~/.var/app/com.visualstudio.code/config/Code/User/settings.json`, with the
  full 16 color terminal palette matching `foot.ini`. A file under
  `~/.config/Code` would never have been read.
- `~/.config/kdeglobals` with a Mocha Qt palette for applications running
  outside a sandbox. It does not affect Vorta or KeePassXC, which is documented
  rather than papered over.
- `.gitignore` and `~/.config/yadm/skip`, kept identical by a validation gate so
  that Flatpak and VS Code cache state cannot be committed in one workflow while
  silently being tracked in the other.

## 1.0.0 - 2026-09-27

- Resolve configuration management on yadm.
- Implement the Fedora Sway Atomic desktop stack with Catppuccin Mocha/Sapphire.
- Add a Fedora 44 versioned Toolbx development image.
- Replace Borgmatic with the Vorta Flatpak while retaining Borg as Vorta's engine.
- Add required and optional Flatpak manifests and online manifest validation.
- Add idempotent plan, apply, check, and verify bootstrap stages.
- Add recovery, architecture, operations, security, customization, and upstream documentation.
- Exclude Quadlet units from the production implementation.
