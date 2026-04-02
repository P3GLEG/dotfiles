return {
  {
    'mason-org/mason.nvim',
    lazy = false,
    config = function()
      require('mason').setup()
    end,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    lazy = false,
    dependencies = { 'mason-org/mason.nvim' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {
          'lua_ls',
          'ts_ls',
          'html',
          'biome',
          'basedpyright',
          'ruff',
        },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = { 'mason-org/mason-lspconfig.nvim' },
    config = function()
      -- Lua
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = { diagnostics = { globals = { 'vim' } } },
        },
      })

      -- TypeScript / JavaScript
      vim.lsp.config('ts_ls', {})

      -- HTML
      vim.lsp.config('html', {})

      -- Biome (JS/TS formatting)
      vim.lsp.config('biome', {})

      -- Python: basedpyright for type checking + intellisense
      vim.lsp.config('basedpyright', {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = 'standard',
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = 'workspace',
            },
          },
          -- Let ruff handle import organization
          pyright = { disableOrganizeImports = true },
        },
      })

      -- Python: ruff for linting + formatting
      vim.lsp.config('ruff', {})

      -- Enable all servers
      vim.lsp.enable({
        'lua_ls', 'ts_ls', 'html', 'biome',
        'basedpyright', 'ruff',
      })

      -- Disable ruff's hover (basedpyright handles hover docs)
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == 'ruff' then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })

      -- gd is NOT a Neovim 0.11 default — add it manually
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
    end,
  },
}
