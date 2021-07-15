# Installation note

### Install [yay](https://github.com/Jguer/yay)
```
pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```
---

### Install dev tool
```
pacman -S nodejs npm go yarn pyenv pyenv-virtualenv
```
---

### Install utilities
```
yay -S fzf lazygit skippy-xd-git xclip sysstat ripgrep bat exa gnome-keyring imagemagick unzip stow acpi pamixer apulse alsa-utils network-manager-applet
```
1. fzf: fuzzy finder
2. acpi: battery status
---

### Install ibus and ibus-bamboo
1. install ibus and ibus-bamboo
```
yay -S ibus ibus-bambooz
```
2. execute `ibus-setup` to setup `ibus-bamboo`
3. change color of ibus icon
```
gsettings set org.freedesktop.ibus.panel xkb-icon-rgba '#81A1C1' 
```
---

### NVIDIA driver and optimus manager
1. install optimus-manager
```
yay -S nvidia optimus-manager
cp /usr/share/optimus-manager.conf /etc/optimus-manger/
```
2. edit file /etc/optimus-manager/optimus-manager.conf as follow
```
[intel]
DRI=3
accel=
driver=modesetting
modeset=yes
tearfree=

[nvidia]
DPI=96
PAT=yes
allow_external_gpus=no
ignore_abi=no
modeset=yes
options=overclocking

[optimus]
switching=nouveau
pci_power_control=yes
auto_logout=no
pci_remove=no
pci_reset=no
startup_auto_battery_mode=intel
startup_auto_extpower_mode=nvidia
startup_mode=auto
```
---

### Install fonts

```
yay -S adobe-source-code-pro-fonts ttf-weather-icons 
```
---

### Install picom-git for blurring effect
```
yay -S picom-git 
```
---

### Install lxappearance
1. install lxappearance
    ```
    yay -S lxappearance papirus-folders-nordic
    ```
2. install [Nordic GTK theme](https://www.gnome-look.org/p/1267246/)
3. setup in the GUI
---

### Install Arc icon (for status bar)
```
git clone [https://github.com/horst3180/arc-icon-theme](https://github.com/horst3180/arc-icon-theme) --depth 1 && cd arc-icon-theme
./autogen.sh --prefix=/usr
sudo make install
```
---

### Bluetooth
[https://wiki.archlinux.org/index.php/bluetooth](https://wiki.archlinux.org/index.php/bluetooth)

By default, the Bluetooth adapter does not power on after a reboot, you need to add the line `AutoEnable=true` in the configuration file `/etc/bluetooth/main.conf` at the bottom in the `[Policy]` section:

    ```
    [Policy]
    AutoEnable=true
    ```
---

### Neovim
1. copy config
```
cd dotfiles && stow nvim 
```

2. install plug-in manager([vim-plug](https://github.com/junegunn/vim-plug))
```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

3. Lsp install
```
:LspInstall cpp json
```
---

### Discord
1. install discord and BetterDiscord
```bash
yay -S discord

curl -O https://raw.githubusercontent.com/bb010g/betterdiscordctl/master/betterdiscordctl
chmod +x betterdiscordctl
sudo mv betterdiscordctl /usr/local/bin

betterdiscordctl install
```
2. copy config
```bash
cd dotfiles
stow BetterDiscord
```
3. set up in discord
    1. go to discord client at `User Settings > Bandaged BD > Themes`
    2. turn on nord theme
---

### Zsh

#### true color check
Run this on terminal and see if the color line break or not:
```
awk 'BEGIN{
    s="/\\\\/\\\\/\\\\/\\\\/\\\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
        r = 255-(colnum*255/76);
        g = (colnum*510/76);
        b = (colnum*255/76);
        if (g>255) g = 510-g;
        printf "\\033[48;2;%d;%d;%dm", r,g,b;
        printf "\\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\\033[0m", substr(s,colnum+1,1);
    }
    printf "\\n";
}'
```
#### Install zsh plugins
```
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```
---
