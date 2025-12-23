#!/bin/sh

# wallpaper
~/.azotebg

# notifications
dunst &

# audio
pipewire &
pipewire-pulse &

# clipboard
wl-paste -t text --watch clipman store &

# night light
wlsunset -l 38.0792 -L 46.2887 -t 6000 &
