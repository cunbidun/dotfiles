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

# xrandr --output eDP-1 --primary --auto
# xrandr --output eDP-1-1 --primary --auto
xrandr --output HDMI-0 --primary --output eDP-1-1 --left-of HDMI-0 --auto
# xrandr --output eDP-1-1 --primary --auto
xrandr --dpi 96 


# xset r rate 200 30; exec awesome 
xset r rate 200 30; exec dwm 
# exec bspwm
# exec dwm 
