# Directory Hash
hash -d gh=~/vcs/github.com/sailorgeoffrey
hash -d ev=~/vcs/github.com/evinova
hash -d esdp=~ev/platform-entity-stream-data-plane
hash -d pdr=~ev/platform-perimeter-data-router

# Aliases
alias netCons='lsof -i'                                     # netCons:      Show all open TCP/IP sockets
alias flushDNS='dscacheutil -flushcache'                    # flushDNS:     Flush out the DNS Cache
alias lsock='sudo /usr/sbin/lsof -i -P'                     # lsock:        Display open sockets
alias lsockU='sudo /usr/sbin/lsof -nP | grep UDP'           # lsockU:       Display only open UDP sockets
alias lsockT='sudo /usr/sbin/lsof -nP | grep TCP'           # lsockT:       Display only open TCP sockets
alias ipInfo0='ipconfig getpacket en0'                      # ipInfo0:      Get info on connections for en0
alias ipInfo1='ipconfig getpacket en1'                      # ipInfo1:      Get info on connections for en1
alias openPorts='sudo lsof -i | grep LISTEN'                # openPorts:    All listening connections
alias showBlocked='sudo ipfw list'                          # showBlocked:  All ipfw rules inc/ blocked IPs
alias sso='aws sso login'                                   # sso:          AWS SSO login
alias rot13="tr 'A-Za-z0-9' 'N-ZA-Mn-za-m5-90-4'"           # rot13:        Simple letter substitution cipher
alias vi=nvim
alias vim=nvim
alias k=kubectl
alias kx=kubectx
alias kn=kubens
alias l='ls'
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -al'

# Enable color names like $fg[red], %F{blue}, etc.
autoload -Uz colors && colors

# Recursively list contents of folders
lr() {
  ls -R | grep ":$" |
    sed -e 's/:$//' \
        -e 's/[^-][^\/]*\//--/g' \
        -e 's/^/   /' \
        -e 's/-/|/' |
      less
}

# Function to show the interface IP address
ifip() {
  ifconfig $1 | grep inet | grep broadcast | awk '{print $2}'
}

# Fuzzy search selection for an AWS profile
select_aws_profile() {
  command aws configure list-profiles | fzf --prompt="Select AWS profile: "
}

# Set the AWS profile env var
set_aws_profile() {
  export AWS_PROFILE=$(select_aws_profile)
}

# Function to wrap AWS CLI and set a profile if one wasn't specified
aws() {
  # If neither AWS_PROFILE nor AWS_ACCESS_KEY_ID is set...
  if [ -z "$AWS_PROFILE" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    # Check if "--profile" was passed in the args
    for arg in "$@"; do
      if [[ "$arg" == --profile ]]; then
        break
      fi
      if [[ "$arg" == --profile=* ]]; then
        break
      fi
      # Special case: handle `--profile xyz` (two words)
      if [[ "$prev" == --profile ]]; then
        break
      fi
      prev="$arg"
    done

    if [[ "$arg" != --profile && "$arg" != --profile=* && "$prev" != --profile ]]; then
      typeset profile=$(select_aws_profile)
    fi
  fi

  AWS_PROFILE="$profile" command aws "$@"
}

# Load Zsh completion system
autoload -Uz compinit
compinit

# Define _task completion for Go Task
_task() {
  local -a tasks
  tasks=(${(f)"$(task --list | tail -n +2 | sed -E 's/^[* ]*([^:]+):.*$/\1/')"})
  _describe 'task' tasks
}

# Fuzzy File Finder
export FZF_TAB_PREVIEW_OPTS="--height=100% --preview-window=bottom"
source <(fzf --zsh)

# Antidote-managed plugins
source /opt/homebrew/share/antidote/antidote.zsh
antidote load < ~/.zsh_plugins.txt

# AWS CLI bash-style completion bridged to zsh
autoload -Uz bashcompinit && bashcompinit
complete -C $(which aws_completer) aws

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# Auto CD
setopt autocd                   # Allow changing directories without `cd`

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_expire_dups_first   # Clear duplicates when trimming internal hist.
setopt hist_find_no_dups        # Don't display duplicates during searches.
setopt hist_ignore_dups         # Ignore consecutive duplicates.
setopt hist_ignore_all_dups     # Remember only one unique copy of the command.
setopt hist_ignore_space        # Ignore commands that start with a space (for hiding sensitive data)
setopt hist_reduce_blanks       # Remove superfluous blanks.
setopt hist_save_no_dups        # Omit older commands in favor of newer ones.

# Completion styling
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*:*:task:*' menu yes select
zstyle ':completion:*:*:task:*' sort false
zstyle ':completion::complete:*' use-cache on
zstyle ':completion:*' verbose yes
zstyle ':completion:*' format '%d'
zstyle ':fzf-tab:*' fzf-flags --layout=reverse --height=100% --preview-window=right:70%:wrap
zstyle ':fzf-tab:complete:*:*' fzf-preview '~/.zsh/preview.zsh "${realpath:-$word}"'
zstyle ':fzf-tab:complete:task:*' fzf-preview 'task --summary $word'
zstyle ':fzf-tab:complete:aws:*' fzf-preview '$words $word help'
zstyle ':fzf-tab:complete:git:*' fzf-preview '$words help $word'
zstyle ':fzf-tab:complete:kubectl:*' fzf-preview '$words $word --help'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Greeting
if [ "$LC_TERMINAL" = "iTerm2" ] || [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
  COWBASE="$HOMEBREW_CELLAR/cowsay"
  COWVER=$(ls "$COWBASE" | sort -V | tail -n 1)
  COWDIR="$COWBASE/$COWVER/share/cowsay/cows/"
  FORTBASE="$HOMEBREW_CELLAR/fortune"
  FORTVER=$(ls "$FORTBASE" | sort -V | tail -n 1)
  FORTDIR="$FORTBASE/$FORTVER/share/games/fortunes/"
  fortune -s $FORTDIR | cowsay -W 77 -f $COWDIR$(ls $COWDIR | grep \.cow | gshuf -n1) | lolcat
  echo
fi

# Starship Prompt
eval "$(starship init zsh)"
