# Operations and upgrades

## Routine checks

```bash
rpm-ostree status
flatpak update --system
workstation-bootstrap check
yadm status
```

Use `workstation-bootstrap verify` after changing the desktop configuration, Toolbx image, font version, or Flatpak manifests.

## Updating the Atomic host

```bash
rpm-ostree upgrade
rpm-ostree status
systemctl reboot
```

Keep the previous deployment until Sway login, networking, audio, graphics, and suspend/resume have been tested.

## Updating Toolbx

`.config/fedora-sway-atomic/versions.env` is the single source of truth for
Toolbx pins. CI builds the image from that file, and `./scripts/validate-repo.sh`
fails if the `ARG` defaults in `toolbox/Containerfile` drift from it. Update the
Containerfile defaults in the same change, or keep them and let the validator
tell you.

1. Update the pin in `.config/fedora-sway-atomic/versions.env`, and the matching
   `ARG` default in `toolbox/Containerfile`.
2. Increment both `TOOLBOX_IMAGE_VERSION` and `TOOLBOX_NAME`.
3. Build and inspect:

   ```bash
   workstation-bootstrap plan
   workstation-bootstrap apply
   workstation-shell
   ```

4. Run `workstation-bootstrap verify`.
5. Keep the old container until active repositories and uncommitted work are confirmed safe.
6. Remove the old container and image explicitly when no longer needed.

Do not reuse a container name for a materially different image.

### Changing the Nerd Font version

`NERD_FONT_VERSION` and `NERD_FONT_SHA256` must be updated together. Compute the
digest from the release and confirm it matches the release's own `SHA-256.txt`
before committing:

```bash
curl -fsSLO https://github.com/ryanoasis/nerd-fonts/releases/download/v${VERSION}/JetBrainsMono.zip
sha256sum JetBrainsMono.zip
```

The installer compares against `NERD_FONT_SHA256` and refuses to install on a
mismatch. Note that the checksum asset published by that project is named
`SHA-256.txt`.

### Changing a pinned git dependency

`ZINIT_COMMIT` and `ZSH_SYNTAX_HIGHLIGHTING_COMMIT` are commit SHAs, not tags.
Resolve a new version to its commit and update the `VERSION` and `COMMIT` pair
together:

```bash
git ls-remote https://github.com/zdharma-continuum/zinit.git refs/tags/v3.17.0
```

### Changing the yadm version

`YADM_COMMIT` is a commit SHA and `YADM_SHA256` is the digest of the single
`yadm` script at that commit. There is no release asset to download, so resolve
the tag, fetch the script by commit, and digest it:

```bash
git ls-remote https://github.com/yadm-dev/yadm.git refs/tags/3.6.0
curl --fail --location --silent --show-error \
  https://raw.githubusercontent.com/yadm-dev/yadm/COMMIT/yadm -o /tmp/yadm
sha256sum /tmp/yadm
grep -m1 '^VERSION=' /tmp/yadm
```

Confirm `VERSION=` matches the tag you resolved, then update `YADM_VERSION`,
`YADM_COMMIT`, and `YADM_SHA256` in `.config/fedora-sway-atomic/versions.env`
*and* the same three values in `docs/INSTALL.md` and `docs/RECOVERY.md`, which
are the pre-clone instructions and cannot reference this repository. The
validator fails when the copies disagree. Run `workstation-bootstrap apply` to
replace the installed script, then confirm `yadm version`.

## Updating Flatpaks

```bash
sudo flatpak update --system
flatpak uninstall --system --unused
```

Before adding an ID, validate it:

```bash
flatpak remote-info --system flathub APP_ID
```

Classify a GUI application as required only when recovery or the normal workflow depends on it. Keep alternatives and discretionary applications optional.

## Updating the Nerd Font

Update `NERD_FONT_VERSION` and `NERD_FONT_SHA256` together, then run
`workstation-bootstrap apply` and confirm:

```bash
fc-match 'JetBrainsMono Nerd Font'
workstation-bootstrap verify
```

See "Changing the Nerd Font version" above for the digest procedure.

## Updating yadm configuration

```bash
yadm status
yadm diff
yadm add PATH
yadm commit -m 'Describe the configuration change'
yadm push
```

Run the repository validator from a conventional clone or from the yadm worktree root:

```bash
~/scripts/validate-repo.sh
```

## Backup operations

Vorta configures and schedules Borg backups. Keep repository credentials outside Git. At least quarterly:

1. run a manual backup;
2. inspect the archive;
3. extract representative files to a temporary directory;
4. record the successful test outside the backup repository;
5. verify the KeePassXC recovery path needed to access the repository.

## Removing a host layer

First identify whether the package is layered:

```bash
rpm-ostree status
rpm -q PACKAGE
```

Remove it from the manifest and deployment:

```bash
sudo rpm-ostree uninstall PACKAGE
systemctl reboot
```

Never use a broad package cleanup command on an Atomic deployment without reviewing the pending deployment.

## Removing the vendored yadm script

yadm is not a host layer, so `rpm-ostree uninstall` does not apply. Remove the
script and its state directly:

```bash
rm -f ~/.local/bin/yadm
rm -rf ~/.local/share/yadm
```

Only do this to hand the machine back to a state that predates this repository.
`workstation-bootstrap apply` will otherwise reinstall the pinned script, which
is intentional.
