return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')

    -- Python linting is handled by ruff LSP server
    -- JS/TS linting is handled by biome LSP server
    -- Add per-filetype linters here as needed:
    lint.linters_by_ft = {}

    vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
