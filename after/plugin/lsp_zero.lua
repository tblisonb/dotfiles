local lsp = require('lsp-zero')
local lspconfig = require('lspconfig')

lsp.preset('recommended')

lsp.on_attach(function(client, bufnr)
	lsp.default_keymaps({buffer = bufnr})
end)

lspconfig.ccls.setup {
	init_options = {
		compilationDatabaseDirectory = "build";
		index = {
			threads = 0;
		};
		clang = {
			excludeArgs = { "-frounding-math"} ;
		};
	}
}

require('lspconfig').ccls.setup({})
require('lspconfig').pyright.setup({})
