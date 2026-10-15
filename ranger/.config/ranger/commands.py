# Custom ranger commands (loaded on top of ranger's built-in ones).
#   :fzf_select [dirs]   fuzzy-find a file (or directory) below the current dir and jump to it
#   :z [query]           jump to a frecent directory with zoxide; no query opens an fzf picker
#   :trash               move the selection to the trash (replaces ranger 1.9.4's broken one)
import os
import subprocess

from ranger.api.commands import Command


class trash(Command):
    """:trash

    Move the marked files (or the current file) to the freedesktop trash with trash-put,
    so they can be restored with trash-restore (dR). Asks first for several files or a
    non-empty directory. ranger 1.9.4's own :trash crashes ('str' object has no attribute 'path').
    """

    allow_abbrev = False

    def execute(self):
        selection = self.fm.thistab.get_selection()
        if not selection:
            self.fm.notify("没有选中文件", bad=True)
            return
        paths = [f.path for f in selection]
        risky = len(paths) > 1 or any(
            os.path.isdir(p) and not os.path.islink(p) and os.listdir(p) for p in paths)
        if risky:
            names = ", ".join(f.relative_path for f in selection)
            self.fm.ui.console.ask("移到回收站: {} (y/N)".format(names),
                                   lambda answer: answer in "yY" and self._trash(paths),
                                   ("n", "N", "y", "Y"))
        else:
            self._trash(paths)

    def _trash(self, paths):
        proc = subprocess.run(["trash-put", "--", *paths], capture_output=True, text=True)
        if self.fm.thisdir:
            self.fm.thisdir.mark_all(False)
        self.fm.reload_cwd()
        if proc.returncode:
            self.fm.notify("trash-put: " + (proc.stderr.strip() or "失败"), bad=True)
        else:
            self.fm.notify("已移到回收站: {} 个 (dR 恢复)".format(len(paths)))


class fzf_select(Command):
    """:fzf_select [dirs]

    Fuzzy-find below the current directory with fzf (hidden files included, .git skipped).
    Directories are entered; files are selected in their directory.
    """

    def execute(self):
        only_dirs = self.arg(1) == "dirs"
        kind = "d" if only_dirs else "f,d"
        # Grouped so the fallback doesn't swallow the pipe into fzf (a || b | c is a || (b | c))
        find = ("{{ fd --hidden --exclude .git --type {} . 2>/dev/null || "
                "find . -mindepth 1 -name .git -prune -o {} -print 2>/dev/null | sed 's|^\\./||'; }}"
                ).format(" --type ".join(kind.split(",")), "-type d" if only_dirs else "")
        preview = ("[ -d {} ] && ls -A --color=always {} || "
                   "bat --color=always --style=plain --line-range :200 {} 2>/dev/null")
        fzf = self.fm.execute_command(
            "{} | fzf +m --height=100% --layout=reverse --preview '{}' --prompt '{}> '".format(
                find, preview, "目录" if only_dirs else "文件"),
            universal_newlines=True, stdout=subprocess.PIPE)
        out, _ = fzf.communicate()
        if fzf.returncode != 0 or not out.strip():
            return
        path = os.path.abspath(out.strip())
        if os.path.isdir(path):
            self.fm.cd(path)
        else:
            self.fm.select_file(path)


class z(Command):
    """:z [query]

    Jump with zoxide. Directories are recorded by plugins/zoxide_add.py as you browse.
    """

    def execute(self):
        query = self.rest(1)
        if query:
            cmd = ["zoxide", "query", "--exclude", self.fm.thisdir.path, "--", *query.split()]
            proc = subprocess.run(cmd, capture_output=True, text=True)
        else:
            proc = self.fm.execute_command("zoxide query -i", universal_newlines=True,
                                           stdout=subprocess.PIPE)
            out, _ = proc.communicate()
            proc.stdout = out
        target = (proc.stdout or "").strip()
        if proc.returncode == 0 and os.path.isdir(target):
            self.fm.cd(target)
        elif query:
            self.fm.notify("zoxide: 没有匹配 '{}' 的目录".format(query), bad=True)

    def tab(self, tabnum):
        # Complete from zoxide's list of known directories
        proc = subprocess.run(["zoxide", "query", "-l", "--", *self.rest(1).split()],
                              capture_output=True, text=True)
        return ["z " + d for d in proc.stdout.splitlines()[:20]]


ARCHIVE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scripts", "archive")


def _run_archive(fm, args, descr):
    """Run scripts/archive in the background (shown in ranger's task list, errors notified)."""
    from ranger.core.loader import CommandLoader

    cwd = fm.thisdir
    loader = CommandLoader(args=[ARCHIVE, *args], descr=descr)
    loader.signal_bind("after", lambda signal: cwd.load_content())
    fm.loader.add(loader)


class extract_here(Command):
    """:extract_here

    Extract the marked archives (or the current one) into folders named after them (ux).
    """

    def execute(self):
        paths = [f.path for f in self.fm.thistab.get_selection() if f.is_file]
        if not paths:
            self.fm.notify("没有选中压缩包", bad=True)
            return
        self.fm.thisdir.mark_all(False)
        names = ", ".join(os.path.basename(p) for p in paths)
        _run_archive(self.fm, ["x", *paths], "解压: " + names)


class compress(Command):
    """:compress NAME

    Pack the marked files (or the current one) into NAME in the current directory (uc).
    The extension picks the format: .zip .7z .tar.gz .tar.xz .tar.zst ...
    Without NAME, opens the console with a suggested name.
    """

    def execute(self):
        selection = self.fm.thistab.get_selection()
        if not selection:
            self.fm.notify("没有选中文件", bad=True)
            return
        name = self.rest(1).strip()
        if not name:
            stem = (selection[0].basename if len(selection) == 1 else self.fm.thisdir.basename)
            if len(selection) == 1 and selection[0].is_file and "." in stem.strip("."):
                stem = stem.rsplit(".", 1)[0]
            text = "compress {}.zip".format(stem)
            self.fm.open_console(text, position=len(text) - len(".zip"))  # cursor before .zip
            return
        names = [f.relative_path for f in selection]
        names = ["./" + n if n.startswith("-") else n for n in names]
        self.fm.thisdir.mark_all(False)
        _run_archive(self.fm, ["c", name, *names], "压缩: " + name)

    def tab(self, tabnum):
        stem = self.rest(1).rsplit(".", 1)[0] if "." in self.rest(1) else self.rest(1)
        return ["compress {}{}".format(stem, ext)
                for ext in (".zip", ".tar.gz", ".7z", ".tar.zst", ".tar.xz")]
