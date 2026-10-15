-- ~/.config/nvim/lua/plugins/venv-selector.lua
-- Extends the venv-selector spec from LazyVim's python extra (which also maps <leader>cv).
-- venv-selector v2 restarts the LSP on activation by itself.
return {
  {
    "linux-cultist/venv-selector.nvim",
    keys = {
      { ",v", "<cmd>VenvSelect<cr>", desc = "Select venv/conda env", ft = "python" },
    },
    opts = {
      -- Default searches (.venv in the project, ~/.virtualenvs, ...) are kept; these add miniforge.
      search = {
        miniforge_envs = {
          command = "$FD 'bin/python$' ~/miniforge3/envs --no-ignore-vcs --full-path --color never",
          type = "anaconda",
        },
        miniforge_base = {
          command = "$FD '/python$' ~/miniforge3/bin --no-ignore-vcs --full-path --color never",
          type = "anaconda",
        },
      },
      options = { notify_user_on_venv_activation = true },
    },
  },
}
