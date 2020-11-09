num=$1
if [ 0 -lt $num -a $num -lt 100 ]; then
  xrandr --output eDP-1 --brightness "0.$num"
fi
