# Installation note

## Core packages

### Install [yay](https://github.com/Jguer/yay)

```bash
pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

---

### Install dev tool

```bash
pacman -S nodejs npm go yarn pyenv pyenv-virtualenv cargo quickemu 
```

* `nodejs`, `npm`, `yarn`: for javascript
* `go`: golang
* `cargo`: for rust
* `pyenv`,`pyenv-virtualenv`: for python
* `quickemu`: virtual environment

---

## Install utilities

```bash
yay -S fzf lazygit ripgrep bat exa gnome-keyring imagemagick unzip stow 
acpi network-manager-applet maim zathura zathura-pdf-mupdf xcursor-osx-elcap

xdg-mime default org.pwmt.zathura.desktop application/pdf # set zathura as default
```

* `fzf`: fuzzy finder
* `acpi`: battery status
* `maim`: screenshot
* `zathura`, `zathura-pdf-mupdf`: pdf reader
* `xcursor-osx-elcap`: cursor theme

---

### Audio

```bash
yay -S pipewire wireplumber pipewire-pulse pulsemixer pamixer pavucontrol ddcutil apulse alsa-utils
```

To control monitor's volume and brightness, add `ic2-dev` kernal module.

Set the default profile in `$HOME/.config/pulse/default.pa` (available in dotfiles folder)

---

### Bottles

```bash
yay -S bottles-git cairo pkgconf gobject-introspection gtk3
pip install PyGOject pyyaml markdown patool
```

---

### Install utilities for neomutt

```bash
yay -S abook lynx
```

---

### Keyboards

#### Install ibus and ibus-bamboo

```bash
yay -S ibus ibus-bamboo
```

#### Remove `ibus` icon from the systrace

Execute `ibus-setup`

---

### NVIDIA driver and optimus manager

  1. install optimus-manager  

```bash
yay -S nvidia optimus-manager
cp /usr/share/optimus-manager.conf /etc/optimus-manger/
```

  2. edit file /etc/optimus-manager/optimus-manager.conf as follow  

  ```txt
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

```bash
yay -S adobe-source-code-pro-fonts ttf-weather-icons 
yay -S adobe-source-han-sans-kr-fonts ttf-baekmuk # korean font
yay -S apple-fonts # apple font
yay -S adobe-base-14-fonts
```

---

### Install picom-git for blurring effect

```bash
yay -S picom-git 
```

---

### Lxappearance

#### Install lxappearance

```bash
yay -S lxappearance papirus-folders-nordic
```

#### Nord GTK theme

Install [Nordic GTK theme](https://www.gnome-look.org/p/1267246/)

#### Enable the theme

1. Run `lxappearance`
2. Setup in the GUI

---

### Bluetooth

Install:

```bash
yay -S  bluez bluez-utils
sudo systemctl enable --now bluetooth.service
```

[wiki](https://wiki.archlinux.org/index.php/bluetooth)

By default, the Bluetooth adapter does not power on after a reboot,
you need to add the line `AutoEnable=true`
in the configuration file `/etc/bluetooth/main.conf`
at the bottom in the `[Policy]` section:

  ```txt
  [Policy]
  AutoEnable=true
  ```

---

### Neovim (Lunarvim)

#### Copy configuration

```bash
cd dotfiles && stow lvim 
```

#### Install plug-in manager and formatter

```bash
pip install flake8 black isort --upgrade # for python
sudo cpan -i YAML::Tiny Unicode::GCString File::HomeDir # for latex formatter
yay -S prettier stylua nodejs-markdownlint-cli shfmt shellcheck write-good
```

#### Install language servers

1. Open a buffer in lvim

2. `<leader>Li` to see which supported language servers, linters and formatters.

3. Run :LspInstall with appropriate servers

---

### Discord

#### Install discord and BetterDiscord

```bash
yay -S discord # install discord

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

#### True color check

Run this on terminal and see if the color line break or not:

```bash
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
git clone https://github.com/svenXY/timewarrior ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/timewarrior
```

---

### Spotify (still error)

```bash
yay -S spotify # installing Spotify
yay -S spicetify-cli # installing Spicetify cli
yay -S spicetify-themes-git # installing the themes
sudo chmod a+wr /usr/share/spotify # gain write permission on Spotify files
sudo chmod a+wr /usr/share/spotify/Apps -R # gain write permission on Spotify files
suto rm -rf ~/config/spotify # delete config folder 
spicetify config current_theme Dreary # setting theme
spicetify config color_scheme nord # setting color scheme
sudo -E spicetify backup apply # applying the change
```

Note:
[Why do we need to delete config folder?](https://forum.manjaro.org/t/spotify-error-needs-usr-lib-libcurl-gnutls-so-4-but-libcurl-gnutls-installed/19260/5)

---

### DWM

``` bash
yay -S imlib2 libxft xorg-server xorg-apps xorg-xinit xclip
yay -S main sysstat
```

#### dwm swallow patch work around

* For `MarkdownPreview` extension, the browser need to open before running
`:MarkdownPreview`.

#### [Patches](https://coggle.it/diagram/X9IiSSM6PTWOM9Wz/t/dwm-patches-last-tallied-2022-03-17/d3448968e2509321527c3864cd4eee651e5f55e525582fdbf33be764972d9aef)

---

### Cronjobs

#### Installation

```bash
yay -S cronie
sudo systemctl enable cronie.service
sudo systemctl start cronie.service
```

#### Install cronjob

1. `cd dotfiles/cron && stow linux -t $HOME`
2. `cd $HOME/cron`
3. `crontab jobs` for user jobs
4. check the command in `root_jobs` to make sure the `user` and `user_id` are correct.
5. check `$HOME/.local/bin/sc_pacman_sync`
to make sure the `user` and `user_id` are correct.
6. `sudo crontab root_jobs` for root jobs
