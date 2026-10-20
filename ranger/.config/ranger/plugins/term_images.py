# Choose the image preview method for the terminal ranger runs in:
#   iTerm2 (not inside tmux)    -> real images with the iterm2 method
#   X11 with ueberzug installed -> keep rc.conf's ueberzug (works inside tmux too)
#   anything else (Alacritty on the Mac, tmux on the Mac, ...) -> preview_images off;
#                                  scope.sh draws images with chafa
import os
import shutil

import ranger.api

old_hook_init = ranger.api.hook_init


def hook_init(fm):
    iterm = (os.environ.get("TERM_PROGRAM") == "iTerm.app"
             or os.environ.get("LC_TERMINAL") == "iTerm2")
    if iterm and not os.environ.get("TMUX"):
        fm.settings.preview_images_method = "iterm2"
        fm.settings.preview_images = True
    elif not (os.environ.get("DISPLAY") and shutil.which("ueberzug")):
        fm.settings.preview_images = False
    return old_hook_init(fm)


ranger.api.hook_init = hook_init
