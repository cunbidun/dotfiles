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

# with HDMI, NVIDIA 
# xrandr --output HDMI-0 --primary --mode 3440x1440 --pos 0x0 --rotate normal --output DP-0 --off --output DP-1 --off --output eDP-1-1 --mode 1920x1080 --rate 144.00 --pos 760x1440 --rotate normal --output DP-1-1 --off

# with HDMI, NVIDIA, 165hz
# xrandr --output HDMI-0 --primary --mode 2560x1440 --rate 144.00 --pos 0x0 --rotate normal --output eDP-1-1 --mode 1920x1080 --pos 320x1440 --rotate normal 

# built-in, NVIDIA
# xrandr --output eDP-1-1 --primary --mode 1920x1080 --rate 144.00 # 144hz

# built-in, Intel
# xrandr --output None-1 --scale 0.66x0.66

while type dwm >/dev/null; do xrdb ~/.Xresources && rm -rf /tmp/dwm-log && dwm && continue || break ; done 
