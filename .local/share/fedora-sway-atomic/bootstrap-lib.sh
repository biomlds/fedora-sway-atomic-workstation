#!/usr/bin/env bash

readonly REQUIRED_FLATPAKS="$PROJECT_HOME/flatpaks-required.txt"
readonly OPTIONAL_FLATPAKS="$PROJECT_HOME/flatpaks-optional.txt"
readonly HOST_PACKAGES="$PROJECT_HOME/host-packages.txt"
readonly REPO_ROOT="${FSA_REPO_ROOT:-$HOME}"
readonly CONTAINERFILE="$REPO_ROOT/toolbox/Containerfile"
readonly FONT_FAMILY='JetBrainsMono Nerd Font'
readonly FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont-$NERD_FONT_VERSION"
readonly FONT_ARCHIVE='JetBrainsMono.zip'
readonly FONT_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}"

color_enabled=0
[[ -t 1 ]] && color_enabled=1

_log() {
  local level="$1" color="$2"; shift 2
  if (( color_enabled )); then
    printf '\033[%sm[%s]\033[0m %s\n' "$color" "$level" "$*"
  else
    printf '[%s] %s\n' "$level" "$*"
  fi
}
info() { _log INFO '1;34' "$@"; }
ok() { _log OK '1;32' "$@"; }
warn() { _log WARN '1;33' "$@" >&2; }
error() { _log ERROR '1;31' "$@" >&2; }
die() { error "$@"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

read_data_lines() {
  local file="$1"
  sed -e 's/[[:space:]]*$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$file"
}

flatpak_ids() {
  local file="$1"
  read_data_lines "$file" | cut -d'|' -f1
}

is_atomic_fedora() {
  [[ -e /run/ostree-booted ]] && [[ -r /etc/fedora-release ]]
}

assert_supported_host() {
  if is_atomic_fedora; then
    return 0
  fi
  if [[ "${FSA_ALLOW_NON_ATOMIC:-0}" == 1 ]]; then
    warn 'non-Atomic host override enabled; host package convergence will be skipped'
    return 0
  fi
  die 'this bootstrap targets Fedora Atomic (/run/ostree-booted); set FSA_ALLOW_NON_ATOMIC=1 only for review/testing'
}

missing_host_packages() {
  local package
  while IFS= read -r package; do
    rpm -q "$package" >/dev/null 2>&1 || printf '%s\n' "$package"
  done < <(read_data_lines "$HOST_PACKAGES")
}

font_installed() {
  command_exists fc-match && fc-match -f '%{family}\n' "$FONT_FAMILY" 2>/dev/null | grep -Fq "$FONT_FAMILY"
}

flatpak_installed() {
  flatpak info --system "$1" >/dev/null 2>&1 || flatpak info --user "$1" >/dev/null 2>&1
}

container_exists() {
  command_exists toolbox && command_exists podman && podman container exists "$TOOLBOX_NAME"
}

image_exists() {
  command_exists podman && podman image exists "$TOOLBOX_IMAGE:$TOOLBOX_IMAGE_VERSION"
}

plan_host() {
  info 'Host integration packages'
  if ! command_exists rpm; then
    warn 'rpm is unavailable; package state cannot be inspected'
    return
  fi
  local -a missing=()
  mapfile -t missing < <(missing_host_packages)
  if ((${#missing[@]} == 0)); then
    ok 'all host integration packages are present'
  else
    printf '  would layer: %s\n' "${missing[*]}"
  fi
}

plan_flatpaks() {
  local with_optional="$1" file id role state
  info 'Required Flatpaks'
  while IFS='|' read -r id role; do
    [[ -n "$id" ]] || continue
    state='would install'
    command_exists flatpak && flatpak_installed "$id" && state='installed'
    printf '  %-42s %-13s %s\n' "$id" "$state" "$role"
  done < <(read_data_lines "$REQUIRED_FLATPAKS")

  if (( with_optional )); then
    info 'Optional Flatpaks requested'
    while IFS='|' read -r id role; do
      [[ -n "$id" ]] || continue
      state='would install'
      command_exists flatpak && flatpak_installed "$id" && state='installed'
      printf '  %-42s %-13s %s\n' "$id" "$state" "$role"
    done < <(read_data_lines "$OPTIONAL_FLATPAKS")
  else
    info 'Optional Flatpaks are not selected; pass --with-optional to include them'
  fi
}

plan_font() {
  info 'Desktop font'
  if font_installed; then
    ok "$FONT_FAMILY is installed"
  else
    printf '  would install Nerd Fonts %s from %s/%s (sha256 %s)\n' \
      "$NERD_FONT_VERSION" "$FONT_BASE_URL" "$FONT_ARCHIVE" "${NERD_FONT_SHA256:-unpinned}"
  fi
}

plan_toolbox() {
  info 'Versioned Toolbx'
  printf '  image:     %s:%s (%s)\n' "$TOOLBOX_IMAGE" "$TOOLBOX_IMAGE_VERSION" "$(image_exists && printf present || printf 'would build')"
  printf '  container: %s (%s)\n' "$TOOLBOX_NAME" "$(container_exists && printf present || printf 'would create')"
}

stage_plan() {
  local with_optional="$1"
  info "Fedora Sway Atomic workstation $PROJECT_VERSION plan"
  is_atomic_fedora || warn 'current environment is not a booted Fedora Atomic deployment'
  plan_host
  plan_flatpaks "$with_optional"
  plan_font
  plan_toolbox
  info 'No changes were made.'
}

ensure_flathub() {
  command_exists flatpak || die 'flatpak is not available in the booted deployment; reboot after host package layering and re-run apply'
  if flatpak remotes --system --columns=name 2>/dev/null | grep -Fxq flathub; then
    ok 'Flathub system remote is configured'
  else
    info 'adding the Flathub system remote'
    sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  fi
  if flatpak remotes --user --columns=name 2>/dev/null | grep -Fxq flathub; then
    warn 'a per-user Flathub remote also exists; remove it with: flatpak remote-delete --user flathub'
  fi
}

apply_host_packages() {
  if [[ "${FSA_ALLOW_NON_ATOMIC:-0}" == 1 ]] && ! is_atomic_fedora; then
    warn 'skipping host package changes on non-Atomic host'
    return
  fi
  local -a missing=()
  mapfile -t missing < <(missing_host_packages)
  if ((${#missing[@]} == 0)); then
    ok 'host package deployment is already converged'
    return
  fi
  info "layering missing host packages: ${missing[*]}"
  sudo rpm-ostree install --idempotent "${missing[@]}"
  touch "${XDG_STATE_HOME:-$HOME/.local/state}/fedora-sway-atomic-reboot-required" 2>/dev/null || {
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}"
    touch "${XDG_STATE_HOME:-$HOME/.local/state}/fedora-sway-atomic-reboot-required"
  }
  warn 'a new rpm-ostree deployment was created; reboot after apply'
}

install_flatpak_manifest() {
  local file="$1" id role
  while IFS='|' read -r id role; do
    [[ -n "$id" ]] || continue
    if flatpak_installed "$id"; then
      ok "$id is already installed"
    else
      info "installing $id ($role)"
      sudo flatpak install --system --noninteractive --or-update flathub "$id"
    fi
  done < <(read_data_lines "$file")
}

install_font() {
  if font_installed; then
    ok "$FONT_FAMILY is already installed"
    return
  fi
  command_exists curl || die 'curl is required to install the font'
  command_exists unzip || die 'unzip is required to install the font'
  [[ "$NERD_FONT_SHA256" =~ ^[0-9a-f]{64}$ ]] || die 'NERD_FONT_SHA256 is unset or malformed in versions.env'
  local work
  work=$(mktemp -d)
  trap 'rm -rf "${work:-}"' RETURN
  info "downloading Nerd Fonts $NERD_FONT_VERSION"
  curl --fail --location --silent --show-error --retry 3 "$FONT_BASE_URL/$FONT_ARCHIVE" -o "$work/$FONT_ARCHIVE"
  printf '%s  %s\n' "$NERD_FONT_SHA256" "$work/$FONT_ARCHIVE" | sha256sum --check --status \
    || die "$FONT_ARCHIVE digest does not match NERD_FONT_SHA256; refusing to install"
  mkdir -p "$FONT_DIR"
  unzip -q -j "$work/$FONT_ARCHIVE" '*.ttf' -d "$FONT_DIR"
  fc-cache -f "$FONT_DIR" >/dev/null
  font_installed || die "$FONT_FAMILY did not register with fontconfig"
  ok "installed $FONT_FAMILY $NERD_FONT_VERSION"
}

toolbox_build_args() {
  printf '%s\n' \
    "FEDORA_RELEASE=$FEDORA_RELEASE" \
    "DEJA_VERSION=$DEJA_VERSION" \
    "LAZYGIT_VERSION=$LAZYGIT_VERSION" \
    "EZA_VERSION=$EZA_VERSION" \
    "STARSHIP_VERSION=$STARSHIP_VERSION" \
    "YAZI_VERSION=$YAZI_VERSION" \
    "ZINIT_VERSION=$ZINIT_VERSION" \
    "ZINIT_COMMIT=$ZINIT_COMMIT" \
    "ZSH_SYNTAX_HIGHLIGHTING_VERSION=$ZSH_SYNTAX_HIGHLIGHTING_VERSION" \
    "ZSH_SYNTAX_HIGHLIGHTING_COMMIT=$ZSH_SYNTAX_HIGHLIGHTING_COMMIT" \
    "MISE_VERSION=$MISE_VERSION"
}

build_toolbox() {
  command_exists podman || die 'podman is required to build the workstation image'
  [[ -r "$CONTAINERFILE" ]] || die "missing Containerfile: $CONTAINERFILE"
  if image_exists; then
    ok "$TOOLBOX_IMAGE:$TOOLBOX_IMAGE_VERSION already exists"
  else
    local -a build_args=()
    mapfile -t build_args < <(toolbox_build_args)
    info "building $TOOLBOX_IMAGE:$TOOLBOX_IMAGE_VERSION"
    podman build --pull=always \
      "${build_args[@]/#/--build-arg=}" \
      --label "org.opencontainers.image.version=$TOOLBOX_IMAGE_VERSION" \
      --tag "$TOOLBOX_IMAGE:$TOOLBOX_IMAGE_VERSION" \
      --file "$CONTAINERFILE" "$REPO_ROOT"
  fi
  if container_exists; then
    ok "Toolbx $TOOLBOX_NAME already exists"
  else
    info "creating Toolbx $TOOLBOX_NAME"
    toolbox create --image "$TOOLBOX_IMAGE:$TOOLBOX_IMAGE_VERSION" "$TOOLBOX_NAME"
  fi
  toolbox run --container "$TOOLBOX_NAME" bat cache --build >/dev/null
  ok 'rebuilt the bat syntax/theme cache'
}

stage_apply() {
  local with_optional="$1"
  assert_supported_host
  command_exists sudo || die 'sudo is required by apply for rpm-ostree layering and system Flatpak installation'
  info "converging Fedora Sway Atomic workstation $PROJECT_VERSION"
  apply_host_packages
  if command_exists flatpak; then
    ensure_flathub
    install_flatpak_manifest "$REQUIRED_FLATPAKS"
    (( with_optional )) && install_flatpak_manifest "$OPTIONAL_FLATPAKS"
  else
    warn 'Flatpak was layered into a pending deployment; reboot and run apply again'
  fi
  if command_exists fc-match && command_exists curl && command_exists unzip; then
    install_font
  else
    warn 'font prerequisites are in a pending deployment; reboot and run apply again'
  fi
  if command_exists podman && command_exists toolbox; then
    build_toolbox
  else
    warn 'Podman or Toolbx is unavailable; reboot and run apply again'
  fi
  stage_check "$with_optional" || warn 'some checks remain incomplete; a pending deployment may require reboot'
  local marker="${XDG_STATE_HOME:-$HOME/.local/state}/fedora-sway-atomic-reboot-required"
  if [[ -e "$marker" ]]; then
    warn "reboot required; remove $marker after booting the new deployment"
  fi
}

check_command() {
  local command="$1" label="${2:-$1}"
  if command_exists "$command"; then
    ok "$label available"
  else
    error "$label missing"
    return 1
  fi
}

check_flatpak_manifest() {
  local file="$1" failures=0 id role
  while IFS='|' read -r id role; do
    [[ -n "$id" ]] || continue
    if flatpak_installed "$id"; then
      ok "$id installed"
    else
      error "$id missing ($role)"
      failures=1
    fi
  done < <(read_data_lines "$file")
  return "$failures"
}

stage_check() {
  local with_optional="$1" failures=0
  info 'running local workstation checks'
  is_atomic_fedora || { error 'not booted into a Fedora Atomic deployment'; failures=1; }
  for command in sway waybar rofi dunst foot kanshi swaylock swayidle flatpak podman toolbox; do
    check_command "$command" || failures=1
  done
  if font_installed; then
    ok "$FONT_FAMILY registered"
  else
    error "$FONT_FAMILY missing"
    failures=1
  fi
  check_flatpak_manifest "$REQUIRED_FLATPAKS" || failures=1
  if (( with_optional )); then
    check_flatpak_manifest "$OPTIONAL_FLATPAKS" || failures=1
  fi
  if image_exists; then
    ok 'versioned Toolbx image present'
  else
    error 'versioned Toolbx image missing'
    failures=1
  fi
  if container_exists; then
    ok 'versioned Toolbx container present'
  else
    error 'versioned Toolbx container missing'
    failures=1
  fi
  if (( failures )); then
    error 'local checks failed'
    return 1
  fi
  ok 'local checks passed'
}

validate_flatpak_manifest_online() {
  local file="$1" id role failures=0
  while IFS='|' read -r id role; do
    [[ -n "$id" ]] || continue
    if flatpak remote-info --system flathub "$id" >/dev/null 2>&1; then
      ok "$id resolves on Flathub"
    else
      error "$id did not resolve on Flathub"
      failures=1
    fi
  done < <(read_data_lines "$file")
  return "$failures"
}

effective_sway_config() {
  local user_config="${XDG_CONFIG_HOME:-$HOME/.config}/sway/config"
  if [[ -r "$user_config" ]]; then
    printf '%s\n' "$user_config"
  else
    printf '/etc/sway/config\n'
  fi
}

verify_sway_configuration() {
  local failures=0 config snippet_dir
  snippet_dir="${XDG_CONFIG_HOME:-$HOME/.config}/sway/config.d"
  config=$(effective_sway_config)
  [[ -x /usr/libexec/sway/layered-include ]] || warn 'Fedora layered-include helper is absent; user config.d snippets may be ignored'
  if sway --validate --config "$config" >/dev/null 2>&1; then
    ok "Sway configuration validates ($config)"
  else
    error "Sway configuration validation failed ($config)"
    failures=1
  fi
  if [[ -d "$snippet_dir" ]]; then
    while IFS= read -r -d '' snippet; do
      case "$snippet" in
        *.conf) ;;
        *)
          error "snippet is not *.conf and would be ignored by layered-include: ${snippet##*/}"
          failures=1
          ;;
      esac
    done < <(find "$snippet_dir" -maxdepth 1 -type f -print0)
  else
    error "user Sway snippet directory is missing: $snippet_dir"
    failures=1
  fi
  return "$failures"
}

verify_toolbox_commands() {
  # The single quotes are intentional: this script runs inside the container.
  # shellcheck disable=SC2016
  local script='set -e; for c in zsh git fzf eza bat rg nvim lazygit tmux yazi starship mise jq tree deja; do command -v "$c" >/dev/null; done; test -r /usr/local/share/zinit/zinit.zsh; test -r /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; bat --list-themes | grep -Fxq "Catppuccin Mocha"'
  toolbox run --container "$TOOLBOX_NAME" bash -lc "$script"
}

stage_verify() {
  local with_optional="$1" failures=0
  stage_check "$with_optional" || failures=1
  info 'running deep workstation verification'
  if command_exists sway; then
    verify_sway_configuration || failures=1
  fi
  if command_exists jq; then
    if jq empty "$HOME/.config/waybar/config.jsonc"; then
      ok 'Waybar JSON validates'
    else
      error 'Waybar JSON is invalid'
      failures=1
    fi
  fi
  if command_exists flatpak && flatpak remotes --system --columns=name | grep -Fxq flathub; then
    validate_flatpak_manifest_online "$REQUIRED_FLATPAKS" || failures=1
    if (( with_optional )); then
      validate_flatpak_manifest_online "$OPTIONAL_FLATPAKS" || failures=1
    fi
  else
    error 'Flathub system remote is unavailable'
    failures=1
  fi
  if container_exists; then
    if verify_toolbox_commands; then
      ok 'Toolbx command inventory validates'
    else
      error 'Toolbx command inventory failed'
      failures=1
    fi
  fi
  if (( failures )); then
    error 'deep verification failed'
    return 1
  fi
  ok 'deep verification passed'
}
