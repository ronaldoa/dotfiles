-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- tab = 4 spaces
vim.opt.tabstop = 4 -- 一个 tab 等于 4 个空格
vim.opt.shiftwidth = 4 -- >> 或 << 命令的缩进宽度
vim.opt.expandtab = true -- 用空格代替 tab
vim.opt.softtabstop = 4 -- 编辑时 tab 键的宽度
--vim.opt.autochdir = true

-- nvim 的 Python 宿主用专门的 venv(molten-nvim 需要 pynvim / jupyter_client / nbformat)
vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python")
