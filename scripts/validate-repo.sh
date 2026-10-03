#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"
failures=0

pass() { printf '[PASS] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; failures=1; }

required_files=(
  README.md LICENSE CHANGELOG.md
  .config/yadm/bootstrap
  .local/bin/workstation-bootstrap
  .local/share/fedora-sway-atomic/bootstrap-lib.sh
  .config/fedora-sway-atomic/versions.env
  .config/fedora-sway-atomic/host-packages.txt
  .config/fedora-sway-atomic/flatpaks-required.txt
  .config/fedora-sway-atomic/flatpaks-optional.txt
  .config/sway/config.d/10-theme.conf .config/sway/config.d/15-timeouts-fsa.conf
  .config/sway/config.d/20-input.conf .config/sway/config.d/60-bindings-fsa.conf
  .config/sway/config.d/90-autostart-fsa.conf .config/sway/config.d/99-rules-fsa.conf
  .config/sway/environment
  .config/waybar/config.jsonc .config/waybar/style.css
  .config/rofi/config.rasi .config/dunst/dunstrc .config/foot/foot.ini
  '.config/bat/themes/Catppuccin Mocha.tmTheme'
  .config/kanshi/config .config/swaylock/config
  toolbox/Containerfile docs/ARCHITECTURE.md docs/RECOVERY.md docs/OPERATIONS.md
  docs/SECURITY.md docs/CUSTOMIZATION.md docs/FLATPAKS.md docs/UPSTREAMS.md
  docs/INSTALL.md docs/HARDENING.md docs/TESTED-HARDWARE.md
)
for file in "${required_files[@]}"; do
  [[ -s "$file" ]] || fail "missing or empty required file: $file"
done
(( failures == 0 )) && pass 'required file inventory'

# Every relative Markdown link must resolve, so a renamed document cannot leave
# a dangling pointer behind.
while IFS= read -r -d '' doc; do
  doc_dir=$(dirname -- "$doc")
  while IFS= read -r target; do
    [[ -e "$doc_dir/$target" ]] || fail "broken link in ${doc#./}: $target"
  done < <(grep -oE '\]\([^)#][^)]*\)' "$doc" | sed -e 's/^](//' -e 's/)$//' | grep -vE '^(https?:|mailto:)' || true)
done < <(find . -type f -name '*.md' -print0)
(( failures == 0 )) && pass 'documentation links'

while IFS= read -r -d '' file; do
  [[ -s "$file" ]] || fail "empty file: ${file#./}"
done < <(find . -type f -not -path './.git/*' -print0)
(( failures == 0 )) && pass 'no empty files'

while IFS= read -r -d '' file; do
  bash -n "$file" || fail "Bash syntax: ${file#./}"
done < <(find . -type f \( -name '*.sh' -o -path './.config/yadm/bootstrap' -o -path './.local/bin/workstation-*' -o -path './.local/bin/sway-*' \) -print0)
(( failures == 0 )) && pass 'Bash syntax'

if command -v shellcheck >/dev/null 2>&1; then
  mapfile -d '' shell_files < <(find . -type f \( -name '*.sh' -o -path './.config/yadm/bootstrap' -o -path './.local/bin/workstation-*' -o -path './.local/bin/sway-*' \) -print0)
  shellcheck -x "${shell_files[@]}" || fail 'ShellCheck findings'
  (( failures == 0 )) && pass 'ShellCheck'
else
  printf '[SKIP] shellcheck is not installed\n'
fi

python3 - <<'PY' || failures=1
import json, pathlib, re, tomllib, xml.etree.ElementTree as ET
root = pathlib.Path('.')
json.loads((root / '.config/waybar/config.jsonc').read_text())
ET.parse(root / '.config/bat/themes/Catppuccin Mocha.tmTheme')
for path in root.rglob('*.toml'):
    tomllib.loads(path.read_text())
for manifest in (root / '.config/fedora-sway-atomic/flatpaks-required.txt', root / '.config/fedora-sway-atomic/flatpaks-optional.txt'):
    for line_no, line in enumerate(manifest.read_text().splitlines(), 1):
        if not line or line.startswith('#'):
            continue
        app_id, sep, purpose = line.partition('|')
        assert sep and purpose, f'{manifest}:{line_no}: expected app-id|purpose'
        assert re.fullmatch(r'[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+){2,}', app_id), f'{manifest}:{line_no}: invalid ID {app_id}'
print('[PASS] JSON, TOML, and manifest structure')
PY

mapfile -t all_ids < <(sed -e '/^#/d' -e '/^$/d' .config/fedora-sway-atomic/flatpaks-*.txt | cut -d'|' -f1)
if [[ "$(printf '%s\n' "${all_ids[@]}" | sort | uniq -d | wc -l)" -eq 0 ]]; then
  pass 'Flatpak manifests contain no duplicate IDs'
else
  fail 'duplicate Flatpak IDs detected'
fi
if printf '%s\n' "${all_ids[@]}" | grep -Fxq com.borgbase.Vorta; then
  pass 'Vorta is present'
else
  fail 'Vorta is missing'
fi
if grep -qi borgmatic .config/fedora-sway-atomic/flatpaks-*.txt toolbox/Containerfile; then
  fail 'Borgmatic found in an implementation manifest'
else
  pass 'Borgmatic is absent from implementation manifests'
fi

if find . -type f \( -name '*.container' -o -name '*.volume' -o -name '*.network' -o -name '*.kube' \) -print -quit | grep -q .; then
  fail 'Quadlet unit detected'
else
  pass 'no Quadlet units'
fi

placeholder_pattern='TO''DO|FIX''ME|CHANGE''ME|YOUR_[A-Z_]+|INSERT_[A-Z_]+'
if grep -RInE "($placeholder_pattern)" --exclude-dir=.git .; then
  fail 'placeholder marker detected'
else
  pass 'no placeholder markers'
fi

if grep -RIl $'\r' --exclude-dir=.git . | grep -q .; then
  fail 'CRLF line ending detected'
else
  pass 'LF line endings'
fi

if grep -RInE '[[:blank:]]+$' --exclude-dir=.git .; then
  fail 'trailing whitespace detected'
else
  pass 'no trailing whitespace'
fi

while IFS= read -r -d '' file; do
  [[ -s "$file" ]] || continue
  [[ "$(tail -c1 "$file" | od -An -c | tr -d ' \n')" == '\n' ]] || fail "missing final newline: ${file#./}"
done < <(find . -type f -not -path './.git/*' -print0)
(( failures == 0 )) && pass 'final newlines'

expected_executables=(
  .config/yadm/bootstrap
  .local/bin/sway-power-menu
  .local/bin/sway-screenshot
  .local/bin/workstation-bootstrap
  .local/bin/workstation-shell
  scripts/validate-repo.sh
)
for file in "${expected_executables[@]}"; do
  [[ -x "$file" ]] || fail "executable bit missing: $file"
done
(( failures == 0 )) && pass 'executable modes'

# An executable bit on anything else is noise at best and misleading at worst.
while IFS= read -r -d '' candidate; do
  [[ -x "$candidate" ]] || continue
  found=0
  for file in "${expected_executables[@]}"; do
    [[ "$candidate" == "./$file" ]] && found=1 && break
  done
  (( found )) || fail "unexpected executable bit: ${candidate#./}"
done < <(find . -type f -perm -u+x -not -path './.git/*' -print0)
(( failures == 0 )) && pass 'no spurious executable bits'

containerfile=$(cat toolbox/Containerfile)
for token in zsh zinit deja zsh-syntax-highlighting fzf eza bat ripgrep neovim lazygit tmux yazi starship mise jq tree; do
  grep -qi "$token" <<<"$containerfile" || fail "Toolbx inventory missing token: $token"
done
(( failures == 0 )) && pass 'Toolbx inventory'

# Fedora's /etc/sway/config layers in user snippets with a "*.conf" glob, so any
# other extension is dropped silently and the setting never applies.
while IFS= read -r -d '' snippet; do
  case "$snippet" in
    *.conf) ;;
    *) fail "Sway snippet is not *.conf and would be ignored by layered-include: ${snippet#./}" ;;
  esac
