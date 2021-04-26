#!/bin/bash

set -e
shopt -s expand_aliases

## preparations

# check Linux distribution
. /etc/os-release
if [ "$ID" = "alpine" ]; then
    DISTRO=$ID
    PKG_UPDATE_CMD="apk update"
    PKG_INSTALL_CMD="apk add"
elif [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
    DISTRO=$ID
    PKG_UPDATE_CMD="apt update"
    PKG_INSTALL_CMD="apt install -y"
else
    echo "Unknown Linux distribution $ID ($NAME)"
    exit 1
fi

# check root
if [ $(id -u) = "0" ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# install necessities
$SUDO $PKG_UPDATE_CMD
$SUDO $PKG_INSTALL_CMD git


## dotfiles git repo

# clone dotfiles
[ -f  "$HOME/.zshrc" ] && mv $HOME/.zshrc $HOME/.zshrc.bak
[ ! -d "$HOME/.dotfiles" ] && git clone --bare https://github.com/gitolicious/dotfiles.git $HOME/.dotfiles

# create dotfiles alias
alias dotfiles="$(which git) --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME"

# checkout dotfiles
dotfiles checkout
dotfiles pull


## installations

# zsh
$SUDO $PKG_INSTALL_CMD zsh

# oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

# load zsh variables
ZSH=${ZSH:-${HOME}/.oh-my-zsh}
ZSH_CUSTOM=${ZSH_CUSTOM:-${ZSH}/custom}

# oh-my-zsh plugins
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]     && git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]         && git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# oh-my-posh
$SUDO wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
$SUDO chmod +x /usr/local/bin/oh-my-posh

# Meslo Nerd Font
if [ $DISPLAY ]; then
    mkdir -p $HOME/.local/share/fonts
    wget -P $HOME/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf
    wget -P $HOME/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf
    wget -P $HOME/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf
    wget -P $HOME/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf
    $SUDO $PKG_INSTALL_CMD fontconfig
    $SUDO fc-cache -f -v
fi

## other tools

# thefuck (https://github.com/nvbn/thefuck)
if [ "$DISTRO" = "alpine" ]; then
    $SUDO $PKG_INSTALL_CMD python3-dev py-pip py3-wheel gcc libc-dev linux-headers
else
    $SUDO $PKG_INSTALL_CMD python3-dev python3-pip
fi

if [ ! -z "$SUDO" ]; then
    $SUDO -H pip3 install thefuck
else
    pip3 install thefuck 
fi 


## start zsh (if on interactive shell)
[[ $- == *i* ]] && zsh || :
