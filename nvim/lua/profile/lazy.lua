local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Bootstrap lazy.vim if not installed.
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- It's plugin time.
require("lazy").setup({
    { "rebelot/kanagawa.nvim" },
    { "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate" },
    { "mbbill/undotree" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "VonHeikemen/lsp-zero.nvim",
        branch = "v3.x" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/nvim-cmp" },
    { "L3MON4D3/LuaSnip" },
    { "junegunn/fzf",
        build = "./install --bin" },
    { "junegunn/fzf.vim" },
    { "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "petertriho/nvim-scrollbar" },
    { "numToStr/Comment.nvim",
        lazy = false },
    { "gbprod/stay-in-place.nvim" },
    { "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "nvim-treesitter/nvim-treesitter-context" },
    { "gpanders/vim-oldfiles" },
    { 'rmagatti/auto-session' },
    { 'windwp/nvim-ts-autotag' },
    { 'github/copilot.vim' },
})
