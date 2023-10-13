#!/bin/bash

if [ `pgrep -x picom` ]; then
   notify-send -t 1600 'Disabled picom' --icon=video-display
   killall picom;
else 
   notify-send -t 1600 'Enabled picom' --icon=video-display
   picom -b &
fi
exit
