#!/bin/bash

set -e
shopt -s expand_aliases

## preparations

# check Linux distribution
. /etc/os-release
if [ "$NAME" = "Alpine Linux" ]; then
    DISTRO="Alpine"
    PKG_UPDATE_CMD="apk update"
    PKG_INSTALL_CMD="apk add"
elif [ "$NAME" = "Ubuntu" ]; then
    DISTRO="Ubuntu"
    PKG_UPDATE_CMD="apt update"
    PKG_INSTALL_CMD="apt install -y"
else
    echo "Unknown Linux distribution $NAME"
    exit 1
fi

# check root
if [ $(id -u) = "0" ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# install necessities
sudo $PKG_UPDATE_CMD
sudo $PKG_INSTALL_CMD git


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
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  mv $HOME/.zshrc.pre-oh-my-zsh $HOME/.zshrc
fi

# load zsh variables
ZSH=${ZSH:-${HOME}/.oh-my-zsh}
ZSH_CUSTOM=${ZSH_CUSTOM:-${ZSH}/custom}

# zsh themes
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  mkdir -p $ZSH_CUSTOM/themes/powerlevel10k
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
fi

# oh-my-zsh plugins
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]     && git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]         && git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Meslo Nerd Font
if [ $DISPLAY ]; then
    mkdir -p ~/.local/share/fonts
    wget -P ~/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf
    wget -P ~/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf
    wget -P ~/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf
    wget -P ~/.local/share/fonts https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf
    $SUDO $PKG_INSTALL_CMD fontconfig
    $SUDO fc-cache -f -v
fi

## other tools

# thefuck (https://github.com/nvbn/thefuck)
if [ "$DISTRO" = "Alpine" ]; then
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
    $PKG_UPDATE_CMD
    $SUDO $PKG_INSTALL_CMD thefuck
else
    $SUDO $PKG_INSTALL_CMD python3-dev python3-pip
    $SUDO -H pip3 install thefuck
fi


## start zsh
zsh
