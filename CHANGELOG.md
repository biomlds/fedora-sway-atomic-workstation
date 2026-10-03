# Changelog

All notable changes are documented here. The project follows Semantic Versioning.

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

### Added

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
