if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Directory Hash
hash -d ev=~/vcs/github.com/evinova
hash -d esdp=~ev/platform-entity-stream-data-plane
hash -d pdr=~ev/platform-perimeter-data-router

# Aliases
alias cd='cd -P'
alias ls='ls --color'
alias ll='ls -l'
alias la='ls -a'
alias lal='ls -al'
alias lla='lal'
alias edit='idea -e'
alias vi=nvim
alias vim=nvim
alias view=termview
alias rot13="tr 'A-Za-z0-9' 'N-ZA-Mn-za-m5-90-4'"
alias k=kubectl
alias kx=kubectx
alias kn='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'

export KUBE_EDITOR="idea -e -w"
export MODULAR_HOME="$HOME/.modular"
export NVM_DIR="$HOME/.nvm"
export FZF_TAB_PREVIEW_OPTS="--height=100% --preview-window=bottom"


# Function used to preview files and folders
termview() {
  if [[ -d "$1" ]]; then
    ls --color $1
  elif [[ -f $1 ]]; then
    case "$1" in
      Taskfile.yml)
        task -t "$1" -l ;;
      *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.tiff)
        viu -w 40 -h 20 "$1" ;;
      *.md)
        glow "$1" ;;
      *)
        bat --style=plain --color=always --line-range :100 "$1" ;;
    esac
  else
    echo "Not a file"
  fi
}

select_aws_profile() {
  # Extract profile names from AWS config and credentials files
  local profiles=($(
    {
      [ -f ~/.aws/config ] && sed -n 's/^\[profile \(.*\)]/\1/p' ~/.aws/config
      [ -f ~/.aws/credentials ] && sed -n 's/^\[\(.*\)]/\1/p' ~/.aws/credentials
    } | sort | uniq
  ))

  # Exit if no profiles found
  if [ ${#profiles[@]} -eq 0 ]; then
    echo "No AWS profiles found. Please check your AWS configuration." >&2
    return 1
  fi

  # Display current profile if set
  if [ -n "$AWS_PROFILE" ]; then
    echo "Current AWS profile: $AWS_PROFILE" >&2
  fi

  # Display options
  echo "Select an AWS profile:" >&2
  select profile in "${profiles[@]}" "Quit"; do
    case $profile in
      "Quit")
        echo "Selection cancelled." >&2
        return 1
        ;;
      "")
        echo "Invalid selection. Please try again." >&2
        ;;
      *)
        echo "$profile"
        return 0
        ;;
    esac
  done
}

# Function to set AWS profile
set_aws_profile() {
  local profile=$(select_aws_profile)
  if [ $? -eq 0 ]; then
    export AWS_PROFILE="$profile"
    echo "AWS profile set to: $AWS_PROFILE" >&2
  fi
}

# Alias for SSO login
alias sso='p=$(select_aws_profile) && [ -n "$p" ] && aws sso login --profile "$p" || return 1'

# Function to wrap AWS CLI
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
      local profile=$(select_aws_profile)
      if [ $? -eq 0 ]; then
        export AWS_PROFILE="$profile"
      else
        echo "No profile selected. Exiting." >&2
        return 1
      fi
    fi
  fi

  command aws "$@"
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

# Save the function to text so we can inline it later in the preview
termview_body=$(functions termview)

# Starship Prompt
eval "$(starship init zsh)"

# Fuzzy File Finder
source <(fzf --zsh)

# Antidote-managed plugins
source /opt/homebrew/share/antidote/antidote.zsh
antidote load < ~/.zsh_plugins.txt

fpath+=("/opt/homebrew/share/zsh/site-functions")

# Completion system
autoload -Uz compinit && compinit
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

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

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
zstyle ':fzf-tab:complete:*:*' fzf-preview "
${termview_body}
termview \"\$realpath\"
"
zstyle ':fzf-tab:complete:task:*' fzf-preview 'task --summary $word'

# Add dirs to PATH
path+=(/opt/homebrew/bin)
path+=(~/Documents/bin)
path+=(~/Applications/**/bin)
path+=(~/bin)
path+=(~/.rvm/bin)
path+=(~/.cargo/bin)
path+=(~/.modular/pkg/packages.modular.com_mojo/bin)
path+=(~/.modular/bin)
path+=(~/.local/bin)

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
