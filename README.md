# dotfiles
Based on https://github.com/mom1/dotfiles

# Requirements
For a better experience, I recommend to configurate new system in the next order: 

1. `iTerm2` https://iterm2.com/downloads.html (for Mac) or `Terminator` https://gnome-terminator.org/ (for Linux)
2. `Homebrew` https://brew.sh/index_ru (for Mac)
3. `PyEnv` (and Python, and make it global)
4. __Current dotfiles__
5. `Sublime Text 3` https://www.sublimetext.com/3 (my best visual text editor)

## PyEnv configuration

	brew install pyenv
	pyenv install {latest stable python version}
	pyenv global {latest stable python version}

After that configuration, you don't need worry about ruining your system python version.

# How to install dotfiles:

	git clone https://github.com/gstr169/dotfiles.git .dotfiles
	cd .dotfiles
	./install
