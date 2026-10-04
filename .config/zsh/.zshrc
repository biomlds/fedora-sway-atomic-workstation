# Interactive Zsh for the versioned workstation Toolbx.
[[ -o interactive ]] || return

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS INC_APPEND_HISTORY SHARE_HISTORY
setopt INTERACTIVE_COMMENTS NO_BEEP PROMPT_SUBST

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
mkdir -p "${HISTFILE:h}"

bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"

export FZF_DEFAULT_OPTS="--height=45% --layout=reverse --border=rounded --info=inline --color=bg+:#313244,bg:#1e1e2e,spinner:#74c7ec,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#74c7ec,marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

if [[ -r /usr/local/share/zinit/zinit.zsh ]]; then
  source /usr/local/share/zinit/zinit.zsh
fi

# The Catppuccin zsh-syntax-highlighting theme has to be sourced before
# zsh-syntax-highlighting itself. That plugin builds its highlighters when it
# loads, and style assignments made after that point are silently ignored, so
# the order here is load-bearing rather than stylistic. Sourcing it second
# looks correct and leaves every command the plugin's stock colours.
if [[ -r ${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/themes/catppuccin-mocha.zsh ]]; then
  source ${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/themes/catppuccin-mocha.zsh
fi

if [[ -r /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if command -v deja >/dev/null 2>&1; then
  eval "$(deja init zsh)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

alias ls='eza --group-directories-first --icons=auto'
alias ll='eza --long --all --group --git --group-directories-first --icons=auto'
alias tree='eza --tree --icons=auto'
alias cat='bat --paging=never'
alias grep='rg'
alias lg='lazygit'
alias v='nvim'
alias yz='yazi'
alias c='clear'

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
y() {
  local tmp cwd
  tmp=$(mktemp -t 'yazi-cwd.XXXXXX')
  yazi "$@" --cwd-file="$tmp"
  cwd=$(command cat -- "$tmp" 2>/dev/null)
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}
