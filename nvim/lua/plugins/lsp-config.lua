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
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "ts_ls", "html", "biome", "ruff", "pyright", "rust_analyzer" },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            vim.lsp.config("ts_ls", { capabilities = capabilities })
            vim.lsp.config("html", { capabilities = capabilities })
            vim.lsp.config("lua_ls", { capabilities = capabilities })
            vim.lsp.config("pyright", { capabilities = capabilities })
            vim.lsp.config("rust_analyzer", {
                capabilities = capabilities,
                settings = { ["rust-analyzer"] = {} },
            })

            vim.lsp.enable({ "ts_ls", "html", "lua_ls", "pyright", "rust_analyzer" })
        end,
    },
}
