# 1. PROFILE STARTUP (Keep this at the very top for now to see improvements)
zmodload zsh/zprof

# 2. ENVIRONMENT VARIABLES (No impact on speed, keep them here)
export ZSH="$HOME/.oh-my-zsh"
export TERM=kitty
export EDITOR=nvim
export VISUAL="$EDITOR"
export W3M_HOME=$HOME/.config/w3m
export GOPATH=~/codespace/go

# 3. PATHS (Adding all at once is slightly faster than multiple exports)
path=(
  "$HOME/.opencode/bin"
  "$HOME/codespace/zig/zig-source"
  "$HOME/codespace/zig/zig-origin/"
  "$HOME/.npm-global/bin"
  "$HOME/Downloads/.vscode/"
  "$GOPATH/bin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/codespace/gnvim/target/optimized"
  $path
)
export PATH

# 4. OH-MY-ZSH (The heavy lifter)
plugins=(git archlinux zoxide sudo zsh-autosuggestions zsh-syntax-highlighting)

# Speed up OMZ by disabling auto-update checks on every shell start
DISABLE_AUTO_UPDATE="true"
source $ZSH/oh-my-zsh.sh

# 5. CACHED EVALS (Luarocks is slow, cache the output)
LUAROCKS_CACHE="$HOME/.cache/luarocks_init.zsh"
if [[ ! -f "$LUAROCKS_CACHE" ]]; then
    luarocks path --bin > "$LUAROCKS_CACHE"
fi
source "$LUAROCKS_CACHE"

# 6. LAZY LOAD ANGULAR (Sourcing 'ng completion' every time is a killer)
ng() {
    unfunction ng
    source <(command ng completion script)
    command ng "$@"
}

# 7. ALIASES (These are nearly instant)
alias read="gum pager <"
alias write="gum write >"
alias open="xdg-open"
alias ch="chmod +x"
alias v="nvim"
alias x="clear"
alias ls="eza --icons"
alias gl="git log"
alias lt="eza --icons --tree --long"
alias code="opencode"
alias cd="z"
alias gi="git add ."
alias gs="git status"
alias go="git init"
alias gc="git commit -m"
alias gp="git push -u origin"
alias cm="cmatrix"
alias fs="fastfetch"
alias y="yazi"
alias th="thunar ."
alias t="touch"
alias mk="mkdir"
alias :q="exit"
alias rm="rm -rf"
alias fa="fastfetch"
alias s="search"
alias ki="kitty @ set-tab-title"

## for starship

STARSHIP_CACHE="$HOME/.cache/starship_init.zsh"
if [[ ! -f "$STARSHIP_CACHE" ]]; then
    starship init zsh > "$STARSHIP_CACHE"
fi
source "$STARSHIP_CACHE"

# 8. PROMPT
#export PS1="%{%F{243}%}%n%{%F{245}%}@%{%F{249}%}%m %{%F{254}%}%1~ %{%f%}$ "
