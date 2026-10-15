-- cscope 接口 (nvim 0.9+ 已移除内置 cscope)，后端用 GNU Global 的 gtags-cscope
-- GTAGS 由 gutentags 的 gtags_maps 模块自动生成到 ~/.cache/tags，并在切换 buffer 时自动连接
return {
  "dhananjaylatkar/cscope_maps.nvim",
  event = "VeryLazy",
  opts = {
    -- <leader>c 已被 LazyVim 的 code 组占用
    prefix = "<C-c>",
    cscope = {
      exec = "gtags-cscope",
      picker = "fzf-lua",
      skip_picker_for_single_result = true,
    },
  },
  config = function(_, opts)
    require("cscope_maps").setup(opts)

    -- 跟随当前 buffer 所在项目切换 GTAGS 数据库
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("GtagsMapsActivate", { clear = true }),
      callback = function()
        if vim.b.gutentags_files then
          vim.fn["gutentags#gtags_maps#activate"]()
        end
      end,
    })
  end,
}
