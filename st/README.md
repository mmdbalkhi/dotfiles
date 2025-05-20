## simple terminal
My very simple fork of st, comes with no guarantees or warranties <sub>(to be clear: this means things may not work as expected, or at all)</sub> :^)

## patches added
* alpha & changealpha (transparency)
* Xresources w/ reload signal (pywal takes priority)
* ligatures
* scrollback ringbuffer, with mouse
* anysize (ensures compatibility with various gaps setups in tiling WMs)
* clipboard
 
## other stuff
* If you aren't using ```~/.Xresources``` or [pywal](https://github.com/dylanaraps/pywal), default color palette is Tomorrow Night.
* Read or change keybinds, default font/size, etc. in **config.h** - I'll update the man page at some point. Bindings are what you'd expect, besides:
  - ```ctrl + c``` & ```ctrl + shift + v``` for copy-paste
  - ```ctrl + =``` & ```ctrl + -``` to increase and decrease font size, respectively

## how install pls?
```
git clone https://github.com/mmdbalkhhi/dotfiles/
cd dotfiles/st
sudo make install
```

> !NOTE:
based on https://github.com/BreadOnPenguins/st
