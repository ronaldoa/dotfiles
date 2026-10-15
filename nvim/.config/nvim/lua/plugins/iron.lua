-- ~/.config/nvim/lua/plugins/iron.lua
-- REPL (iron.nvim). All keys live under <leader>r so they don't shadow
-- LazyVim's <leader>s (search) group or <leader>cl (Lsp Info).

return {
  {
    "Vigemus/iron.nvim",
    ft = { "python", "sh" },
    cmd = { "IronRepl", "IronRestart", "IronFocus", "IronHide" },
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")
      local common = require("iron.fts.common")

      iron.setup({
        config = {
          -- Whether a repl should be discarded or not
          scratch_repl = true,
          repl_definition = {
            sh = {
              command = { "zsh" },
            },
            python = {
              command = { "python3" }, -- or { "ipython", "--no-autoindent" }
              format = common.bracketed_paste_python,
              block_dividers = { "# %%", "#%%" },
              env = { PYTHON_BASIC_REPL = "1" }, --this is needed for python3.13 and up.
            },
          },
          -- The REPL buffer gets the filetype of the language being used
          repl_filetype = function(bufnr, ft)
            return ft
          end,
          -- Send selections to the DAP repl if an nvim-dap session is running.
          dap_integration = true,
          -- 在底部打开一个 10 行高的窗口(而不是全屏)
          repl_open_cmd = view.bottom(10),
        },
        keymaps = {
          toggle_repl = "<leader>rr", -- 打开/关闭 REPL
          restart_repl = "<leader>rR", -- 重启 REPL
          send_line = "<leader>rl", -- 发送当前行
          send_motion = "<leader>rs", -- 发送 motion,如 <leader>rsip
          visual_send = "<leader>rs", -- 发送选中内容
          send_paragraph = "<leader>rp",
          send_file = "<leader>rf",
          send_until_cursor = "<leader>ru",
          send_code_block = "<leader>rb", -- 发送 # %% 代码块
          send_code_block_and_move = "<leader>rn", -- 发送代码块并跳到下一块
          mark_motion = "<leader>rm",
          mark_visual = "<leader>rm",
          send_mark = "<leader>rM",
          remove_mark = "<leader>rd",
          cr = "<leader>r<cr>",
          interrupt = "<leader>ri",
          exit = "<leader>rq",
          clear = "<leader>rc",
        },
        highlight = {
          italic = true,
        },
        ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
      })

      vim.keymap.set("n", "<leader>rF", "<cmd>IronFocus<cr>", { desc = "Focus REPL" })
      vim.keymap.set("n", "<leader>rh", "<cmd>IronHide<cr>", { desc = "Hide REPL" })
    end,
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = { { "<leader>r", group = "REPL", icon = " " } },
    },
  },
}
