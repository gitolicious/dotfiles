#!/bin/bash

set -e
shopt -s expand_aliases


## CLI arguments
if [[ "$1" = "--fuck-off" || ! -z ${FUCK_OFF+x} ]]; then
    SKIP_THE_FUCK=true
fi


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

# on WSL2 check DNS connection problems https://github.com/microsoft/WSL/issues/5256
if [[ -n "$WSL_DISTRO_NAME" ]] && $SUDO $PKG_UPDATE_CMD | grep -q "Temporary failure resolving"; then
    echo "Your WSL2 seems to have DNS issues - check https://github.com/microsoft/WSL/issues/5256 or try the following:"
    [ ! -z "$SUDO" ] && echo "$SUDO bash -c \"echo nameserver 8.8.8.8 >> /etc/resolv.conf\"" ||  echo "echo nameserver 8.8.8.8 >> /etc/resolv.conf"
    exit 1
fi


# install necessities
$SUDO $PKG_UPDATE_CMD
$SUDO $PKG_INSTALL_CMD git curl wget


## dotfiles git repo

# clone dotfiles
[ -f  "$HOME/.zshrc" ] && mv $HOME/.zshrc $HOME/.zshrc.bak
[ ! -d "$HOME/.dotfiles" ] && git clone --bare https://github.com/gitolicious/dotfiles.git $HOME/.dotfiles

# create dotfiles alias
alias dotfiles="$(which git) --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME"

# checkout dotfiles
dotfiles checkout
dotfiles pull
[ ! -f  "$HOME/.zshrc" ] && dotfiles checkout -- .zshrc
# after git v2.23.0 switch to
##dotfiles restore $HOME/.zshrc


## installations

# zsh
$SUDO $PKG_INSTALL_CMD zsh

# set zsh as default shell
if [ "$DISTRO" = "alpine" ]; then
    # alpine require shadow for chsh
    $SUDO $PKG_INSTALL_CMD shadow
    if [ -f "/etc/pam.d/chsh" ]; then
        $SUDO sed s/required/sufficient/g -i /etc/pam.d/chsh
        REVERT_CHSH_CMD="$SUDO sed s/sufficient/required/g -i /etc/pam.d/chsh"
    else
        $SUDO bash -c "echo \"auth       required   pam_shells.so\" > /etc/pam.d/chsh"
        REVERT_CHSH_CMD="$SUDO rm /etc/pam.d/chsh"
    fi
fi
[[ -x "$(command -v chsh)" && -x "$(command -v zsh)" ]] && $SUDO chsh -s $(which zsh) $(whoami)
if "$REVERT_CHSH_CMD"; then
    bash -c "$REVERT_CHSH_CMD"
fi

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

# oh-my-zsh requires glibc on alpine
if [ "$DISTRO" = "alpine" ]; then
    # https://github.com/JanDeDobbeleer/oh-my-posh/issues/379#issuecomment-773706331
    # https://github.com/sgerrand/alpine-pkg-glibc#installing
    $SUDO wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.33-r0/glibc-2.33-r0.apk
    $SUDO $PKG_INSTALL_CMD glibc-2.33-r0.apk
fi

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

if [ ! "$SKIP_THE_FUCK" ]; then

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

fi

## verify installation
echo "Verifying installation..."
[ -x "$(command -v zsh)" ]          && echo "zsh OK"        || echo "zsh FAILED"
[ -x "$(command -v oh-my-posh)" ]   && echo "oh-my-posh OK" || echo "oh-my-posh FAILED"
if [ ! "$SKIP_THE_FUCK" ]; then
    [ -x "$(command -v thefuck)" ]  && echo "thefuck OK"    || echo "thefuck FAILED"
else
    echo "thefuck SKIPPED"
fi 


## start zsh (if on interactive shell)
[[ $- == *i* ]] && zsh || :
