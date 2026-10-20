-- 与 tmux 的 christoomey/vim-tmux-navigator 插件配对：C-h/j/k/l 在 nvim 窗口和 tmux pane 之间无缝跳转
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
    { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down" },
    { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up" },
    { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right" },
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate Previous" },
  },
}
