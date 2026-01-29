#!/bin/sh

# wallpaper
~/.azotebg

# notifications
dunst &

# Pipewire things
pipewire &
pipewire-pulse &

/usr/libexec/xdg-desktop-portal-gtk &

# clipboard
wl-paste -t text --watch clipman store &

# night light
wlsunset -l 38.0792 -L 46.2887 -t 6000 &

# audio stream
setsid sh -c 'cd "$HOME/.local/bin" && ./pashare start 2>&1 | logger -t pashare' &
