-- ~/.config/nvim/lua/plugins/molten.lua
-- 在 nvim 里编辑和运行 .ipynb:
--   jupytext.nvim 把 .ipynb 打开成 # %% 分块的 Python,保存时写回 .ipynb;
--   molten-nvim 连 Jupyter kernel 执行,输出显示在 cell 下方;
--   image.nvim 用 ueberzugpp 在终端上叠窗口显示图片(X11 下和终端无关)。
-- 所有键在 <leader>j 下,不和 iron.nvim 的 <leader>r 冲突。

-- 当前 # %% 块的起止行(1-based,含首尾);没有分隔线时就是整个文件
local function cell_range()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local last = vim.api.nvim_buf_line_count(0)
  local is_sep = function(l)
    return vim.fn.getline(l):match("^#%s*%%%%") ~= nil
  end
  local s = cur
  while s > 1 and not is_sep(s) do
    s = s - 1
  end
  if is_sep(s) then
    s = s + 1
  end
  local e = cur + 1
  while e <= last and not is_sep(e) do
    e = e + 1
  end
  return s, e - 1
end

local function run_cell(move)
  local s, e = cell_range()
  if e >= s then
    vim.fn.MoltenEvaluateRange(s, e)
  end
  if move and e < vim.api.nvim_buf_line_count(0) then
    vim.api.nvim_win_set_cursor(0, { math.min(e + 2, vim.api.nvim_buf_line_count(0)), 0 })
  end
end

return {
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false, -- 要在打开 .ipynb 之前注册 BufReadCmd
    opts = { style = "percent", output_extension = "auto", force_ft = nil },
  },
  {
    "3rd/image.nvim",
    build = false, -- 用 magick_cli,不需要 luarocks 的 magick
    opts = {
      backend = "ueberzug",
      processor = "magick_cli",
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    ft = { "python" },
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false -- 光标移进 cell 才弹输出窗
      vim.g.molten_virt_text_output = true -- 输出直接显示在 cell 下方
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_wrap_output = true

      -- 打开 .ipynb:按文件里记的 kernel 启动,并把已有输出导入显示
      local import_outputs = function(e)
        vim.schedule(function()
          local kernels = vim.fn.MoltenAvailableKernels()
          local ok, name = pcall(function()
            local f = assert(io.open(e.file, "r"))
            local meta = vim.json.decode(f:read("a"))["metadata"]
            f:close()
            return meta.kernelspec.name
          end)
          if not ok or not vim.tbl_contains(kernels, name) then
            name = nil
            local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
            if venv then
              name = venv:match("/.+/(.+)")
            end
          end
          if name and vim.tbl_contains(kernels, name) then
            vim.cmd(("MoltenInit %s"):format(name))
          end
          vim.cmd("MoltenImportOutput")
        end)
      end
      vim.api.nvim_create_autocmd("BufAdd", { pattern = "*.ipynb", callback = import_outputs })
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.ipynb",
        callback = function(e)
          if vim.api.nvim_get_vvar("vim_did_enter") ~= 1 then
            import_outputs(e)
          end
        end,
      })
      -- 保存 .ipynb 时把输出也写回文件(和 Jupyter 里保存一样)
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*.ipynb",
        callback = function()
          if require("molten.status").initialized() == "Molten" then
            vim.cmd("MoltenExportOutput!")
          end
        end,
      })
    end,
    keys = {
      { "<leader>ji", "<cmd>MoltenInit<cr>", desc = "Init kernel" },
      { "<leader>jc", function() run_cell(false) end, desc = "Run cell" },
      { "<leader>jn", function() run_cell(true) end, desc = "Run cell & next" },
      { "<leader>jl", "<cmd>MoltenEvaluateLine<cr>", desc = "Run line" },
      { "<leader>jr", ":<C-u>MoltenEvaluateVisual<cr>gv", mode = "v", desc = "Run selection" },
      { "<leader>ja", "<cmd>MoltenReevaluateAll<cr>", desc = "Re-run all cells" },
      { "<leader>jo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Enter output" },
      { "<leader>jh", "<cmd>MoltenHideOutput<cr>", desc = "Hide output" },
      { "<leader>jd", "<cmd>MoltenDelete<cr>", desc = "Delete cell output" },
      { "<leader>jx", "<cmd>MoltenInterrupt<cr>", desc = "Interrupt kernel" },
      { "<leader>jR", "<cmd>MoltenRestart!<cr>", desc = "Restart kernel" },
      { "<leader>je", "<cmd>MoltenExportOutput!<cr>", desc = "Export outputs to ipynb" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = { { "<leader>j", group = "Jupyter", icon = " " } },
    },
  },
}
