# Upstream references

- Fedora Sway config packaging (source of /etc/sway/config and /etc/sway/config.d): https://gitlab.com/fedora/sigs/sway/sway-config-fedora
- Sway upstream config.in (shows the include @sysconfdir@/sway/config.d/* convention): https://github.com/swaywm/sway/blob/master/config.in
- sway(5), which defines unbindsym flag matching: https://man.archlinux.org/man/sway.5.en
These sources define the behavior assumed by the repository and should be reviewed when component versions change.

- Fedora Sway configuration guide: https://docs.fedoraproject.org/en-US/atomic-desktops/sway-configuration-guide/
- Fedora Atomic installation: https://docs.fedoraproject.org/en-US/atomic-desktops/installation/
- yadm bootstrap: https://yadm.io/docs/bootstrap
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

The image package transaction records exact Fedora RPM versions in the resulting OCI image metadata; rebuilding against changed Fedora repositories may produce a different RPM set, so publish immutable image digests if distributing prebuilt images. See [Hardening](HARDENING.md).
