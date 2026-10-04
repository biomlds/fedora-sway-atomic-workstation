# Installation guide

This guide covers the operating system installation that happens before this
repository is used. The repository itself cannot be applied until a Fedora Sway
Atomic deployment is booted and a user account exists.

## Before you start

Decide and record these offline. Each one is expensive to change later.

- **Full-disk encryption.** Enable LUKS. There is no recovery path for a lost
  LUKS passphrase; verify that your passphrase is written down and stored
  somewhere physically separate from the machine.
- **Secure Boot.** Leave it enabled and sign the installation media keys when
  the firmware offers. Disabling Secure Boot removes a boot-chain trust anchor
  and also affects third-party driver loading.
- **TPM-backed measured boot.** Keep the default. It strengthens the integrity
  guarantee of an ostree deployment without user-visible cost.
- **Filesystem layout.** The default layout is acceptable. Custom layouts risk a
  partition too small for a future rpm-ostree deployment.
- **A second machine.** Keep the KeePassXC database, recovery codes, and SSH
  keys reachable from another device. See [Recovery](RECOVERY.md).

## 1. Verify the installation media

Download the Fedora Sway Atomic ISO and the matching published checksum, then
verify before writing to USB media:

```bash
sha256sum -c <CHECKSUM_FILE>
```

Do not skip this. An unverified ISO is an untrusted bootloader.

## 2. Install Fedora Sway Atomic

Boot the verified media and follow the installer. Points that matter for this
repository:

- Select **encryption** and set a strong LUKS passphrase.
- Complete the user creation. The first non-greeter user created becomes the
  privileged administrator.
- Do not skip firmware updates if the installer offers them.
- Reboot into the installed deployment rather than the live image.

## 3. Update the deployment

```bash
rpm-ostree upgrade
systemctl reboot
```

Keep the previous deployment. Do not delete it until the new one has been used
for a normal working session.

## 4. Install yadm

Fedora ships **no** `yadm` package, in Fedora itself or in Fedora EPEL, so
`rpm-ostree install yadm` cannot work and is not used here. Upstream's own
[installation page](https://yadm.io/docs/install#download) points RPM
distributions at the openSUSE Build Service instead; adding a third-party
repository to the ostree deployment is avoided. yadm is therefore installed as
a digest-pinned script in `~/.local/bin`.

This step must work before this repository is cloned, so it cannot call a
helper from the repository. Run it verbatim:

```bash
YADM_VERSION=3.5.0
YADM_COMMIT=7eabaee84c8bd9521e56966e5c88e7a435fdd9c7
YADM_SHA256=d8c2d661725b98e9910e4a59b58beed5cfb01f5196a825a08668ff0887f7441d

tmp=$(mktemp -d)
curl --fail --location --silent --show-error --retry 3 \
  "https://raw.githubusercontent.com/yadm-dev/yadm/${YADM_COMMIT}/yadm" \
  -o "$tmp/yadm"
printf '%s  %s\n' "$YADM_SHA256" "$tmp/yadm" | sha256sum --check
install -Dm0755 "$tmp/yadm" "$HOME/.local/bin/yadm"
rm -rf "$tmp"
yadm version
```

`sha256sum` must print `yadm: OK` before the script is installed. If it reports
`FAILED`, stop and investigate: the download did not match the pin, so do not
continue. The final command should report `yadm version 3.5.0`.

`apply` re-verifies the installed script against the same digest and reinstalls
it if it is missing or has drifted, so this step only has to succeed once.

The commit is pinned rather than a release tag because yadm's `develop` branch
moves independently of its tags; the script at `develop` is not byte-identical to
the `3.5.0` tag. The pinned values are mirrored in
`.config/fedora-sway-atomic/versions.env` and `scripts/validate-repo.sh` fails if
they disagree with this page.

## 5. Apply this repository

```bash
yadm clone https://github.com/biomlds/fedora-sway-atomic-workstation.git --bootstrap
```

The bootstrap runs `workstation-bootstrap apply`. Expect at least two reboots
during the first application, because host package layering only takes effect
in a new deployment:

1. `apply` layers host packages and reports that a reboot is required.
2. Reboot into the new deployment.
3. Run `workstation-bootstrap apply` again to converge Flatpaks, the font, and
   the Toolbx image.

`apply` requires `sudo` for `rpm-ostree` layering and for system-wide Flatpak
installation.

## 6. Validate

```bash
workstation-bootstrap check
workstation-bootstrap verify
```

Resolve every failure before treating the machine as ready. The runbook in
[Recovery](RECOVERY.md) assumes both commands pass.

## 7. Accept the machine

Work through this list before relying on the workstation:

- Sway starts, and the Catppuccin theme is applied rather than the default Sway
  colours.
- Waybar is running once, not twice.
- `Super+Return` opens Foot, `Super+D` opens Rofi.
- The screen locks after five minutes of inactivity and the display powers off
  afterwards.
- `Print` copies a region screenshot to the clipboard, `Super+Print` saves one,
  and `Alt+Print` / `Ctrl+Print` use the Fedora `grimshot` bindings.
- Volume, media, and brightness keys each change state once per press.
- `Super+E` opens the power menu, including a working Suspend.
- `workstation-shell` opens Zsh and `nvim`, `lazygit`, `yazi`, `mise`, and
  `deja` all run.
- `nvim`, `yazi`, and `eza` open in the Mocha/Sapphire theme rather than their
  own defaults. Neovim compiles its highlight cache on first launch, so give it
  a moment before judging the colors.
- A Vorta backup completes and the archive can be listed.

Two of these are regression guards for bugs fixed in this version; they are
worth confirming explicitly rather than assuming.

## 8. Theme the applications that need it

Most tools are themed by this repository alone, so there is nothing to do here.
Three do not, and are listed so they are a known gap rather than a surprise:

- **VS Code** is not themed until its Catppuccin extension is installed. Run
  this once:

  ```bash
  flatpak run com.visualstudio.code \
    --install-extension catppuccin.catppuccin-vsc
  ```

  Without it VS Code shows a warning that the requested theme is missing. The
  integrated terminal is on-palette either way, because its palette is written
  out in `settings.json`.

- **KeePassXC** ships only Light, Dark, and System. Select its built-in **Dark**
  theme in Settings → Appearance. There is no Catppuccin port.

- **Vorta** has no dark mode and, being a Flatpak, cannot see
  `~/.config/kdeglobals`. The recipe in [Theming](THEMING.md) is unverified;
  treat it as an experiment rather than a required step.

Brave and Obsidian themes are selected inside the application, per profile and
per vault respectively. [Theming](THEMING.md) links the official ports.

Then confirm the theme is consistent end to end:

```bash
git diff
lazygit
yazi
eza
nvim
```

`git diff` and LazyGit both use the Mocha colors from this repository rather than
Git's own defaults. Yazi, eza, and Neovim use the official Catppuccin ports
listed in [Theming](THEMING.md), pinned rather than fetched at runtime. Run
`./scripts/validate-repo.sh` if you changed any color by hand.

## Cleaning up the reboot marker

After confirming the deployment is healthy:

```bash
rm -f ~/.local/state/fedora-sway-atomic-reboot-required
```
