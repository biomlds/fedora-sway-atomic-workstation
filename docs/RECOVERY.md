# Recovery runbook

## Recovery prerequisites

Keep these outside the workstation:

- Fedora Sway Atomic installation media and its verified checksum.
- LUKS recovery information.
- Access to the GitHub account and this repository.
- KeePassXC database plus its key material and recovery method.
- Vorta/Borg repository location, passphrase, and any SSH key required to reach it.
- A tested backup containing Documents, Pictures, notes, projects, and other user data.

## Bare-metal recovery

### 1. Install the operating system

Install the current Fedora Sway Atomic release manually. Enable LUKS, create the intended user, and complete the first boot. Apply operating system updates:

```bash
rpm-ostree upgrade
systemctl reboot
```

### 2. Install yadm

```bash
sudo rpm-ostree install yadm
systemctl reboot
```

### 3. Restore configuration

```bash
yadm clone https://github.com/biomlds/fedora-sway-atomic-workstation.git --no-bootstrap
yadm status
workstation-bootstrap plan
workstation-bootstrap apply
```

`apply` requires `sudo`: rpm-ostree layering and system-wide Flatpak installation both need it. If host packages were layered, reboot and run `workstation-bootstrap apply` again. The second run converges Flatpaks, font, and Toolbx without duplicating prior work.

See [Installation](INSTALL.md) for the full first-install sequence.

### 4. Validate the platform

```bash
workstation-bootstrap check
workstation-bootstrap verify
```

Resolve every failed required check before restoring sensitive material.

### 5. Restore secrets

Open KeePassXC and restore its database using the separately stored recovery method. Restore SSH keys with restrictive permissions:

```bash
chmod 700 ~/.ssh
find ~/.ssh -type f -exec chmod 600 {} +
find ~/.ssh -type f -name '*.pub' -exec chmod 644 {} +
```

Do not copy tokens or passphrases into this repository.

### 6. Restore data with Vorta

Open Vorta, add the existing Borg repository, provide credentials through the approved secret process, inspect archive contents, and restore to a temporary directory first. Compare the temporary restore before replacing current files. Re-enable scheduled backups only after a successful manual backup and extraction test.

### 7. Restore project runtimes

Enter the Toolbx and install only project-declared versions:

```bash
workstation-shell
cd ~/Projects/example
mise trust
mise install
```

### 8. Final acceptance

- Log in to Sway and test launcher, lock, idle, notifications, audio, brightness, and screenshots.
- Confirm required Flatpaks start and their data is present.
- Confirm `workstation-shell` opens Zsh and `deja`, `nvim`, `lazygit`, `tmux`, `yazi`, and `mise` run.
- Run a Vorta backup, check the Borg archive, and perform a test extraction.
- Remove the reboot marker after confirming the new deployment:

```bash
rm -f ~/.local/state/fedora-sway-atomic-reboot-required
```

## rpm-ostree rollback

If a new deployment does not boot or the host-layer change is unsuitable, choose the previous deployment from the boot menu or run:

```bash
sudo rpm-ostree rollback
systemctl reboot
```

The yadm, Flatpak, font, and Toolbx data in the home directory are independent of the deployment rollback. Note that a rollback reverts the Flatpak remote *configuration*, which lives in the deployment, but not application versions in `/var/lib/flatpak`, which does not.

## Toolbx rollback

A version upgrade creates a differently named container. Enter the older container with `toolbox enter OLD_NAME`. Remove an obsolete container only after projects and uncommitted work are accounted for:

```bash
toolbox rm OLD_NAME
podman image rm OLD_IMAGE_REFERENCE
```

## yadm recovery

Inspect before discarding local changes:

```bash
yadm status
yadm diff
yadm log --oneline --decorate -10
```

Restore one tracked file with `yadm restore PATH`. Avoid `yadm reset --hard` unless the entire home worktree has been reviewed and backed up.
