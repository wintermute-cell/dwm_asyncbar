# dwm_asyncbar

An `xsetroot` based statusbar for dwm, that uses asyncronous blocks
to save on performance.
Written entirely in bash, designed to be easily understandable and extensible.

![Example Image](screenshot.jpg)

## Install
- clone this repo
- cd into the directory: `cd dwm_asyncbar`
- install using: 
```chmod u+x dwm_asyncbar.sh && ln -s dwm_asyncbar.sh $HOME/.local/bin/```
- add to your `.xinitrc` (or whatever else you want to launch the bar from):
```$HOME/.local/bin/dwm_asyncbar.sh &```
(or just `dwm_asyncbar.sh &` if `.local/bin/` is already in your path)
- done! reboot to start the bar.
