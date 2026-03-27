return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()
      -- Install parsers
      local ensure = { "lua", "javascript", "python", "rust" }
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyDone",
        once = true,
        callback = function()
          vim.cmd("TSInstall " .. table.concat(ensure, " "))
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    enabled = true,
    opts = { mode = "cursor", max_lines = 3 },
    -- Simple toggle without LazyVim deps
    keys = {
      {
        "<leader>ut",
        function()
          local tsc = require("treesitter-context")
          tsc.toggle()
          vim.notify("Toggled Treesitter Context", vim.log.levels.INFO)
        end,
        desc = "Toggle Treesitter Context",
      },
    },
  },
}
