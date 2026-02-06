-- 多语言 gutentags 配置 (C, C++, Python, Java, Go, JS/TS)
return {
  "ludovicchabant/vim-gutentags",
  lazy = false,
  config = function()
    -- 是否启用 gutentags
    vim.g.gutentags_enabled = 1
    -- 保存文件时自动更新 tags
    vim.g.gutentags_generate_on_write = 1
    -- 如果 tags 文件不存在，自动创建
    vim.g.gutentags_generate_on_missing = 1

    -- 标签缓存目录
    vim.g.gutentags_cache_dir = vim.fn.expand("~/.cache/tags")
    vim.fn.mkdir(vim.g.gutentags_cache_dir, "p")

    -- 识别项目根的标志文件
    vim.g.gutentags_project_root = {
      ".git",
      "Makefile",
      "package.json",
      "pyproject.toml",
      "setup.py",
      "pom.xml",
      "go.mod",
    }

    -- ctags 路径
    vim.g.gutentags_ctags_executable = "ctags"

    -- 使用 fd 提高性能（需已安装 fd）
    vim.g.gutentags_file_list_command = "fd -tf"

    -- 支持的语言 + 参数
    vim.g.gutentags_ctags_extra_args = {
      "--fields=+l", -- 显示语言
      "--languages=C,C++,Python,Java,Go,JavaScript,TypeScript",
      "--c++-kinds=+px",
      "--c-kinds=+px",
      "--python-kinds=-iv", -- 忽略 import/变量
      "--java-kinds=+p", -- 加上 package
      "--js-kinds=+cfm", -- 函数/类/方法
      "--extra=+q",
    }

    -- 高级命令支持（如 :GutentagsToggleEnabled）
    vim.g.gutentags_define_advanced_commands = 1
  end,
}
