--------------------------------------------------------------------------------
-- init.lua
--
-- Personal Neovim configuration. Plugins are managed by lazy.nvim.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Bootstrap lazy.nvim
--------------------------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

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

--------------------------------------------------------------------------------
-- Plugins
--------------------------------------------------------------------------------

require("lazy").setup({
    { "rebelot/kanagawa.nvim" },
    { "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate" },
    { "mbbill/undotree" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/nvim-cmp" },
    { "L3MON4D3/LuaSnip" },
    { "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "petertriho/nvim-scrollbar" },
    { "numToStr/Comment.nvim",
        lazy = false },
    { "gbprod/stay-in-place.nvim" },
    { "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "nvim-treesitter/nvim-treesitter-context" },
    { "rmagatti/auto-session" },
    { "windwp/nvim-ts-autotag" },
    { "stevearc/conform.nvim" },
    { "mfussenegger/nvim-lint" },
    { "folke/which-key.nvim" },
    { "stevearc/oil.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "nvim-mini/mini.nvim" },
})

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

-- Must run before applying the colorscheme below; kanagawa defaults to
-- italic comments (commentStyle = { italic = true }).
require("kanagawa").setup({
    commentStyle = { italic = false },
    -- @keyword.conditional.ternary (the ?/: in a ternary) has no explicit
    -- entry of its own in kanagawa's treesitter highlights, so it falls
    -- back to the base @keyword group, which - like all @keyword* groups -
    -- is italic via keywordStyle. Overriding it here (rather than setting
    -- keywordStyle = { italic = false }) keeps other keywords (if/else/
    -- return/etc.) italic as before and only changes the ternary operator.
    overrides = function(colors)
        return {
            ["@keyword.conditional.ternary"] = {
                fg = colors.theme.syn.keyword,
                italic = false,
            },
        }
    end,
})
vim.cmd.colorscheme("kanagawa")
vim.opt.colorcolumn = { "80", "127" }
vim.o.termguicolors = true
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,"
    .. "winpos,terminal,localoptions"

vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = { current_line = true },
})

vim.opt.scrolloff = 10
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.cindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.listchars = {
    eol = "↵",
    tab = "→ ",
    nbsp = "␣",
    trail = "•",
    extends = "⟩",
    precedes = "⟨",
}

vim.opt.list = true
vim.opt.textwidth = 127
vim.opt.wrap = false

vim.opt.spelllang = "en_us"
vim.opt.spell = true

vim.opt.incsearch = true

vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = (os.getenv("HOME") or os.getenv("USERPROFILE"))
    .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.updatetime = 50

-- This is redundant with the lualine plugin and obscures status info in some
-- contexts.
vim.opt.showmode = false

-- lsp.log grows infinitely; at one point it was over a gig so just disable it.
vim.lsp.log.set_level("off")

if vim.loop.os_uname().sysname == "Windows_NT" then
    -- Idk how this worked before nvim 0.10 but undotree can't find default
    -- 'diff' command so we have to specify on Windows.
    vim.g.undotree_DiffCommand = "FC"

    local user_profile = vim.fn.getenv("USERPROFILE")
    vim.g.python3_host_prog = user_profile
        .. "/.pyenv/pyenv-win/versions/3.8.10/python.exe"

    -- Native Windows nvim.exe talks to terminals through the ConPTY layer,
    -- which has historically stripped curly/colored-underline escape codes
    -- even when both nvim and the terminal (e.g. WezTerm) support them - so
    -- undercurl (used for SpellBad, LSP diagnostics, etc.) silently doesn't
    -- render unless forced here instead of relying on nvim's auto-detection.
    vim.cmd([[let &t_Cs = "\e[4:3m"]])
    vim.cmd([[let &t_Ce = "\e[4:0m"]])
    vim.cmd([[let &t_AU = "\e[58:2::%lu:%lu:%lum"]])
end

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------

vim.g.mapleader = " "

-- Open oil.nvim in the directory associated with the current buffer. This
-- used to open netrw via vim.cmd.Ex, but oil's default_file_explorer = true
-- disables netrw entirely (rather than just intercepting it), so :Ex itself
-- no longer works.
vim.keymap.set("n", "<leader>v", function() require("oil").open() end)

-- Toggle Undotree.
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Change the default behavior of pasting in visual mode; anything selected
-- will be deleted, with the contents sent to the black hole register, then
-- the unnamed register contents will be pasted. This preserves the contents
-- of the unnamed register after the paste, which frankly is the behavior I
-- expect not coming from Vim. I don't ever find myself wanting to
-- effectively paste and yank something in the same operation.
vim.keymap.set("v", "p", '"_dP')

-- Re-center cursor when jumping around text.
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")
vim.keymap.set("n", "gg", "ggzz")
vim.keymap.set("n", "G", "Gzz")

-- Move cursor to the end of the visual selection after yank.
-- vim.keymap.set("v", "y", "y']")

-- Move selected lines up and down, inserting them as it goes.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Preserve cursor position when appending line below.
vim.keymap.set("n", "J", "mzJ`z")

-- Re-center cursor when jumping between search terms.
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Yank into '+' register (system clipboard).
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

-- Need a way to get back indentation on a line with whitespace cleared;
-- deleted contents should go to the black hole register as to not override
-- anything.
vim.keymap.set("n", "<leader>i", '"_ddO')

-- Insert matching braces.
vim.keymap.set("i", "{<CR>", "{<CR>}<Esc>O")
vim.keymap.set("i", "(<CR>", "(<CR>)<Esc>O")
vim.keymap.set("i", "[<CR>", "[<CR>]<Esc>O")

-- desc is set on all of these (rather than the plain trailing comments used
-- elsewhere in this file) so which-key.nvim shows a useful label for them.
local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>gg", fzf.grep, { desc = "Grep global" })
vim.keymap.set("n", "<leader>gb", fzf.lgrep_curbuf, { desc = "Grep buffer" })
vim.keymap.set("n", "<leader>gl", fzf.grep_last, { desc = "Grep last" })
vim.keymap.set("n", "<leader>gw", fzf.grep_cword, { desc = "Grep word" })
vim.keymap.set("n", "<leader>gW", fzf.grep_cWORD, { desc = "Grep WORD" })
vim.keymap.set("v", "<leader>gv", fzf.grep_visual, { desc = "Grep visual" })
vim.keymap.set("n", "<leader>fh", fzf.oldfiles, { desc = "File history" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "File buffers" })
vim.keymap.set("n", "<leader>ss", fzf.spell_suggest, { desc = "Spell suggest" })

-- This is because I'm lazy - it selects all lines in the current buffer.
vim.keymap.set("n", "<C-a>", "ggVGzz")

-- With search highlighting enabled (which it is by default) normally the
-- terms will remain highlighted until the next search is done or by
-- pressing Ctrl + l. This remap means anytime escape is hit it will clear
-- the highlights, which feels more intuitive to me.
vim.keymap.set("n", "<Esc>", function() vim.cmd("noh") end)

-- I find I accidentally hit F1 a lot when going to hit escape which brings
-- up help info so disable it.
vim.keymap.set("i", "<F1>", "<Esc>")
vim.keymap.set("n", "<F1>", "<Esc>")
vim.keymap.set("v", "<F1>", "<Esc>")

-- These seem to jump up or down to the start or end of the scrolloff
-- respectively. I don't ever use it and I find myself accidentally hitting
-- shift pretty often and it screws me up so just remap these to 'h' and 'l'.
vim.keymap.set("n", "H", "h")
vim.keymap.set("n", "L", "l")

--------------------------------------------------------------------------------
-- Autocommands
--------------------------------------------------------------------------------

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    callback = function()
        -- Save the current cursor position.
        local save_cursor = vim.fn.getpos(".")
        -- Remove trailing whitespace.
        pcall(function() vim.cmd([[%s/\s\+$//e]]) end)
        -- Convert tabs to spaces (width of 4).
        pcall(function() vim.cmd([[%s/\t/    /eg]]) end)
        -- Restore the original cursor position; otherwise the cursor gets
        -- reset to the beginning of the current line.
        vim.fn.setpos(".", save_cursor)
    end,
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = { "*" },
    callback = function()
        -- Run check.py on the current buffer.
        pcall(function()
            if string.find(vim.fn.getcwd(), "C:\\working\\systems", 0) then
                local file = vim.api.nvim_buf_get_name(0)
                local checkScript = "C:/working/systems/shared/bin/check.py"
                local result = vim.fn.system(
                    string.format([[%s -q %s]], checkScript, file))
                if result ~= nil and result ~= "" then
                    -- Print the result to the command line only if it is not
                    -- empty.
                    print(result)
                end
            end
        end)
    end,
})

-- v:oldfiles is only loaded from shada at startup and otherwise doesn't
-- update as files are visited within a session, so fzf-lua's oldfiles
-- picker (<leader>fh) would keep showing a static, launch-time snapshot.
-- This replicates the one thing gpanders/vim-oldfiles was doing for us:
-- move the current file to the front of v:oldfiles every time it's
-- displayed, same as its own oldfiles#add().
vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*",
    callback = function(args)
        local fname = vim.api.nvim_buf_get_name(args.buf)
        if fname == "" or vim.fn.filereadable(fname) == 0
            or not vim.bo[args.buf].buflisted then
            return
        end
        fname = vim.fn.fnamemodify(fname, ":p")
        local rest = vim.tbl_filter(
            function(f) return f ~= fname end, vim.v.oldfiles)
        table.insert(rest, 1, fname)
        vim.v.oldfiles = rest
    end,
})

--------------------------------------------------------------------------------
-- Plugin setup
--------------------------------------------------------------------------------

require("auto-session").setup({
    log_level = "error",
})

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
    mapping = cmp.mapping.preset.insert({
        -- `Enter` key to confirm completion
        ["<CR>"] = cmp.mapping.confirm({ select = false }),

        -- Ctrl+Space to trigger completion menu
        ["<C-Space>"] = cmp.mapping.complete(),

        -- Navigate between snippet placeholder
        ["<C-f>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(1) then
                luasnip.jump(1)
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<C-b>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),

        -- Scroll up and down in the completion documentation
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
    }),
    -- Without this, cmp has nothing to pull completions from at all - LSP
    -- diagnostics/hover/etc. still work fine, but no completion menu ever
    -- appears regardless of what's attached.
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
    }),
})

