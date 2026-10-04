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
  docs/INSTALL.md docs/HARDENING.md docs/TESTED-HARDWARE.md docs/THEMING.md
  .gitconfig .gitignore .config/yadm/skip .config/lazygit/config.yml
  .config/kdeglobals
  .config/eza/theme.yaml .config/qt5ct/qt5ct.conf
  .config/qt5ct/colors/catppuccin-mocha-sapphire.conf
  .config/nvim/init.lua .config/nvim/colors/catppuccin-mocha.lua
  .config/nvim/lua/catppuccin/init.lua .config/nvim/lua/catppuccin/VENDORED.md
  .config/nvim/lua/catppuccin/palettes/mocha.lua
  .var/app/com.visualstudio.code/config/Code/User/settings.json
)
for file in "${required_files[@]}"; do
  [[ -s "$file" ]] || fail "missing or empty required file: $file"
done
(( failures == 0 )) && pass 'required file inventory'

# Every relative Markdown link must resolve, so a renamed document cannot leave
# a dangling pointer behind. A link may carry a "#fragment": the file part must
# exist, and the fragment must match a heading in the target, so a renamed
# section cannot leave a dangling anchor behind either.
slugify() { tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9 -]//g' -e 's/ \{1,\}/-/g' -e 's/^-//' -e 's/-$//'; }
heading_slugs() { grep -hE '^#{1,6} ' "$1" | sed -E 's/^#{1,6} +//' | slugify; }
while IFS= read -r -d '' doc; do
  doc_dir=$(dirname -- "$doc")
  while IFS= read -r target; do
    path=${target%%#*}
    fragment=${target#"$path"}
    fragment=${fragment#\#}
    if [[ ! -e "$doc_dir/$path" ]]; then
      fail "broken link in ${doc#./}: $target"
      continue
    fi
    if [[ -n "$fragment" ]] && [[ -f "$doc_dir/$path" ]]; then
      heading_slugs "$doc_dir/$path" | grep -Fxq "$(printf '%s' "$fragment" | slugify)" \
        || fail "broken anchor in ${doc#./}: $target"
    fi
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
json.loads((root / '.var/app/com.visualstudio.code/config/Code/User/settings.json').read_text())
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

# Repository hygiene is asserted over our own files. The vendored third-party
# Catppuccin Neovim tree is deliberately excluded: it must stay byte-identical to
# the pinned upstream commit, so rewriting it to satisfy a style gate would make
# the pin meaningless. It is still covered, by the palette and pin gates below.
hygiene_files() {
  find . -type f -not -path './.git/*' -not -path './.config/nvim/lua/catppuccin/*' -print0
}

placeholder_pattern='TO''DO|FIX''ME|CHANGE''ME|YOUR_[A-Z_]+|INSERT_[A-Z_]+'
if hygiene_files | xargs -0 -r grep -InE "($placeholder_pattern)"; then
  fail 'placeholder marker detected'
else
  pass 'no placeholder markers'
fi

if hygiene_files | xargs -0 -r grep -Il $'\r' | grep -q .; then
  fail 'CRLF line ending detected'
else
  pass 'LF line endings'
fi

if hygiene_files | xargs -0 -r grep -InE '[[:blank:]]+$'; then
  fail 'trailing whitespace detected'
else
  pass 'no trailing whitespace'
fi

while IFS= read -r -d '' file; do
  [[ -s "$file" ]] || continue
  [[ "$(tail -c1 "$file" | od -An -c | tr -d ' \n')" == '\n' ]] || fail "missing final newline: ${file#./}"
done < <(hygiene_files)
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

# yadm is not a Fedora package, in Fedora or in Fedora EPEL, so it cannot arrive
# through rpm-ostree at all. It is installed as one script pinned by commit and
# digest. versions.env holds the pin the bootstrap enforces; the install guides
# repeat it because those steps have to work before this repository is cloned.
yadm_bad=0
[[ -n "${YADM_VERSION:-}" ]] || { fail 'versions.env does not define YADM_VERSION'; yadm_bad=1; }
[[ "$YADM_COMMIT" =~ ^[0-9a-f]{40}$ ]] || { fail 'YADM_COMMIT must be a 40-character lowercase commit sha'; yadm_bad=1; }
[[ "$YADM_SHA256" =~ ^[0-9a-f]{64}$ ]] || { fail 'YADM_SHA256 must be a 64-character lowercase sha256'; yadm_bad=1; }
(( yadm_bad == 0 )) && pass 'yadm pins are well formed'

yadm_bad=0
for doc in docs/INSTALL.md docs/RECOVERY.md; do
  for pin in "YADM_VERSION=$YADM_VERSION" "YADM_COMMIT=$YADM_COMMIT" "YADM_SHA256=$YADM_SHA256"; do
    grep -qF "$pin" "$doc" || { fail "$doc does not carry the pinned $pin"; yadm_bad=1; }
  done
done
(( yadm_bad == 0 )) && pass 'yadm pins in the install guides match versions.env'

# Regression guard for the defect that made first installation impossible.
# rpm-ostree rejects a transaction containing a name no repository provides, and
# the call was unguarded under `set -e`, so the whole apply aborted. The scan is
# anchored to command position so prose explaining that the command is wrong does
# not trip it, and CHANGELOG is skipped because it quotes the bad command on
# purpose.
yadm_bad=0
if grep -qx 'yadm' .config/fedora-sway-atomic/host-packages.txt; then
  fail 'host-packages.txt lists yadm; no Fedora package provides it, so rpm-ostree cannot resolve it'
  yadm_bad=1
fi
if grep -rn --include='*.md' --exclude=CHANGELOG.md \
  -E '^[[:space:]]*(sudo[[:space:]]+)?rpm-ostree install yadm' .; then
  fail 'documentation still instructs "rpm-ostree install yadm"'
  yadm_bad=1
fi
(( yadm_bad == 0 )) && pass 'yadm is not treated as a Fedora package'

# rpm-ostree layers the whole list or none of it, so one wrong entry costs the
# user every host package. This is an offline lint rather than a dependency
# resolution: it catches names that cannot be packages, not a plausible name that
# happens not to exist. Probing stays the bootstrap's job.
yadm_bad=0
while IFS= read -r package; do
  if [[ ! "$package" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]]; then
    fail "host-packages.txt entry is not a package name: $package"
    yadm_bad=1
  fi
done < <(grep -vE '^[[:space:]]*(#|$)' .config/fedora-sway-atomic/host-packages.txt)
(( yadm_bad == 0 )) && pass 'host package manifest holds package names only'

# The digest must gate the executable, and the fetch must address the pinned
# commit: yadm's develop branch is not byte-identical to its tags and publishes
# no release assets, so a branch or tag URL would change the tool silently.
yadm_bad=0
for symbol in 'install_yadm()' 'yadm_installed()' 'yadm_script_digest()'; do
  grep -qF "$symbol" .local/share/fedora-sway-atomic/bootstrap-lib.sh \
    || { fail "bootstrap-lib.sh does not define $symbol"; yadm_bad=1; }
done
grep -qE '^[[:space:]]*install_yadm \|\|' .local/share/fedora-sway-atomic/bootstrap-lib.sh \
  || { fail 'stage_apply does not reconcile yadm'; yadm_bad=1; }
grep -qE 'YADM_SCRIPT_URL=.*\$\{YADM_COMMIT\}' .local/share/fedora-sway-atomic/bootstrap-lib.sh \
  || { fail 'the yadm script URL is not pinned to YADM_COMMIT'; yadm_bad=1; }
(( yadm_bad == 0 )) && pass 'bootstrap verifies and repairs the pinned yadm'

# yadm reads .config/yadm/skip, while a plain checkout of this repository reads
# .gitignore. Both files describe the same exclusions, so a divergence would
# let cache data be committed in one workflow but not the other.
strip_comments() { grep -vE '^[[:space:]]*(#|$)' "$1" | sed -e 's/[[:space:]]*$//' | sort; }
if [[ -f .config/yadm/skip && -f .gitignore ]]; then
  if diff -u <(strip_comments .gitignore) <(strip_comments .config/yadm/skip) >/dev/null; then
    pass '.gitignore and yadm skip rules agree'
  else
    fail '.gitignore and .config/yadm/skip have diverged'
  fi
else
  fail 'missing .gitignore or .config/yadm/skip'
fi

# Theme policy. Catppuccin Mocha with the Sapphire accent is a stated goal, not
# an accident, so it is enforced instead of trusted. Gate one rejects any color
# literal that is not a Mocha member; gate two rejects a palette that still
# uses Mocha names but has drifted onto the wrong values, which gate one cannot
# see because every drifted value is itself in-palette.
python3 - <<'PY' || failures=1
import pathlib, re, sys

MOCHA = {
    'rosewater': 'f5e0dc', 'flamingo': 'f2cdcd', 'pink': 'f5c2e7', 'mauve': 'cba6f7',
    'red': 'f38ba8', 'maroon': 'eba0ac', 'peach': 'fab387', 'yellow': 'f9e2af',
    'green': 'a6e3a1', 'teal': '94e2d5', 'sky': '89dceb', 'sapphire': '74c7ec',
    'blue': '89b4fa', 'lavender': 'b4befe', 'text': 'cdd6f4', 'subtext1': 'bac2de',
    'subtext0': 'a6adc8', 'overlay2': '9399b2', 'overlay1': '7f849c', 'overlay0': '6c7086',
    'surface2': '585b70', 'surface1': '45475a', 'surface0': '313244', 'base': '1e1e2e',
    'mantle': '181825', 'crust': '11111b',
}
ALLOWED = set(MOCHA.values())
problems = []

# Every file that is allowed to carry a color literal. Documentation is excluded
# on purpose: it legitimately quotes non-palette colors when explaining a point.
# Comments inside these files are NOT excluded, so a hex value mentioned in a
# comment still has to be a palette member. That is deliberate: it keeps the
# scan free of per-format comment-stripping heuristics, and the alternative is a
# config file that silently drifts out of the palette.
THEME_FILES = [
    '.config/sway/config.d/10-theme.conf',
    '.config/swaylock/config',
    '.config/waybar/style.css',
    '.config/foot/foot.ini',
    '.config/rofi/config.rasi',
    '.local/share/rofi/themes/catppuccin-mocha-sapphire.rasi',
    '.config/dunst/dunstrc',
    '.config/tmux/tmux.conf',
    '.config/yazi/theme.toml',
    '.config/starship.toml',
    '.config/nvim/init.lua',
    '.config/bat/themes/Catppuccin Mocha.tmTheme',
    '.config/lazygit/config.yml',
    '.config/kdeglobals',
    '.gitconfig',
    '.config/eza/theme.yaml',
    '.config/qt5ct/qt5ct.conf',
    '.config/qt5ct/colors/catppuccin-mocha-sapphire.conf',
    '.var/app/com.visualstudio.code/config/Code/User/settings.json',
]

# qt5ct writes eight-digit values as #AARRGGBB: two hex digits of alpha, then
# the six RGB digits. The generic scan below reads eight digits as #RRGGBBAA, so
# these files are named explicitly and decoded the other way round. Getting this
# backwards would read a legal "alpha ff over mantle" value as a bogus colour.
AARRGGBB_FILES = {
    '.config/qt5ct/colors/catppuccin-mocha-sapphire.conf',
}

def normalize(value):
    return value.lower().lstrip('#')

for name in THEME_FILES:
    path = pathlib.Path(name)
    if not path.is_file():
        problems.append(f'{name}: expected theme file is missing')
        continue
    text = path.read_text()

    # In CSS every "#" starts an id selector, and several hex digits alone make
    # a plausible id, so three-digit shorthand is only honoured outside CSS.
    widths = r'(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})'
    if path.suffix == '.css':
        widths = r'(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6})'

    for match in re.finditer(r'#(' + widths + r')\b', text):
        digits = match.group(1).lower()
        if name in AARRGGBB_FILES and len(digits) == 8:
            value = digits[2:]
        else:
            value = digits[:6]
        if value not in ALLOWED:
            line = text.count('\n', 0, match.start()) + 1
            problems.append(f'{name}:{line}: {digits} is not a Catppuccin Mocha color')

    for match in re.finditer(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)', text, re.I):
        value = ''.join(f'{int(part):02x}' for part in match.groups())
        if value not in ALLOWED:
            line = text.count('\n', 0, match.start()) + 1
            problems.append(f'{name}:{line}: rgb({value}) is not a Catppuccin Mocha color')

    # foot(1) takes bare hex without a leading "#".
    if name.endswith('foot.ini'):
        for match in re.finditer(r'^[A-Za-z][\w-]*\s*=\s*([0-9a-fA-F]{6})\s*$', text, re.M):
            if match.group(1).lower() not in ALLOWED:
                line = text.count('\n', 0, match.start()) + 1
                problems.append(f'{name}:{line}: {match.group(1).lower()} is not a Catppuccin Mocha color')

def check_palette(label, found, require_all):
    for key, value in found.items():
        expected = MOCHA.get(key)
        if expected is None:
            problems.append(f'{label}: {key} is not a Catppuccin Mocha color name')
        elif expected != value:
            problems.append(f'{label}: {key} is #{value}, drifted from Mocha #{expected}')
    missing = sorted(set(MOCHA) - set(found))
    if require_all and missing:
        problems.append(f'{label}: palette is missing {", ".join(missing)}')

sway = pathlib.Path('.config/sway/config.d/10-theme.conf').read_text()
check_palette(
    '.config/sway/config.d/10-theme.conf',
    {m.group(1): m.group(2).lower() for m in
     re.finditer(r'^\s*set\s+\$(\w+)\s+#?([0-9a-fA-F]{6})\s*$', sway, re.M)},
    require_all=True,
)

starship = pathlib.Path('.config/starship.toml').read_text()
block = re.search(r'\[palettes\.catppuccin_mocha\](.*?)(?=\n\[|\Z)', starship, re.S)
if block is None:
    problems.append('.config/starship.toml: missing the [palettes.catppuccin_mocha] block')
else:
    check_palette(
        '.config/starship.toml',
        {m.group(1): m.group(2).lower() for m in
         re.finditer(r'''(\w+)\s*=\s*["']?#([0-9a-fA-F]{6})''', block.group(1))},
        require_all=True,
    )

# Neovim uses the official Catppuccin port, vendored under
# .config/nvim/lua/catppuccin/. That tree is third-party code and is
# deliberately NOT in THEME_FILES: it carries three literals that are not
# palette colours and are never emitted with flavour = "mocha" (a lighten()
# call guarded by a `latte =` branch) or are Neovim's own blend sentinels
# rather than a colour to draw. Hand-editing vendored code would also make the
# commit pin meaningless. What matters is the one thing that decides how Neovim
# looks, so that is what is asserted: the vendored Mocha palette must be exactly
# the canonical 26 values.
nvim_palette = pathlib.Path('.config/nvim/lua/catppuccin/palettes/mocha.lua')
if not nvim_palette.is_file():
    problems.append('.config/nvim/lua/catppuccin/palettes/mocha.lua: vendored palette is missing')
else:
    check_palette(
        '.config/nvim/lua/catppuccin/palettes/mocha.lua',
        {m.group(1): m.group(2).lower() for m in
         re.finditer(r'^\s*(\w+)\s*=\s*"#([0-9a-fA-F]{6})",?\s*$', nvim_palette.read_text(), re.M)},
        require_all=True,
    )

if problems:
    for problem in problems:
        print(f'[FAIL] {problem}', file=sys.stderr)
    sys.exit(1)
print('[PASS] Catppuccin Mocha palette is enforced')
PY

# eza only ever parses one of its two candidate filenames. In
# src/options/theme.rs, ThemeConfig::deduce probes theme.yml first but returns
# ThemeConfig::default() when it finds one, discarding the contents; only the
# theme.yaml branch calls from_path and actually loads the file. So a correctly
# maintained theme.yml renders as eza's stock colours and looks like a working
# theme that is merely boring, which is why the filename is pinned here. Both
# names are probed, .yml first, so leaving the old file behind would shadow the
# new one rather than being harmless.
[[ -e .config/eza/theme.yaml ]] || fail 'eza theme must live at .config/eza/theme.yaml'
if [[ -e .config/eza/theme.yml ]]; then
  fail '.config/eza/theme.yml exists, but eza ignores that name and would fall back to its default theme'
fi
(( failures == 0 )) && pass 'eza theme uses the filename eza actually parses'

# The Neovim colorscheme is the official Catppuccin port, vendored instead of
# installed through a plugin manager so the palette cannot drift and the offline
# container build cannot fail on a fetch. That guarantee only holds while the
# vendored tree is still core-only and still matches the commit recorded in
# versions.env, so both are checked rather than trusted.
nvim_vendor='.config/nvim/lua/catppuccin'
for required in "$nvim_vendor/init.lua" "$nvim_vendor/palettes/mocha.lua" \
  "$nvim_vendor/lib/compiler.lua" '.config/nvim/colors/catppuccin-mocha.lua'; do
  [[ -f "$required" ]] || fail "vendored Catppuccin core is missing $required"
done
if [[ -d "$nvim_vendor/groups/integrations" ]]; then
  fail 'vendored Catppuccin core still ships groups/integrations (vendoring is core-only)'
fi
if grep -qE 'auto_integrations[[:space:]]*=[[:space:]]*true' .config/nvim/init.lua; then
  fail '.config/nvim/init.lua enables auto_integrations but no integration files are vendored'
fi
[[ "$CATPPUCCIN_NVIM_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
  || fail 'versions.env does not pin CATPPUCCIN_NVIM_COMMIT to a full commit sha'
if [[ -n "$CATPPUCCIN_NVIM_COMMIT" ]]; then
  grep -q "$CATPPUCCIN_NVIM_COMMIT" "$nvim_vendor/VENDORED.md" \
    || fail 'VENDORED.md does not record the CATPPUCCIN_NVIM_COMMIT pin'
fi
(( failures == 0 )) && pass 'vendored Catppuccin Neovim core is pinned and core-only'

# The documentation promises that the VS Code integrated terminal matches foot.
# Both files are in-palette independently, so palette membership alone cannot
# keep that promise; compare the two directly.
python3 - <<'PY' || failures=1
import json, pathlib, re, sys

foot = pathlib.Path('.config/foot/foot.ini').read_text().split('[colors]')[1].split('[')[0]
foot_map = dict(re.findall(
    r'^(regular\d|bright\d|background|foreground|selection-background)\s*=\s*([0-9a-fA-F]{6})',
    foot, re.M))

settings = json.loads(
    pathlib.Path('.var/app/com.visualstudio.code/config/Code/User/settings.json').read_text())
tones = ['Black', 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan', 'White']
vscode_map = {
    'background': settings['terminal.integrated.background'],
    'foreground': settings['terminal.integrated.foreground'],
    'selection-background': settings['terminal.integrated.selectionBackground'],
}
for index, tone in enumerate(tones):
    vscode_map[f'regular{index}'] = settings[f'terminal.integrated.ansi{tone}']
    vscode_map[f'bright{index}'] = settings[f'terminal.integrated.ansiBright{tone}']

mismatches = [
    f'{key}: foot #{value.lower()} but VS Code #{vscode_map.get(key, "<absent>").lower().lstrip("#")}'
    for key, value in sorted(foot_map.items())
    if vscode_map.get(key, '').lstrip('#').lower() != value.lstrip('#').lower()
]
if mismatches:
    for mismatch in mismatches:
        print(f'[FAIL] terminal palette differs between foot and VS Code: {mismatch}', file=sys.stderr)
    sys.exit(1)
print('[PASS] VS Code terminal palette matches foot')
PY

if (( failures )); then
  printf '\nRepository validation failed.\n' >&2
  exit 1
fi
printf '\nRepository validation passed.\n'
