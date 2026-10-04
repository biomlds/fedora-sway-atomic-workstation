# Fedora Sway Atomic Workstation

A production-oriented, reproducible workstation repository for **Fedora Sway Atomic**. The repository is a native [yadm](https://yadm.io/) worktree: files under `.config`, `.local`, and the home-directory dotfiles are checked out directly into the user's home directory.

The implementation keeps the immutable host small, installs GUI applications as Flatpaks, and places the development CLI in a versioned Toolbx image. It uses Catppuccin Mocha with the Sapphire accent and JetBrains Mono Nerd Font across every tool that supports theming, and the palette is enforced by the validator rather than left to convention. See [theming](docs/THEMING.md) for coverage and the known gaps.

## What is included

- Fedora's Sway, Waybar, Rofi, Dunst, Foot, Kanshi, Swaylock, and Swayidle stack.
- Cohesive Catppuccin Mocha/Sapphire configuration for the desktop and terminal tools, including Git, LazyGit, and the VS Code integrated terminal.
- Official Catppuccin ports where the upstream project publishes one, vendored or pinned rather than fetched at runtime: Neovim, Yazi, eza, LazyGit, bat, VS Code, and qt5ct.
- A Fedora 44 Toolbx image containing Zsh, Zinit, Deja, zsh-syntax-highlighting, FZF, eza, bat, ripgrep, Neovim, LazyGit, tmux, Yazi, Starship, mise, jq, and tree.
- Required and optional Flatpak manifests installed system-wide from Flathub. Vorta is the backup client; Borgmatic is deliberately not installed.
- Idempotent `plan`, `apply`, `check`, and `verify` bootstrap stages.
- Installation, hardening, recovery, operations, security, architecture, customization, and hardware documentation.
- Static validation and CI, including a Toolbx image build smoke test and a repository history secret scan.

## Repository target

This repository is prepared for:

```text
https://github.com/biomlds/fedora-sway-atomic-workstation
```

If you choose another repository name, update `YADM_REPOSITORY` in `.config/fedora-sway-atomic/versions.env` before publishing.

## First installation

Fedora ships no `yadm` package, so it is installed as a digest-pinned script in
`~/.local/bin` rather than layered onto the deployment. See
[installation step 4](docs/INSTALL.md#4-install-yadm) for the exact commands. In
short: install Fedora Sway Atomic with LUKS full-disk encryption, create the
user account, boot the installed deployment, install yadm as described there,
then run:

```bash
yadm clone https://github.com/biomlds/fedora-sway-atomic-workstation.git --bootstrap
```

The yadm bootstrap delegates to `~/.local/bin/workstation-bootstrap apply`. The apply stage:

1. installs or repairs the pinned yadm script against its SHA-256 digest;
2. confirms the Atomic/Fedora environment;
3. layers only missing host integration packages, reporting any name that no
   Fedora package provides instead of aborting the run;
4. confirms the Flathub system remote that Atomic provides by default;
5. installs required Flatpaks system-wide;
6. installs the pinned JetBrains Mono Nerd Font against a repository-pinned SHA-256 digest;
7. builds the pinned Toolbx image and creates a versioned container;
8. runs local checks and reports whether a reboot is required.

`apply` requires `sudo` for rpm-ostree layering and system-wide Flatpak
installation.

Host package layering creates a new deployment. If packages were added, reboot before expecting the complete desktop stack, then run `apply` again to converge the remaining layers.

To review without changing the machine:

```bash
workstation-bootstrap plan
```

To include the optional GUI applications:

```bash
workstation-bootstrap apply --with-optional
```

## Daily use

Open the workstation Toolbx in Zsh:

```bash
workstation-shell
```

Useful commands:

```bash
workstation-bootstrap check
workstation-bootstrap verify
workstation-bootstrap plan --with-optional
yadm status
yadm diff
```

The Toolbx name is versioned. Rebuilding a newer version never silently destroys an older development environment.

## Key bindings

| Binding | Action |
| --- | --- |
| `Super+Return` | Foot terminal |
| `Super+D` | Rofi application launcher |
| `Super+Shift+Q` | Close focused window |
| `Super+Shift+C` | Reload Sway |
| `Super+Shift+E` | Power menu |
| `Super+L` | Lock session |
| `Print` | Copy a region screenshot to the clipboard |
| `Super+Print` | Save a region screenshot in `~/Pictures/Screenshots` |
| `Alt+Print` / `Ctrl+Print` | Fedora `grimshot` window / area capture |
| `Super+1` … `Super+0` | Switch workspace |
| `Super+Shift+1` … `Super+Shift+0` | Move container to workspace |

Media keys are rebound in `.config/sway/config.d/60-bindings-fsa.conf`, which
adds the `--locked` workaround for `XF86AudioPlay`/`Next`/`Prev`.

Waybar, swayidle, the `Alt`/`Ctrl+Print` screenshots, and the volume and
brightness keys are owned by Fedora's own Sway snippets, not by this repository.
Delegating volume and brightness keeps Fedora's on-screen display and its
`$volume_limit`, `$volume_step`, and `$brightness_step` settings. The ownership
table is in [Architecture](docs/ARCHITECTURE.md).

## Design constraints

- No secrets, host names, email addresses, output serials, or backup repository credentials are committed.
- No Quadlet units are implemented. The architecture reserves them for explicitly reviewed future service development only.
- No destructive Toolbx migration occurs automatically.
- Optional Flatpaks are opt-in.
- The host stays minimal: GUI applications are Flatpaks, CLI tooling is Toolbx, and only session integration is layered onto the OS.
- mise is present and activated, but global language runtimes are not installed by bootstrap; projects own their versions with `mise.toml`.
- Session components already provided by Fedora (Waybar, swayidle, `grimshot` screenshots) are not started a second time from this repository.

## Documentation

- [Installation guide](docs/INSTALL.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Hardening](docs/HARDENING.md)
- [Recovery runbook](docs/RECOVERY.md)
- [Operations and upgrades](docs/OPERATIONS.md)
- [Flatpak catalog and validation](docs/FLATPAKS.md)
- [Security model](docs/SECURITY.md)
- [Hardware customization](docs/CUSTOMIZATION.md)
- [Theming](docs/THEMING.md)
- [Tested hardware](docs/TESTED-HARDWARE.md)
- [Upstream references](docs/UPSTREAMS.md)

## Validation

Run the repository checks from a normal clone:

```bash
./scripts/validate-repo.sh
```

On the configured workstation, run the deeper runtime validation:

```bash
workstation-bootstrap verify
```

## License

MIT. See [LICENSE](LICENSE).