require("Comment").setup()

local fzflua = require("fzf-lua")
fzflua.setup({
    lsp = {
        code_actions = {
            previewer = "codeaction_native",
            preview_pager = "delta --side-by-side "
                .. "--width=$FZF_PREVIEW_COLUMNS "
                .. "--hunk-header-style='omit' --file-style='omit'",
        },
    },
    -- Sort files in a search; this prevents the returned files from being in
    -- an indeterminate order.
    files = {
        rg_opts = "--sort=path --color=always --files --hidden --follow",
    },
    -- grep = {
    --     rg_opts = "--sort=path --color=always --hidden --follow "
    --         .. "--line-number --column --multiline",
    -- },
})

require("mason").setup({})

-- Advertises richer completion capabilities (snippets, etc.) to each server
-- so cmp's "nvim_lsp" source has more to work with.
local cmp_nvim_lsp = require("cmp_nvim_lsp")
vim.lsp.config("clangd", {
    capabilities = vim.tbl_deep_extend("force",
        cmp_nvim_lsp.default_capabilities(),
        { offsetEncoding = { "utf-16" } }),
})
vim.lsp.enable({ "clangd" })

vim.lsp.config("omnisharp", {
    -- nvim-lspconfig's base cmd for omnisharp resolves an "OmniSharp"/
    -- "omnisharp" executable on PATH; since Mason installs the DLL directly,
    -- this replaces just the invocation while keeping the rest of the base
    -- args - most importantly `--languageserver`, without which OmniSharp
    -- speaks its own legacy stdio protocol instead of actual LSP and nothing
    -- works.
    cmd = {
        "dotnet",
        "C:/Users/Tanner/AppData/Local/nvim-data/mason/packages/"
            .. "omnisharp/libexec/OmniSharp.dll",
        "-z",
        "--hostPID", tostring(vim.fn.getpid()),
        "DotNet:enablePackageRestore=false",
        "--encoding", "utf-8",
        "--languageserver",
    },
    capabilities = cmp_nvim_lsp.default_capabilities(),
    settings = {
        FormattingOptions = {
            -- Enables support for reading code style, naming convention and
            -- analyzer settings from .editorconfig.
            EnableEditorConfigSupport = true,
            -- Specifies whether 'using' directives should be grouped and
            -- sorted during document formatting.
            OrganizeImports = nil,
        },
        MsBuild = {
            -- If true, MSBuild project system will only load projects for
            -- files that were opened in the editor. This setting is useful
            -- for big C# codebases and allows for faster initialization of
            -- code navigation features only for projects that are relevant
            -- to code that is being edited. With this setting enabled
            -- OmniSharp may load fewer projects and may thus display
            -- incomplete reference lists for symbols.
            LoadProjectsOnDemand = nil,
        },
        RoslynExtensionsOptions = {
            -- Enables support for roslyn analyzers, code fixes and rulesets.
            EnableAnalyzersSupport = nil,
            -- Enables support for showing unimported types and unimported
            -- extension methods in completion lists. When committed, the
            -- appropriate using directive will be added at the top of the
            -- current file. This option can have a negative impact on
            -- initial completion responsiveness, particularly for the first
            -- few completion sessions after opening a solution.
            EnableImportCompletion = nil,
            -- Only run analyzers against open files when
            -- 'enableRoslynAnalyzers' is true
            AnalyzeOpenDocumentsOnly = nil,
        },
        Sdk = {
            -- Specifies whether to include preview versions of the .NET SDK
            -- when determining which version to use for project loading.
            IncludePrereleases = true,
        },
    },
})
vim.lsp.enable({ "omnisharp" })