done < <(find .config/sway/config.d -type f -print0 2>/dev/null)
(( failures == 0 )) && pass 'Sway snippet extensions'

if [[ -d .config/swayidle ]]; then
  fail 'user swayidle config is present but /etc/sway/config.d/90-swayidle.conf passes explicit timeouts'
else
  pass 'no shadowed swayidle config'
fi

# versions.env is the single source of truth for Toolbx pins. The Containerfile
# keeps matching ARG defaults so it also builds standalone, and those defaults
# must not drift from versions.env.
set -a
# shellcheck source=/dev/null
. .config/fedora-sway-atomic/versions.env
set +a
for key in FEDORA_RELEASE DEJA_VERSION LAZYGIT_VERSION EZA_VERSION STARSHIP_VERSION YAZI_VERSION \
  ZINIT_VERSION ZINIT_COMMIT ZSH_SYNTAX_HIGHLIGHTING_VERSION ZSH_SYNTAX_HIGHLIGHTING_COMMIT MISE_VERSION; do
  value="${!key:-}"
  [[ -n "$value" ]] || fail "versions.env does not define $key"
  grep -qE "^ARG ${key}=${value//./\\.}$" toolbox/Containerfile \
    || fail "Containerfile ARG $key does not match versions.env ($value)"
done
(( failures == 0 )) && pass 'Toolbx pins are consistent with versions.env'

[[ "$NERD_FONT_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail 'NERD_FONT_SHA256 must be a 64-character lowercase sha256'
if grep -q 'SHA256SUMS' .local/share/fedora-sway-atomic/bootstrap-lib.sh; then
  fail 'font installer still trusts a release-supplied checksum file'
else
  pass 'font installer verifies against the pinned digest'
fi

if (( failures )); then
  printf '\nRepository validation failed.\n' >&2
  exit 1
fi
printf '\nRepository validation passed.\n'
