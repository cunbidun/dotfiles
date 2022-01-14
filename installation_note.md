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
pacman -S nodejs npm go yarn pyenv pyenv-virtualenv cargo
```

* `nodejs`, `npm`, `yarn`: for javascript
* `go`: golang
* `cargo`: for rust
* `pyenv`,`pyenv-virtualenv`: for python

---

## Install utilities

```bash
yay -S imlib2 fzf lazygit skippy-xd-git xclip sysstat ripgrep bat exa gnome-keyring imagemagick unzip stow acpi pamixer apulse alsa-utils network-manager-applet maim
```

* `fzf`: fuzzy finder
* `acpi`: battery status
* `maim`: screenshot

---

### Install utilities for neomutt

```bash
yay -S abook lynx
```

---

### Keyboards

#### Install ibus and ibus-bamboo

```bash
yay -S ibus ibus-bambooz
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
cargo install stylua
pip install flake8 black isort --upgrade # for python
sudo npm install -g prettier
sudo npm install -g write-good
sudo cpan -i YAML::Tiny Unicode::GCString File::HomeDir # for latex formatter
yay -S nvim-packer-git
yay -S nodejs-markdownlint-cli # for markdownlint
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

### Java applet Topcoder

1. Make sure Java 8 is installed.
`yay -S jre8-openjdk-headless  jre8-openjdk  jdk8-openjdk  openjdk8-doc  openjdk8-src`

2. Disable security by deleting "MD5" from the line that starts with
"jdk.jar.disabledAlgorithms" in with the following commands:

```bash
sudo archlinux-java set java-8-openjdk
sudo $EDITOR /usr/lib/jvm/default/jre/lib/security/java.security

Before: jdk.jar.disabledAlgorithms=MD2, MD5, RSA keySize < 1024, \
After:  jdk.jar.disabledAlgorithms=MD2, RSA keySize < 1024, \
```

**Learn more**: [Source](https://codeforces.cc/blog/entry/90503?#comment-789564)

### DWM

#### dwm swallow patch work around

* For `MarkdownPreview` extension, the browser need to open before running
`:MarkdownPreview`.
