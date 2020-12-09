# A dotfiles repo

## Dotfiles included:

1. alacritty
2. Code (vscode)
3. nvim
4. some script
5. Xresources
6. awesome (my window manager)
7. espanso
8. tmux
9. zsh

## How to install and use the dotfiles:

1. Install [stow](https://www.gnu.org/software/stow/)
2. Clone the repo
3. `cd ~/dotfiles`
4. `stow`

# After install Arch

## Install yay: https://github.com/Jguer/yay

1. pacman -S --needed git base-devel
2. git clone https://aur.archlinux.org/yay.git
3. cd yay
4. makepkg -si

## Install networkmanager: yay -S network-manager-applet

## Theme:
### install adobe-source-code-pro-fonts: yay -S adobe-source-code-pro-fonts
### install ibus ibus-bamboo: yay -S ibus ibus-bamboo
1. ibus-setup to install ibus-bamboo
### install picom: yay -S picom

### install lxappearance:

1. yay -S lxappearance
2. setup in the GUI

### install acpi: yay -S acpi

### install apulse: yay -S apulse

### install alsa-utils: yay -S alsa-utils

### install Arc icon:

1. git clone https://github.com/horst3180/arc-icon-theme --depth 1 && cd arc-icon-theme
2. ./autogen.sh --prefix=/usr
3. sudo make install

## Install tools

### install chromium: yay -S chromium

### install VimPlug

sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'


### install nodejs: pacman -S nodejs npm

# Install nvidia
1. yay -S nvidia
2. yay -S optimus-manager
3. cp /usr/share/optimus-manager.conf /etc/optimus-manger/
4. set the startup option to auto