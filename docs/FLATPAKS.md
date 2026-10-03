# Flatpak application catalog

The manifests use canonical Flathub application IDs. `workstation-bootstrap verify` resolves every selected ID with `flatpak remote-info --system flathub APP_ID`; an unresolved ID fails verification.

## Installation scope

Applications are installed **system-wide** from the Flathub **system** remote,
which Fedora Atomic Desktops enable by default. This repository does not add a
second, per-user Flathub remote; if one is found it is reported as a warning.

What this buys:

- The remote definition is part of the OS image, so it is restored by an
  ordinary reinstall and reverted by `rpm-ostree rollback`.
- `flatpak-system-updater` updates applications without user action.
- Applications are available to every local account.

What it does not buy, stated plainly: system Flatpaks live in `/var/lib/flatpak`,
which is **not** part of the OSTree deployment. Rolling the deployment back does
not revert application versions. Rolling back reverts the remote configuration
only. Treat Flatpak application state as separate from OS state when planning
recovery.

## Required

| Application ID | Role | Rationale |
| --- | --- | --- |
| `com.brave.Browser` | Primary web browser | Matches the workstation architecture's default browser. |
| `com.visualstudio.code` | Graphical code editor | Required graphical editor while Neovim remains available in Toolbx. |
| `md.obsidian.Obsidian` | Knowledge base | Restores the documented notes workflow. |
| `org.keepassxc.KeePassXC` | Secrets source of truth | Required before restoring credentials and backup access. |
| `com.borgbase.Vorta` | Borg backup client and scheduler | Replaces Borgmatic in the agreed desktop architecture. |

## Optional

| Application ID | Role |
| --- | --- |
| `org.mozilla.firefox` | Alternative browser |
| `org.telegram.desktop` | Messaging |
| `org.cryptomator.Cryptomator` | Client-side encrypted vaults |
| `org.onlyoffice.desktopeditors` | Office documents |
| `org.gimp.GIMP` | Image editing |
| `com.github.tchx84.Flatseal` | Flatpak permission inspection |
| `org.videolan.VLC` | Media playback |
| `com.spotify.Client` | Music streaming |
| `dev.vencord.Vesktop` | Discord-compatible desktop client |

## Validation and review

Check one application before changing a manifest:

```bash
flatpak remote-info --system flathub APP_ID
```

Check every required and optional application:

```bash
workstation-bootstrap verify --with-optional
```

Reviewing permissions of an installed application:

```bash
flatpak override --user --show APP_ID
```

An ID resolving on Flathub confirms availability, not trust. Review publisher
verification, license, source status, permissions, and update history on Flathub
before promoting an optional application to required. Proprietary applications
remain subject to their own terms and privacy policies.
