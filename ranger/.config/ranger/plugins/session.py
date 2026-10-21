# Reopen ranger where it was left: every tab's directory and selected file, the active
# tab and the viewmode (miller, or the two-pane :dual view). Plain `ranger` restores;
# `ranger <path>` (or --selectfile / --cmd / --clean) starts fresh as usual.
# Saved to ~/.local/share/ranger/session.json on cd / tab / viewmode changes and on exit,
# so closing the terminal window still keeps the directories. Several instances: the
# last one to change something wins.
import atexit
import json
import os

import ranger.api
from ranger.container.settings import SIGNAL_PRIORITY_AFTER_SYNC

old_hook_init = ranger.api.hook_init
old_hook_ready = ranger.api.hook_ready

state = {"saved": None, "ready": False}


def session_path(fm):
    return fm.datapath("session.json")


def save(fm):
    if not state["ready"] or ranger.args.clean:
        return
    names = fm.get_tab_list()
    tabs = []
    for name in names:
        tab = fm.tabs[name]
        thisfile = tab.thisfile
        tabs.append({"path": tab.path, "file": thisfile.path if thisfile else None})
    viewmode = fm.settings.viewmode
    if viewmode == "multipane" and len(tabs) < 2:
        viewmode = "miller"  # one tab left after q in :dual, nothing to split
    data = {"tabs": tabs, "current": names.index(fm.current_tab), "viewmode": viewmode}
    try:
        tmp = session_path(fm) + ".tmp"
        with open(tmp, "w") as fobj:
            json.dump(data, fobj)
        os.replace(tmp, session_path(fm))
    except OSError:
        pass


def hook_init(fm):
    args = ranger.args
    if not (args.clean or args.paths or args.selectfile or args.cmd):
        # Read now: the first cd of this run would otherwise overwrite it
        try:
            with open(session_path(fm)) as fobj:
                state["saved"] = json.load(fobj)
        except (OSError, ValueError):
            pass

    fm.signal_bind("cd", lambda signal: save(fm))
    fm.signal_bind("tab.change", lambda signal: save(fm))
    fm.signal_bind("tab.layoutchange", lambda signal: save(fm))
    fm.settings.signal_bind("setopt.viewmode", lambda signal: save(fm),
                            priority=SIGNAL_PRIORITY_AFTER_SYNC)
    atexit.register(save, fm)
    return old_hook_init(fm)


def restore(fm, data):
    tabs = [t for t in data.get("tabs", []) if os.path.isdir(t.get("path") or "")]
    if not tabs:
        return
    for name, tab in enumerate(tabs, 1):
        fm.tab_open(name, tab["path"])
        if tab.get("file") and os.path.dirname(tab["file"]) == fm.thisdir.path \
                and os.path.lexists(tab["file"]):
            fm.thisdir.move_to_obj(tab["file"])
    current = data.get("current", 0)
    fm.tab_open(current + 1 if 0 <= current < len(tabs) else 1)
    viewmode = data.get("viewmode")
    if viewmode in ("miller", "multipane") and viewmode != fm.settings.viewmode:
        fm.execute_console("set viewmode " + viewmode)


def hook_ready(fm):
    if state["saved"]:
        try:
            restore(fm, state["saved"])
        except Exception as ex:  # a stale session must never stop ranger from starting
            fm.notify("恢复上次的会话失败: {}".format(ex), bad=True)
    state["ready"] = True
    save(fm)
    return old_hook_ready(fm)


ranger.api.hook_init = hook_init
ranger.api.hook_ready = hook_ready
