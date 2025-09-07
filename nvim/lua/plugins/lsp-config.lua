return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        opts = {
            auto_install = true,
        },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "ts_ls", "html", "biome", "ruff_lsp", "pyright", "rust_analyzer" },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local lspconfig = require("lspconfig")
            -- TypeScript
            if lspconfig.ts_ls then
                lspconfig.ts_ls.setup({
                    capabilities = capabilities,
                })
            else
                -- fallback for older lspconfig
                lspconfig.tsserver.setup({
                    capabilities = capabilities,
                })
            end
            lspconfig.html.setup({
                capabilities = capabilities,
            })
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
            })
            lspconfig.pyright.setup({
                capabilities = capabilities,
            })
            lspconfig.rust_analyzer.setup({
                settings = {
                    ["rust-analyzer"] = {},
                },
            })
        end,
    },
}
