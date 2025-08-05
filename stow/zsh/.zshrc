# Directory Hash
hash -d ev=~/vcs/github.com/evinova
hash -d esdp=~ev/platform-entity-stream-data-plane
hash -d pdr=~ev/platform-perimeter-data-router

# Aliases

alias netCons='lsof -i'                                                                             # netCons:      Show all open TCP/IP sockets
alias flushDNS='dscacheutil -flushcache'                                                            # flushDNS:     Flush out the DNS Cache
alias lsock='sudo /usr/sbin/lsof -i -P'                                                             # lsock:        Display open sockets
alias lsockU='sudo /usr/sbin/lsof -nP | grep UDP'                                                   # lsockU:       Display only open UDP sockets
alias lsockT='sudo /usr/sbin/lsof -nP | grep TCP'                                                   # lsockT:       Display only open TCP sockets
alias ipInfo0='ipconfig getpacket en0'                                                              # ipInfo0:      Get info on connections for en0
alias ipInfo1='ipconfig getpacket en1'                                                              # ipInfo1:      Get info on connections for en1
alias openPorts='sudo lsof -i | grep LISTEN'                                                        # openPorts:    All listening connections
alias showBlocked='sudo ipfw list'                                                                  # showBlocked:  All ipfw rules inc/ blocked IPs
alias sso='p=$(select_aws_profile) && [ -n "$p" ] && aws sso login --profile "$p" || return 1'      # sso:          AWS SSO login
alias rot13="tr 'A-Za-z0-9' 'N-ZA-Mn-za-m5-90-4'"                                                   # rot13:        Simple letter substitution cipher
alias vi=nvim
alias vim=nvim
alias view=termview
alias k=kubectl
alias kx=kubectx
alias kn=kubens
alias ll="ls -l"
alias l="ls"
alias la='ls -a'
alias lal='ls -al'
alias lla='lal'
alias edit='idea -e'

# Recursively list contents of folders
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'

# Function to show the interface IP address
ifip() {
  ifconfig $1 | grep inet | grep broadcast | awk '{print $2}'
}

# Display useful host related informaton
ii() {
  echo -e "\nYou are logged on `hostname`"
  echo -e "\nUsers logged on: " ; w -h
  echo -e "\nCurrent date : " ; date
  echo -e "\nMachine stats : " ; uptime
  echo -e "\nCurrent network location : " ; scselect
  #echo -e "\nDNS Configuration: " ; scutil --dns
  echo
}

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
      *.cow)
        cowsay -f "./$1" "Hello World" ;;
      *)
        bat --style=plain --color=always --line-range :100 "$1" ;;
    esac
  else
    echo "Not a file"
  fi
}

kubens() {
  [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6
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

# Auto CD
setopt autocd                   # Allow changing directories without `cd`

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_find_no_dups
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
zstyle ':fzf-tab:complete:*:*' fzf-preview "
${termview_body}
termview \"\$realpath\"
"
zstyle ':fzf-tab:complete:task:*' fzf-preview 'task --summary $word'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Greeting
if [ "$LC_TERMINAL" = "iTerm2" ] || [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    COWBASE="$HOMEBREW_CELLAR/cowsay"
    COWVER=$(ls "$COWBASE" | sort -V | tail -n 1)
    COWDIR="$COWBASE/$COWVER/share/cowsay/cows/"
    FORTDIR="$HOMEBREW_CELLAR/fortune/9708/share/games/fortunes/"
    fortune -s $FORTDIR | cowsay -W 77 -f $COWDIR$(ls $COWDIR | grep \.cow | gshuf -n1) | lolcat
    echo
fi
