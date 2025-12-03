export CLICOLOR=1
# Alternate Colors
# export LSCOLORS=GxFxCxDxBxegedabagaced

# Add dirs to PATH
path+=(~/bin)
path+=(~/.rvm/bin)
path+=(~/.cargo/bin)
path+=(~/.modular/pkg/packages.modular.com_mojo/bin)
path+=(~/.modular/bin)
path+=(~/.local/bin)

# macOS-specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
  path+=(/Library/Frameworks/Python.framework/Versions/3.12/bin)
  path+=(/opt/homebrew/bin)
  path+=(~/Documents/bin)
  path+=(~/Applications/**/bin)
fi

export PATH
export KUBE_EDITOR="idea -e -w"
export MODULAR_HOME="$HOME/.modular"

alias assume=". assume"
