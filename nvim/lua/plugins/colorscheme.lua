return {
  'echasnovski/mini.base16',
  priority = 1000,
  config = function()
    require('mini.base16').setup({
      palette = {
        base00 = '#080808', -- background (from catppuccin base)
        base01 = '#111111', -- lighter bg (from surface1)
        base02 = '#1E1E1E', -- selection (from overlay0)
        base03 = '#555555', -- comments (from subtext1)
        base04 = '#878787', -- dark foreground (from subtext0)
        base05 = '#F5F5F5', -- foreground (from text)
        base06 = '#E5E5E5', -- light foreground (from lavender)
        base07 = '#F5F5F5', -- lightest foreground
        base08 = '#FF0000', -- red (variables, errors)
        base09 = '#FF6600', -- orange (constants, rosewater)
        base0A = '#FFFF00', -- yellow (classes, search)
        base0B = '#00FF00', -- green (strings)
        base0C = '#00FFFF', -- cyan (regex, support)
        base0D = '#44B4CC', -- blue (functions)
        base0E = '#9933CC', -- purple (keywords, mauve)
        base0F = '#870000', -- dark red (deprecated, maroon)
      },
    })

    -- Match Neovim's built-in terminal to the palette
    vim.g.terminal_color_0  = '#080808'
    vim.g.terminal_color_1  = '#FF0000'
    vim.g.terminal_color_2  = '#00FF00'
    vim.g.terminal_color_3  = '#FFFF00'
    vim.g.terminal_color_4  = '#44B4CC'
    vim.g.terminal_color_5  = '#9933CC'
    vim.g.terminal_color_6  = '#00FFFF'
    vim.g.terminal_color_7  = '#F5F5F5'
    vim.g.terminal_color_8  = '#555555'
    vim.g.terminal_color_9  = '#FF6600'
    vim.g.terminal_color_10 = '#CCFF04'
    vim.g.terminal_color_11 = '#FFCC00'
    vim.g.terminal_color_12 = '#0000FF'
    vim.g.terminal_color_13 = '#FF00FF'
    vim.g.terminal_color_14 = '#44B4CC'
    vim.g.terminal_color_15 = '#F5F5F5'
  end,
}
