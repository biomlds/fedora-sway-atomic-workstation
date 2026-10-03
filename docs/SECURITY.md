# Security model

## Trust boundaries

- Fedora Atomic and rpm-ostree provide an image-based operating system with deployment rollback.
- Flatpak permissions limit GUI application access but must still be reviewed per application. System-wide installation shares state across accounts and does not add isolation beyond what the sandbox already provides.
- Toolbx is trusted developer convenience. It shares the user's home, devices, sockets, network, and credentials and is not a sandbox.
- yadm content is public-repository-safe by design; no secret material is tracked.
- KeePassXC and offline recovery media are the secret trust anchors.
- Vorta invokes Borg; repository encryption is only as strong as its passphrase/key handling and recovery practice.

## Idle and screen locking

`/etc/sway/config.d/90-swayidle.conf` starts swayidle and locks the screen
before suspend, with timeouts driven by `$lock_timeout` and `$screen_timeout`.
This repository sets those variables rather than shipping a
`~/.config/swayidle/config`, because Fedora passes the timeouts on the command
line and a config file would be ignored. The tracked values lock after five
minutes and power outputs off five minutes later.

## Secret handling

Never commit:

- KeePassXC databases or key files;
- SSH private keys;
- Wi-Fi profiles;
- API tokens, cloud credentials, recovery codes, or environment files containing secrets;
- Borg passphrases, repository URLs containing credentials, or private host aliases;
- real monitor serial numbers when they reveal asset information.

Store secrets in KeePassXC, use SSH agents where appropriate, and keep an offline recovery path.

## Supply-chain controls

- The Toolbx base release and externally sourced component versions are pinned in `.config/fedora-sway-atomic/versions.env`, which is the single source of truth. CI reads its build arguments from that file and the repository validator fails if the Containerfile defaults drift from it.
- Deja and LazyGit are compiled from pinned Go module versions in a separate builder stage.
- eza, Starship, and Yazi are compiled from locked, pinned Rust crates in a separate builder stage.
- Zinit and zsh-syntax-highlighting are fetched by commit SHA rather than by tag, because a tag can be moved to point at different content. `.git` metadata is removed from the runtime image.
- The Nerd Font installer verifies the release archive against `NERD_FONT_SHA256` pinned in this repository. It deliberately does not fetch the release's own checksum file, since a digest published alongside the artifact it protects does not protect it.
- CI rebuilds the Toolbx image and verifies the required command inventory.
- A CI job scans the Git history for common secret patterns. This is a backstop, not a guarantee.
- Flatpak IDs are validated with `flatpak remote-info --system flathub` during deep verification.

The mise bootstrap uses the official installer with a pinned release because mise is not in Fedora's primary repositories at the required cadence. Review changes to that installer path whenever the version pin moves.

Base container images are pinned by Fedora release tag rather than by digest, so rebuilding against changed Fedora repositories may produce a different RPM set. This is a deliberate trade-off: a digest pin would freeze the image on a base that no longer receives security updates. See [Hardening](HARDENING.md) for the full reasoning and the remaining limitations.

## Flatpak review

Use Flatseal for inspection, not as a reason to grant broad access. Review each application's filesystem, device, socket, and session-bus permissions after installation and after major updates. Prefer portals over blanket home-directory access.

## Incident response

1. Disconnect the affected workstation when credential exposure is suspected.
2. Rotate secrets from a separate trusted device.
3. Revoke SSH keys and application sessions.
4. Preserve logs and deployment information required for investigation.
5. Reinstall Fedora Sway Atomic and follow the recovery runbook when integrity is uncertain.
6. Restore data from an archive known to predate the compromise and validate it before use.