vim.lsp.config("pyright", {
    -- The system PYTHONPATH is set to ".;..;..\..;..." (several levels of
    -- parent directories), which always reaches the drive root - and since
    -- C:\tools exists (this is Neovim's own install directory), Python
    -- treats it as an implicit namespace package literally called "tools",
    -- shadowing any real bin/tools.py-style local module with an empty
    -- stand-in. pyright inherits this since it's spawned as a child of
    -- Neovim, so attribute access on such modules silently resolves to
    -- nothing. Clearing PYTHONPATH just for this process fixes resolution
    -- without touching the environment scripts actually run in.
    cmd_env = { PYTHONPATH = "" },
    capabilities = cmp_nvim_lsp.default_capabilities(),
})
vim.lsp.enable({ "pyright" })

--  This function gets run when an LSP attaches to a particular buffer. That
--  is to say, every time a new file is opened that is associated with an
--  lsp (for example, opening `main.rs` is associated with `rust_analyzer`)
--  this function will be executed to configure the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup(
        "kickstart-lsp-attach", { clear = true }),
    callback = function(event)
        -- NOTE: Remember that lua is a real programming language, and as
        -- such it is possible to define small helper and utility functions
        -- so you don't have to repeat yourself many times.
        --
        -- In this case, we create a function that lets us more easily
        -- define mappings specific for LSP related items. It sets the mode,
        -- buffer and description for us each time.
        local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func,
                { buffer = event.buf, desc = "LSP: " .. desc })
        end
        local fzf = require("fzf-lua")

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a
        --  function is defined, etc. To jump back, press <C-t>.
        map("gd", fzf.lsp_definitions, "[G]oto [D]efinition")

        -- Find references for the word under your cursor.
        map("gr", fzf.lsp_references, "[G]oto [R]eferences")

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an
        --  actual implementation.
        map("gi", fzf.lsp_implementations, "[G]oto [I]mplementation")

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want
        --  to see the definition of its *type*, not where it was *defined*.
        map("<leader>D", fzf.lsp_typedefs, "Type [D]efinition")

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map("<leader>ds", fzf.lsp_document_symbols, "[D]ocument [S]ymbols")

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your whole
        --  project.
        map("<leader>ws", fzf.lsp_live_workspace_symbols,
            "[W]orkspace [S]ymbols")

        -- Execute a code action, usually your cursor needs to be on top of
        -- an error or a suggestion from your LSP for this to activate.
        -- map('<leader>ca', fzf.lsp_code_actions, '[C]ode [A]ction')

        -- Rename the variable under your cursor
        --  Most Language Servers support renaming across files, etc.
        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

        -- Opens a popup that displays documentation about the word under
        -- your cursor. See `:help K` for why this keymap
        map("K", vim.lsp.buf.hover, "Hover Documentation")

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        -- These used to come from lsp-zero.nvim's default_keymaps(); kept
        -- here directly now that the (dead upstream) plugin is gone.
        map("go", vim.lsp.buf.type_definition, "[G]oto type definition")
        map("gs", vim.lsp.buf.signature_help, "Show [S]ignature help")
        map("gl", vim.diagnostic.open_float, "Show diagnostic")

        -- vim.diagnostic.goto_prev()/goto_next() are deprecated in favor of
        -- jump(); on_jump replicates their old default of opening a
        -- floating diagnostic window at the cursor after moving (passing
        -- `float = true` to jump() still works, but just triggers another
        -- deprecation notice).
        local function openDiagnosticFloatOnJump(_, bufnr)
            vim.diagnostic.open_float(
                { bufnr = bufnr, scope = "cursor", focus = false })
        end
        map("[d", function()
            vim.diagnostic.jump(
                { count = -1, on_jump = openDiagnosticFloatOnJump })
        end, "Previous diagnostic")
        map("]d", function()
            vim.diagnostic.jump(
                { count = 1, on_jump = openDiagnosticFloatOnJump })
        end, "Next diagnostic")

        map("<F2>", vim.lsp.buf.rename, "Rename symbol")
        -- lsp_format = "fallback" uses conform's own formatters (stylua,
        -- ruff_format, etc.) where configured, and otherwise falls back to
        -- this client's own LSP formatting - same behavior as before conform
        -- was added, for filetypes with no formatter configured.
        local function formatBufferOrSelection()
            require("conform").format({ async = true, lsp_format = "fallback" })
        end
        map("<F3>", formatBufferOrSelection, "Format file")
        vim.keymap.set("x", "<F3>", formatBufferOrSelection,
            { buffer = event.buf, desc = "LSP: Format selection" })

        -- The following two autocommands are used to highlight references
        -- of the word under your cursor when your cursor rests there for a
        -- little while. See `:help CursorHold` for information about when
        -- this is executed.
        --
        -- When you move your cursor, the highlights will be cleared (the
        -- second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end

        local codeActionMethod =
            vim.lsp.protocol.Methods.textDocument_codeAction
        if client:supports_method(codeActionMethod) then
            map("<leader>ca", function()
                require("fzf-lua").lsp_code_actions({
                    winopts = {
                        preview = { horizontal = "up:80%" },
                    },
                })
            end, "Code actions")

            -- Also from lsp-zero.nvim's default_keymaps().
            map("<F4>", vim.lsp.buf.code_action, "Execute code action")
            vim.keymap.set("x", "<F4>", vim.lsp.buf.code_action,
                { buffer = event.buf, desc = "LSP: Execute code action" })
        end
    end,
})

