#!/bin/sh

# idle
swayidle -w \
         timeout 180 'swaylock -f' \
         timeout 300 'niri msg action power-off-monitors' resume 'niri msg action power-on-monitors' \
         before-sleep 'swaylock -f' &

sway-audio-idle-inhibit &

# wallpaper
~/.azotebg

# notifications
dunst &

# Pipewire things
dbus-run-session pipewire &
dbus-run-session pipewire-pulse &
wireplumber &

/usr/libexec/xdg-desktop-portal-gtk &

# clipboard
wl-paste -t text --watch clipman store &

# night light
wlsunset -l 38.0792 -L 46.2887 -t 6000 &

#

/usr/bin/battery-alert &

# singbox
setsid sh -c "/bin/sing-box run -c $HOME/.config/sing-box/config.json 2>&1 | logger -t sing-box" &

# Audio Steam
setsid sh -c 'cd "$HOME/.local/bin" && ./pashare start 2>&1 | logger -t pashare' &

# vpn
#setsid sh -c 'cd "$HOME/.local/bin" && ./masque-plus --endpoint 162.159.198.2:443 --bind 127.0.0.1:8086 2>&1 | logger -t masque' &
