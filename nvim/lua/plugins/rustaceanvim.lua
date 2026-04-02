return {
  'mrcjkb/rustaceanvim',
  version = '^6',
  lazy = false,
  init = function()
    vim.g.rustaceanvim = {
      server = {
        settings = {
          ['rust-analyzer'] = {
            cargo = { allFeatures = true },
            checkOnSave = {
              command = 'clippy',
              extraArgs = { '--no-deps' },
            },
            procMacro = { enable = true },
          },
        },
      },
    }
  end,
}
