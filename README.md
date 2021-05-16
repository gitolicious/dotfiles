# dotfiles
My Linux dotfiles basic setup.

The approach was stolen from a [Medium article by Flavio Wuensche
](https://medium.com/toutsbrasil/how-to-manage-your-dotfiles-with-git-f7aeed8adf8b) which in turn is based on [Hacker News solution proposed by StreakyCobra](https://news.ycombinator.com/item?id=11070797)

This is highly personalized to my own personal needs but feel free to adapt to yours. It works with major distributions (tested with Alpine, Ubuntu and Debian) natively, in a Docker container as well as for VS Code devlopment containers.

# Getting started

If you're starting from scratch, go ahead and create a `.dotfiles` folder, which we'll use to track your dotfiles
```bash
git init --bare $HOME/.dotfiles
```
* create an alias `dotfiles` so you don't need to type it all over again
```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

* set git status to hide untracked files
```bash
dotfiles config --local status.showUntrackedFiles no
```

* add the alias to `.zshrc` (or `.bashrc`) so you can use it later
```bash
echo "alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" >> $HOME/.bashrc
```

# Usage

Now you can use regular git commands such as:
```bash
dotfiles status
dotfiles add .vimrc
dotfiles commit -m "Add vimrc"
dotfiles add .bashrc
dotfiles commit -m "Add bashrc"
dotfiles push
```
Nice, right? Now if you're moving to a virgin system...

# Setup environment in a new computer

Make sure to have git installed, then:
* clone your github repository
```bash
git clone --bare https://github.com/USERNAME/dotfiles.git $HOME/.dotfiles
```

* define the alias in the current shell scope
```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```
* checkout the actual content from the git repository to your `$HOME`
```bash
dotfiles checkout
```

> Note that if you already have some of the files you'll get an error message. You can either (1) delete them or (2) back them up somewhere else. It's up to you.

Now go on and install apps and plugins.

Awesome! You’re done.

# Simpler version

Everything is combined in the bootstrap file for convenience.
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gitolicious/dotfiles/main/bin/bootstrap.sh)"
```

This can be used in VS Code Remote Containers by adding the following line to `./devcontainer/devcontainer.json`
```json
"postCreateCommand": "bash -c \"$(curl -fsSL https://raw.githubusercontent.com/gitolicious/dotfiles/main/bin/bootstrap.sh)\"",
```

If you don't need [thefuck](https://github.com/nvbn/thefuck), you can save some installation time for its dependencies such as python by adding the `--fuck-off` argument or setting the `FUCK_OFF` environment variable.