require("lualine").setup({
    extensions = { "fzf", "lazy", "mason" },
    options = {
        globalstatus = true,
    },
    sections = {
        lualine_b = {
            require("auto-session.lib").current_session_name,
        },
        lualine_c = {
            {
                "filename",
                path = 1, -- 0: Just the filename
                          -- 1: Relative path
                          -- 2: Absolute path
                          -- 3: Absolute path, with tilde as the home
                          --    directory
                          -- 4: Filename and parent dir, with tilde as the
                          --    home directory
            },
        },
    },
})

require("scrollbar").setup()

require("stay-in-place").setup()

require("oil").setup({
    -- Makes oil the explorer for directory buffers (e.g. `:e some/dir`).
    -- This disables netrw outright rather than just intercepting it, so
    -- <leader>v below calls oil directly instead of vim.cmd.Ex.
    default_file_explorer = true,
})

require("mini.pairs").setup()
require("mini.surround").setup()

-- ruff (Python) and stylua (Lua) are Mason-installed specifically for this;
-- clangd/omnisharp already format C/C++/C# well enough via LSP fallback.
require("conform").setup({
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
    },
})

require("lint").linters_by_ft = {
    python = { "ruff" },
}
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
    callback = function()
        require("lint").try_lint()
    end,
})

local wk = require("which-key")
wk.setup({})
wk.add({
    { "<leader>f", group = "Find" },
    { "<leader>g", group = "Grep" },
})

-- "vim"/"vimdoc" are included even though nothing edits vimscript directly:
-- Neovim core bundles its own (older) parsers for them, but nvim-treesitter's
-- query files target a newer grammar revision, causing "invalid node type"
-- errors wherever lua's injections.scm embeds vim syntax (e.g.
-- vim.cmd([[...]]) blocks). Installing them here overrides core's bundled
-- parser with one that actually matches the query.
require("nvim-treesitter").install(
    { "c", "cpp", "python", "lua", "vim", "vimdoc" })

-- Highlight any buffer whose language already has a parser installed. This
-- is the `main`-branch replacement for the old `highlight.enable = true`
-- module; unlike the retired `auto_install = true`, it won't fetch a parser
-- on first use of a new filetype, only highlight ones already present.
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft) or ft
        if vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf, lang)
        end
    end,
})

require("nvim-ts-autotag").setup()

require("treesitter-context").setup({
    max_lines = 10,
})
