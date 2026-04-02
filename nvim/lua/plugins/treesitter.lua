return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({
        'bash', 'c', 'diff', 'html', 'json', 'lua', 'luadoc',
        'javascript', 'markdown', 'markdown_inline', 'python',
        'query', 'regex', 'rust', 'toml', 'vim', 'vimdoc', 'yaml',
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    opts = { mode = 'cursor', max_lines = 3 },
    keys = {
      {
        '<leader>ut',
        function()
          local tsc = require('treesitter-context')
          tsc.toggle()
          vim.notify('Toggled Treesitter Context', vim.log.levels.INFO)
        end,
        desc = 'Toggle Treesitter Context',
      },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      local move = require('nvim-treesitter-textobjects.move')
      local ts_repeat_move = require('nvim-treesitter-textobjects.repeatable_move')

      -- Repeatable movement with ; and ,
      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move_next)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_previous)

      -- Function movements
      vim.keymap.set({ 'n', 'x', 'o' }, ']f', function()
        move.goto_next_start('@function.outer')
      end, { desc = 'Next function' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[f', function()
        move.goto_previous_start('@function.outer')
      end, { desc = 'Previous function' })

      -- Class movements
      vim.keymap.set({ 'n', 'x', 'o' }, ']c', function()
        move.goto_next_start('@class.outer')
      end, { desc = 'Next class' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[c', function()
        move.goto_previous_start('@class.outer')
      end, { desc = 'Previous class' })

      -- Parameter movements
      vim.keymap.set({ 'n', 'x', 'o' }, ']a', function()
        move.goto_next_start('@parameter.inner')
      end, { desc = 'Next parameter' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[a', function()
        move.goto_previous_start('@parameter.inner')
      end, { desc = 'Previous parameter' })
    end,
  },
}
