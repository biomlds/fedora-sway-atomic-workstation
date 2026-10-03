# Contributing

1. Create a branch from `main`.
2. Keep host additions minimal; prefer Flatpak for GUI applications and Toolbx for CLI tools.
3. Pin the Toolbx base release and external component versions.
4. Never commit credentials, machine output identifiers, private backup locations, or personal Git identity.
5. Run `./scripts/validate-repo.sh` before opening a pull request.
6. If the Toolbx definition changes, build it locally and run the image smoke command from `.github/workflows/validate.yml`.
7. Update `CHANGELOG.md` and the relevant operational documentation for user-visible changes.

Changes that add a host layer, new Flatpak permission, network installer, or persistent service must include a rationale and rollback procedure.
