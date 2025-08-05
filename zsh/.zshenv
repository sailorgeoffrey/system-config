export CLICOLOR=1
# Alternate Colors
# export LSCOLORS=GxFxCxDxBxegedabagaced

PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:${PATH}"

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

export PATH
export KUBE_EDITOR="idea -e -w"
export MODULAR_HOME="$HOME/.modular"
export NVM_DIR="$HOME/.nvm"
