-- ~/.config/nvim/lua/plugins/venv-selector.lua

-- ~/.config/nvim/lua/plugins/venv-selector.lua
return {
  {
    "linux-cultist/venv-selector.nvim",
    -- branch = "regexp",
    ft = "python",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { ",v", "<cmd>VenvSelect<cr>", desc = "Select venv/conda env" },
    },
    opts = {
      anaconda_base_path = "/home/ronaldo/miniforge3",
      name = { ".venv", "venv" },
      options = { notify_user_on_venv_activation = true },
    },
    config = function(_, opts)
      require("venv-selector").setup(opts)
      vim.api.nvim_create_autocmd("User", {
        pattern = "VenvActivated",
        callback = function()
          vim.cmd("LspRestart")
        end,
      })
    end,
  },
}
