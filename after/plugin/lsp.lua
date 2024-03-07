local lsp = require('lsp-zero')
local lspconfig = require('lspconfig')

lsp.preset('recommended')

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({buffer = bufnr})
end)

require('mason').setup({})
require('mason-lspconfig').setup({
    ensure_installed = {},
    handlers = {
        lsp.default_setup,
    },
})

lspconfig.clangd.setup({})
