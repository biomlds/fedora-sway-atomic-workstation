# Vendored Catppuccin colorscheme (Neovim)

This directory is a vendored copy of the official Catppuccin Neovim port.

- Upstream: https://github.com/catppuccin/nvim
- Pinned commit: `edefef779ab08ce1a4a404713e3012b0d202bd35`
- Pinned on: 2026-08-09 (`feat(editor): add highlights for PmenuKind and PmenuKindSel (#1011)`)
- Also recorded as `CATPPUCCIN_NVIM_COMMIT` in `.config/fedora-sway-atomic/versions.env`

## What was taken

Everything under `lua/catppuccin/` plus `colors/catppuccin-mocha.lua`, unmodified.

## What was removed

`lua/catppuccin/groups/integrations/` was deleted. We do not install any of the
plugins those files theme, so they would never be loaded: `lua/catppuccin/init.lua`
only `require`s an integration when it is explicitly enabled, and
`~/.config/nvim/init.lua` sets `auto_integrations = false`. The remaining core has
no dependencies outside its own tree.

This cuts the vendored tree from 468 KiB to ~180 KiB.

## Why vendor instead of lazy-loading a plugin manager

The Toolbx container is built offline and reproducible. Vendoring pins the exact
colours that ship with the workstation, so Neovim cannot drift to a different
palette, and a broken network can never change the theme.

## Why the tree is not hand-edited

`scripts/validate-repo.sh` expects the colours in `palettes/mocha.lua` to be
exactly the canonical 26-value Mocha palette. Everything else in this directory
is third-party code: leave it byte-identical to upstream so the pin stays
meaningful and the tree can be re-vendored with a single command.

## Upgrading

```sh
SHA=$(git ls-remote https://github.com/catppuccin/nvim main | cut -f1)
curl -sSL "https://codeload.github.com/catppuccin/nvim/tar.gz/$SHA" | tar xz \
  --strip-components=1 \
  --wildcards '*/lua/catppuccin/*' '*/colors/catppuccin-mocha.lua'
# then re-copy into ~/.config/nvim, delete groups/integrations/,
# update CATPPUCCIN_NVIM_COMMIT in versions.env, and update the date above.
```
