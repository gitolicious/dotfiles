#!/bin/bash

set -e
shopt -s expand_aliases

sudo apt update
sudo apt install -y git

## dotfiles git repo

# clone dotfiles
git clone --bare https://github.com/gitolicious/dotfiles.git $HOME/.dotfiles

# create dotfiles alias
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# checkout dotfiles
dotfiles checkout


## installations

# zsh
sudo apt install -y zsh

# oh-my-zsh
RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

mv $HOME/.zshrc.pre-oh-my-zsh $HOME/.zshrc

# load zsh variables
ZSH=${ZSH:-${HOME}/.oh-my-zsh}
ZSH_CUSTOM=${ZSH_CUSTOM:-${ZSH}/custom}

# zsh themes
mkdir -p $ZSH_CUSTOM/themes/powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# oh-my-zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

## other tools

sudo apt install -y python3-dev python3-pip
sudo -H pip3 install thefuck


## start zsh
zsh
