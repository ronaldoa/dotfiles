# Record every directory ranger visits in zoxide, so `:z` / `,z` can jump back to it.
import subprocess

import ranger.api

old_hook_init = ranger.api.hook_init


def hook_init(fm):
    def add(signal):
        if signal.new and signal.new.path:
            subprocess.Popen(["zoxide", "add", "--", signal.new.path],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    fm.signal_bind("cd", add)
    return old_hook_init(fm)


ranger.api.hook_init = hook_init
