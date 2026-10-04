# Upstream references

- Fedora Sway config packaging (source of /etc/sway/config and /etc/sway/config.d): https://gitlab.com/fedora/sigs/sway/sway-config-fedora
- sway-config-fedora RPM spec: its Requires and Recommends are the authority for what the base image already provides, and therefore for what belongs in host-packages.txt: https://src.fedoraproject.org/rpms/sway-config-fedora
- Sway upstream config.in (shows the include @sysconfdir@/sway/config.d/* convention): https://github.com/swaywm/sway/blob/master/config.in
- sway(5), which defines unbindsym flag matching: https://man.archlinux.org/man/sway.5.en
These sources define the behavior assumed by the repository and should be reviewed when component versions change. The Fedora Sway Atomic product page is *not* a substitute for the spec: it advertises `light`, `imv`, `Thunar`, `dunst`, and `kanshi`, but upstream requires none of them and uses `brightnessctl` rather than `light` for backlight.

- Fedora Sway configuration guide: https://docs.fedoraproject.org/en-US/atomic-desktops/sway-configuration-guide/
- Fedora Atomic installation: https://docs.fedoraproject.org/en-US/atomic-desktops/installation/
- yadm bootstrap: https://yadm.io/docs/bootstrap
- yadm installation (states that RPM distributions are served from openSUSE Build Service rather than Fedora): https://yadm.io/docs/install#download
- yadm upstream source, pinned by commit rather than by a moving branch: https://github.com/yadm-dev/yadm
- Toolbx documentation: https://containertoolbx.org/doc/
- Toolbx create reference: https://github.com/containers/toolbox/blob/main/doc/toolbox-create.1.md
- Catppuccin palette: https://github.com/catppuccin/catppuccin
- Nerd Fonts releases: https://github.com/ryanoasis/nerd-fonts/releases
- Zinit releases: https://github.com/zdharma-continuum/zinit/releases
- Deja: https://github.com/Giammarco-Ferranti/deja
- LazyGit: https://github.com/jesseduffield/lazygit
- eza: https://github.com/eza-community/eza
- zsh-syntax-highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
- Starship: https://starship.rs/
- mise installation: https://mise.jdx.dev/installing-mise.html
- Yazi installation: https://yazi-rs.github.io/docs/installation/
- Flathub: https://flathub.org/
- Vorta: https://vorta.borgbase.com/
- Flathub user vs system installation: https://docs.flathub.org/docs/for-users/user-vs-system-install

## Upstream behavior this repository depends on

- Fedora's /etc/sway/config merges user snippets via a layered-include helper, ordering /usr/share/sway/config.d, /etc/sway/config.d, then ~/.config/sway/config.d. User snippets therefore load last, which is what makes unbindsym overrides take effect.
- The helper globs *.conf. A user snippet with any other extension is dropped silently.
- unbindsym removes a binding only when it was created with the same flags, so --locked must be mirrored.
- /etc/sway/config.d/90-swayidle.conf passes idle timeouts on the swayidle command line, so ~/.config/swayidle/config is never read.
- Fedora Atomic Desktops enable the Flathub system remote by default.

If any of these change upstream, re-check the session ownership table in [Architecture](ARCHITECTURE.md).

## Pinned versions

Toolbx pins live in exactly one place, `.config/fedora-sway-atomic/versions.env`. The Containerfile repeats them as `ARG` defaults so it can also be built standalone, and `./scripts/validate-repo.sh` fails when the two disagree.

Currently pinned: Fedora 44, Nerd Fonts 3.5.1, Deja v0.4.2, LazyGit v0.65.1, eza 0.23.5, Starship 1.26.0, Yazi 26.9.1, Zinit v3.17.0 (db9e267), zsh-syntax-highlighting 0.8.0 (db085e4), and mise v2026.9.14.

yadm itself is pinned outside the Toolbx image, because it runs on the host rather than inside a container: yadm 3.5.0 at commit 7eabaee84c8bd9521e56966e5c88e7a435fdd9c7 with SHA-256 d8c2d661725b98e9910e4a59b58beed5cfb01f5196a825a08668ff0887f7441d. Pin by commit, not by tag or branch: yadm's `develop` branch is not byte-identical to its `3.5.0` tag, and it publishes no release assets, so a branch or release URL would silently change the tool under a reader. The same three values are repeated in [Installation](INSTALL.md#4-install-yadm) for the pre-clone step; `scripts/validate-repo.sh` fails if they drift apart.

The image package transaction records exact Fedora RPM versions in the resulting OCI image metadata; rebuilding against changed Fedora repositories may produce a different RPM set, so publish immutable image digests if distributing prebuilt images. See [Hardening](HARDENING.md).
