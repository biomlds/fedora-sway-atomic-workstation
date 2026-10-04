# Hardening

The workstation is secure because of what it does not change: the host stays
small, applications are sandboxed Flatpaks, and the immutable base can be rolled
back. This document covers what is enabled by default, what the repository adds,
and what the owner still has to decide.

## Enforced by the platform

These are properties of Fedora Atomic, not of this repository. Verify, do not
assume:

```bash
getenforce                       # expect: Enforcing
sestatus | head -3
rpm-ostree status
systemctl is-enabled firewalld
```

- **Immutable host.** Changes are recorded as deployments, so a bad update is
  undone with `rpm-ostree rollback` rather than repaired in place.
- **SELinux enforcing.** Flatpak applications additionally run under the
  `xdg-desktop-portal` and bwrap sandbox layers.
- **Rollback.** Keep at least one previous deployment until the current one has
  survived a full working session, including suspend and resume.

## Host footprint

Every entry in `.config/fedora-sway-atomic/host-packages.txt` adds a host layer.
Each one is a package that will not roll back with `rpm-ostree rollback`.

The manifest deliberately omits packages the base image already guarantees. The
`sway-config-fedora` spec hard-Requires sway, brightnessctl, grimshot,
playerctl, swayidle, swaylock, and waybar, so listing them would promise a layer
that can never be created and would overstate the footprint. `foot`,
`libnotify`, and `rofi-wayland` are only `Recommends`, and `dunst` and `kanshi`
are not mentioned upstream at all, so those five are listed and layered.

The split is deliberate:

- GUI applications belong in Flatpak, not on the host.
- CLI developer tooling belongs in Toolbx, not on the host.
- Only compositor and session integration, plus bootstrap prerequisites, belong
  on the host.

Before adding a host package, confirm it cannot be delivered as a Flatpak or a
Toolbx image. Record the operational reason and a rollback command.

Two components are installed outside package management and are therefore never
covered by `rpm-ostree rollback`:

- **yadm**, as `~/.local/bin/yadm`, a single POSIX shell script from
  `yadm-dev/yadm` pinned by commit and SHA-256 in
  `.config/fedora-sway-atomic/versions.env`. Fedora ships no `yadm` package, so
  the alternative was a third-party repository in the ostree deployment. The
  script runs as the invoking user and holds no privileges beyond that user's
  own home directory.
- **JetBrains Mono Nerd Font**, as loose files under
  `~/.local/share/fonts/`, verified against `NERD_FONT_SHA256`.

Both are treated as *content*, not packages: `apply` re-verifies the digest on
every run and reinstalls the pinned copy if it is missing or has drifted, so
these are self-healing in a way layered packages are not. To confirm the state by
hand:

```bash
sha256sum ~/.local/bin/yadm
grep YADM_SHA256 .config/fedora-sway-atomic/versions.env
```

If the two differ, do not run `yadm`; reinstall from
[installation step 4](INSTALL.md#4-install-yadm).

## Application sandboxing

Flatpak permissions are the main per-application risk. Review them rather than
trusting them:

```bash
flatpak info --system APP_ID
flatpak override --user --show APP_ID
```

Install Flatseal (`com.github.tchx84.Flatseal`) to inspect permissions
conveniently. Prefer portals over granting home-directory or device access.

Re-review after a major application update, because permission changes arrive
silently with the update.

## Toolbx is not a sandbox

Toolbx shares the user's home directory, devices, sockets, network, and
credentials. It is a development environment with an ergonomic shell, not a
security boundary. Anything untrusted should run outside it, for example in a
disposable podman container or a VM.

## Verified supply chain

Handled by this repository and enforced by CI:

- The Nerd Font archive is verified against `NERD_FONT_SHA256` in
  `versions.env`. The digest is pinned in the repository rather than fetched
  from the release, because a checksum published alongside the artifact it
  protects proves nothing on its own.
- `zinit` and `zsh-syntax-highlighting` are fetched by commit SHA, not by tag,
  since a tag can be moved to point at different content.
- `eza`, `starship`, and `yazi` build from locked Cargo manifests; `deja` and
  `lazygit` build from pinned Go module versions; both compile in separate
  builder stages.
- Toolbx pins live only in `.config/fedora-sway-atomic/versions.env`. CI reads
  them from there, and `./scripts/validate-repo.sh` fails if the Containerfile
  defaults drift from that file.
- Flatpak IDs are resolved against Flathub during deep verification.

Known limitation: the Toolbx base images are pinned by Fedora release tag, not
by digest, so rebuilding later against changed Fedora repositories can produce
a different RPM set. This is deliberate. Digest-pinning the base would freeze
the image on a stale, potentially insecure base and would require a manual bump
for every Fedora point release. Record the resolved digest when publishing a
prebuilt image.

Known limitation: `dnf upgrade` runs during the image build, so the image is not
bit-reproducible across rebuilds.

## Screen lock

The idle policy is owned by `/etc/sway/config.d/90-swayidle.conf`, which reads
`$lock_timeout` and `$screen_timeout`. The repository sets both in
`.config/sway/config.d/15-timeouts-fsa.conf`:

- Lock after 5 minutes idle.
- Power outputs off 5 minutes later.
- Keep outputs off for a further 5 minutes while the screen stays locked.

The lock also triggers before suspend. Tune the two variables rather than
editing `/etc/sway/config.d`, which rpm-ostree owns.

A shorter lock timeout is the single highest-value change for a portable
machine. Consider 2 minutes for a laptop.

## Secrets

KeePassXC is the source of truth. Never commit to this repository:

- KeePassXC databases or key files
- SSH private keys
- Wi-Fi profiles
- API tokens, cloud credentials, recovery codes
- Borg passphrases or repository URLs containing credentials
- Monitor serial numbers that reveal asset information

`workstation-bootstrap verify` and CI do not detect a leaked secret in your
history. The `secret-scan` CI job scans for the common cases; it is not a
substitute for reviewing what you stage.

Keep an offline copy of the KeePassXC database and its recovery material.

## Backups are a security control

A backup you have never restored from is not a backup, and an unencrypted Borg
repository is a liability. At least quarterly, run a backup, list the archive,
extract representative files to a temporary directory, and confirm the KeePassXC
path needed to reach the repository still works. See
[Operations](OPERATIONS.md).

## Not covered here

These are deliberately out of scope and require an individual decision:

- Kernel command-line tuning and sysctl hardening
- `fscrypt` encryption of project directories beyond LUKS
- A hardware security key for sudo or for Git hosting
- Kernel lockdown mode
- Disabling the microcode update daemon

Each has a real usability cost. Adopt them deliberately rather than copying a
list, and record the decision so the next reinstall reproduces it.

## Incident response

1. Disconnect the machine if credential exposure is suspected.
2. Rotate secrets from a separate trusted device.
3. Revoke SSH keys and active application sessions.
4. Preserve logs and deployment information.
5. Reinstall Fedora Sway Atomic and follow [Recovery](RECOVERY.md) when
   integrity is uncertain.
6. Restore from an archive that predates the compromise and validate it before
   use.
