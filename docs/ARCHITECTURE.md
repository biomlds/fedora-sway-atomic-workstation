# Architecture

## Goals

The workstation optimizes for recovery, minimal host mutation, reproducibility, version-controlled configuration, and clear separation between the operating system, GUI applications, developer tools, secrets, and data.

## Layer model

### Layer 0: Fedora Sway Atomic

Fedora Sway Atomic is manually installed with LUKS encryption. Podman, Toolbx, rpm-ostree, and Flatpak provide the platform primitives. Host package layering is reserved for software that must integrate directly with the compositor or session.

### Layer 1: yadm configuration

yadm owns the home-relative files in this repository. Fedora's Sway profile remains the base; ordered snippets under `~/.config/sway/config.d` override it at user precedence. The repository contains no secrets or machine output identifiers.

### Layer 2: desktop session

The host session consists of Sway, Waybar, Rofi, Dunst, Foot, Kanshi, Swaylock,
and Swayidle. The visual system is Catppuccin Mocha with Sapphire (`#74c7ec`) as
the principal accent. JetBrains Mono Nerd Font supplies consistent text and icon
glyphs.

#### Ownership of the session components

The repository does not re-create the whole session. Fedora's
`/etc/sway/config` merges user snippets through a `layered-include` helper, in
this order: `/usr/share/sway/config.d`, `/etc/sway/config.d`, then
`~/.config/sway/config.d`. User snippets load last, which is what makes
`unbindsym` overrides work.

Because Fedora already owns several session components, starting them again from
a user snippet produces a duplicate, unmanaged process. Ownership is therefore
split explicitly:

| Component | Owner | Mechanism |
| --- | --- | --- |
| Waybar | Fedora | `/etc/sway/config.d/90-bar.conf`, `bar { swaybar_command waybar }` |
| swayidle | Fedora | `/etc/sway/config.d/90-swayidle.conf` |
| Screenshots (Alt/Ctrl+Print) | Fedora | `/etc/sway/config.d/60-bindings-screenshot.conf`, `grimshot` |
| Idle timeouts | this repository | `$lock_timeout` / `$screen_timeout` in `15-timeouts-fsa.conf` |
| Dunst, Kanshi | this repository | `90-autostart-fsa.conf` |
| Theme, key bindings, window rules | this repository | `10-`, `20-`, `60-`, `99-` snippets |

Consequences worth knowing:

- A single `unbindsym` only removes a binding made with the same flags, so
  `60-bindings-fsa.conf` mirrors `--locked` when unbinding a `--locked` binding.
- Fedora's `90-swayidle.conf` passes timeouts on the command line, so a
  `~/.config/swayidle/config` would be ignored. The idle policy is expressed as
  sway variables instead.
- Fedora's snippet glob is `*.conf`. A user snippet with any other extension is
  dropped silently. Both `validate-repo.sh` and `workstation-bootstrap verify`
  check for this.

### Layer 3: versioned Toolbx

`toolbox/Containerfile` builds `localhost/biomlds/workstation-toolbox:44-2026.09.0`, and bootstrap creates `workstation-f44-2026-09`. The image contains the complete CLI environment and pinned external components. A new image version receives a new container name so an update cannot silently replace an existing environment.

Toolbx shares the user's home directory and desktop/session resources. It is an ergonomic development environment, not a sandbox or security boundary.

### Layer 4: mise

mise is installed in the Toolbx and activated by Zsh. Bootstrap deliberately does not install global language runtimes. Each project declares versions in its own `mise.toml`, which prevents workstation state from becoming an undocumented source of truth.

### Layer 5: Flatpak GUI applications

Required applications are in `flatpaks-required.txt`; optional applications are
in `flatpaks-optional.txt`. Installations are system-wide and resolved from the
Flathub system remote that Atomic enables by default; the repository does not add
a duplicate per-user remote. Vorta is the backup interface and scheduler. Borg
repositories, passphrases, and retention policies remain outside this
repository.

System-wide installation means the remote definition is part of the OS image,
while application data in `/var/lib/flatpak` sits outside the OSTree deployment
and therefore does not roll back with the deployment.

### Layer 6: secrets and data

KeePassXC is the secrets source of truth. SSH keys, tokens, Wi-Fi credentials, recovery codes, Vorta repository URLs, and Borg passphrases are restored separately. Documents, pictures, notes, projects, and backup repositories are data, not configuration.

## Bootstrap state machine

- `plan`: read-only diff of host packages, applications, font, image, and container.
- `apply`: converges each component idempotently. Existing packages, applications, font, image, and container are not reinstalled.
- `check`: local and fast; confirms the booted environment and installed inventory.
- `verify`: deep and potentially network-dependent; validates Sway and Waybar configuration, Flathub IDs, and the command inventory inside Toolbx.

## Host mutation policy

The host package manifest includes only compositor/session integration and bootstrap prerequisites. CLI development tools belong in Toolbx. GUI applications belong in Flatpak. A host-layer addition requires an operational reason and rollback instructions.

## Service policy

There are no Quadlet units in this version. A future service may use Quadlets only after its persistence, networking, secret storage, backup behavior, update policy, and rollback have been designed and reviewed. The existence of that extension point is not authorization to deploy a service automatically.

## Recovery boundaries

1. Fedora deployment: recreated by installation and rpm-ostree layering.
2. User configuration: restored by yadm.
3. CLI tools: rebuilt from the Containerfile.
4. GUI applications: restored from manifests. System Flatpak data is outside the
   OSTree deployment and must be reinstalled after a reinstall.
5. Secrets: recovered from KeePassXC and offline recovery material.
6. User data: restored through Vorta/Borg.
