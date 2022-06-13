#!/bin/sh

pwd

rm -rf "$HOME/.oh-my-zsh"

# install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting"

# Remove left over file
rm -f "$HOME/.zshrc"
rm -f "$HOME/.zshenv"
rm -f "$HOME/.zshcommon"
rm -rf "$HOME/.zprompts"
rm -rf "$HOME/.git-prompt.sh"
find "$HOME" -maxdepth 1 -type f -name "*.pre-oh-my-zsh*" -exec rm -rf {} \;
find "$HOME" -maxdepth 1 -type l -name "*.pre-oh-my-zsh*" -exec rm -rf {} \;

# install config
if [ "$(uname)" = 'Linux' ]; then
	echo "Installing for Linux"
	stow common linux -t "$HOME"
else
	echo "Installing for Mac"
	stow common macos -t "$HOME"
fi
