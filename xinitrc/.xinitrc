#!/bin/zsh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

export PATH=$PATH:~/.scripts/bin
xset r rate 200 30 &

# with HDMI, nvidia
# xrandr --output HDMI-0 --primary --mode 3440x1440 --pos 0x0 --rotate normal --output DP-0 --off --output DP-1 --off --output eDP-1-1 --mode 1920x1080 --rate 144.00 --pos 760x1440 --rotate normal --output DP-1-1 --off
# xrandr --output HDMI-0 --primary --rate 144.00 --output eDP-1-1 --below HDMI-0 --mode 1920x1080 --rate 144.00 

# built-in, nvida
# xrandr --output eDP-1-1 --primary --mode 1920x1080 --rate 144.00 # 144hz

# built-in, intel 
xrandr --output eDP-1 --primary --mode 1920x1080 --rate 144.00 # 144hz

# with thunderbolt, nvidia
# xrandr --output HDMI-0 --off --output DP-0 --off --output DP-1 --off --output eDP-1-1 --mode 1920x1080 --rate 144.00 --pos 320x1440 --rotate normal --output DP-1-1 --primary --mode 2560x1440 --rate 144.00 --pos 0x0 --rotate normal

# with thunderbolt, nvidia 3440x1440
# xrandr --output DP-1-1 --primary --mode 3440x1440 --rate 144.00 --output eDP-1-1 --below DP-1-1 --mode 1920x1080 --rate 144.00

# with thunderbolt, nvidia
# xrandr --output DP-1-1 --primary --auto --output eDP-1-1 --left-of DP-1-1 --mode 1920x1080 --rate 144.00

# xrandr --output eDP-1-1 --primary --mode 1920x1080 --rate 144.00 --output DP-1-1 --auto --left-of eDP-1-1 

# xrandr --output eDP-1 --primary --auto
# xrandr --output eDP-1-1 --primary --auto
# xrandr --output eDP-1-1 --primary --output HDMI-0 --above eDP-1-1 --auto
# xrandr --output HDMI-0 --primary --output eDP-1-1 --left-of HDMI-0 --auto
# xrandr --output eDP-1-1 --primary --auto

xrandr --dpi 96 

# exec awesome 
# exec xmonad 
while type dwm >/dev/null ; do dwm && continue || break ; done 
# exec bspwm
# exec i3
