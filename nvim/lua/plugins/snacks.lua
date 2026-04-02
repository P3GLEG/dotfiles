return {
  'folke/snacks.nvim',
  priority = 900,
  lazy = false,
  opts = {
    -- File picker (replaces telescope)
    picker = { enabled = true },
    -- File explorer sidebar (replaces neo-tree)
    explorer = { enabled = true },
    -- Dashboard (replaces alpha)
    dashboard = {
      enabled = true,
      preset = {
        header = [[





       ████ ██████           █████      ██
      ███████████             █████
      █████████ ███████████████████ ███   ███████████
     █████████  ███    █████████████ █████ ██████████████
    █████████ ██████████ █████████ █████ █████ ████ █████
  ███████████ ███    ███ █████████ █████ █████ ████ █████
 ██████  █████████████████████ ████ █████ █████ ████ ██████


                                                                       ]],
      },
    },
    -- Notifications (replaces nvim-notify)
    notifier = { enabled = true },
    -- Big file handling (disable heavy features on large files)
    bigfile = { enabled = true },
    -- Better vim.ui.input
    input = { enabled = true },
    -- Indent guides (optional, you already have indent-blankline)
    indent = { enabled = false },
  },
  keys = {
    -- Picker keymaps (same as old telescope bindings)
    { '<leader>ff', function() Snacks.picker.files() end, desc = 'Find files' },
    { '<leader>fg', function() Snacks.picker.grep() end, desc = 'Live grep' },
    { '<leader>fb', function() Snacks.picker.buffers() end, desc = 'Buffers' },
    { '<leader>fh', function() Snacks.picker.help() end, desc = 'Help tags' },
    -- Explorer (same as old neo-tree binding)
    { '<leader>n', function() Snacks.explorer() end, desc = 'Toggle explorer' },
  },
}
