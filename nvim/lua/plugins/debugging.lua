return {
  'mfussenegger/nvim-dap',
  dependencies = {
    {
      'rcarriga/nvim-dap-ui',
      dependencies = { 'nvim-neotest/nvim-nio' },
    },
    {
      'mfussenegger/nvim-dap-python',
      config = function()
        -- Use debugpy installed via Mason
        local ok, debugpy = pcall(function()
          return require('mason-registry')
            .get_package('debugpy')
            :get_install_path() .. '/venv/bin/python'
        end)
        if ok then
          require('dap-python').setup(debugpy)
        else
          vim.notify('debugpy not installed. Run :MasonInstall debugpy', vim.log.levels.WARN)
        end
      end,
    },
  },
  config = function()
    require('dapui').setup()

    local dap, dapui = require('dap'), require('dapui')
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    vim.keymap.set('n', '<Leader>dt', ':DapToggleBreakpoint<CR>', { silent = true, desc = 'Toggle breakpoint' })
    vim.keymap.set('n', '<Leader>dc', ':DapContinue<CR>', { silent = true, desc = 'Continue' })
    vim.keymap.set('n', '<Leader>dx', ':DapTerminate<CR>', { silent = true, desc = 'Terminate' })
    vim.keymap.set('n', '<Leader>do', ':DapStepOver<CR>', { silent = true, desc = 'Step over' })
  end,
}
