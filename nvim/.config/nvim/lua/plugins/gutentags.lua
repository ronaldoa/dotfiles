-- 多语言 gutentags 配置 (C, C++, Python, Java, Go, JS/TS)
return {
  "ludovicchabant/vim-gutentags",
  lazy = false,
  -- 用 init 而不是 config：部分选项只在插件加载时读取一次
  init = function()
    -- 是否启用 gutentags
    vim.g.gutentags_enabled = 1
    -- 保存文件时自动更新 tags
    vim.g.gutentags_generate_on_write = 1
    -- 如果 tags 文件不存在，自动创建
    vim.g.gutentags_generate_on_missing = 1

    -- 标签缓存目录
    vim.g.gutentags_cache_dir = vim.fn.expand("~/.cache/tags")

    -- 识别项目根的标志文件：.git 由插件默认加上；非 git 项目在根目录 touch .root
    -- 不用 package.json / pyproject.toml 等，否则 monorepo 子目录和 node_modules 里的包会被当成独立项目
    vim.g.gutentags_project_root = { ".root" }

    -- 打开依赖或插件里的文件时不生成 tags
    vim.cmd([[
      function! GutentagsSkipDeps(path) abort
        return a:path !~# '\v/(node_modules|site-packages|\.venv|venv|\.local/share/nvim|\.cargo|go/pkg)/'
      endfunction
    ]])
    vim.g.gutentags_init_user_func = "GutentagsSkipDeps"

    -- ctags 路径
    vim.g.gutentags_ctags_executable = "ctags"

    -- 用 fd 列文件：非 git 目录也遵守 .gitignore，并始终排除依赖和构建产物
    vim.g.gutentags_file_list_command =
      "fd -tf --no-require-git -E node_modules -E dist -E build -E .venv -E venv -E __pycache__"

    -- 支持的语言 + 参数
    vim.g.gutentags_ctags_extra_args = {
      "--fields=+l", -- 显示语言
      "--languages=C,C++,Python,Java,Go,JavaScript,TypeScript",
      "--c++-kinds=+px",
      "--c-kinds=+px",
      "--python-kinds=-iv", -- 忽略 import/变量
      "--java-kinds=+p", -- 加上 package
      "--js-kinds=+cfm", -- 函数/类/方法
      "--extras=+q",
    }

    -- 高级命令支持（如 :GutentagsToggleEnabled）
    vim.g.gutentags_define_advanced_commands = 1
  end,
}
