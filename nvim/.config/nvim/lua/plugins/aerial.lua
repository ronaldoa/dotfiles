return {
  "stevearc/aerial.nvim",
  opts = {
    backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
    filter_kind = {
      "Class",
      "Constructor",
      "Enum",
      "Function",
      "Interface",
      "Module",
      "Method",
      "Struct",
    },
  },
}
