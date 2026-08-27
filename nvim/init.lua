-------------------------------------------------------------------------------------------------------------------------------
-- init.lua
--
-- Personal Neovim configuration. Plugins are managed by lazy.nvim.
-------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------
-- Bootstrap lazy.nvim
-------------------------------------------------------------------------------------------------------------------------------

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


-------------------------------------------------------------------------------------------------------------------------------
-- Plugins
-------------------------------------------------------------------------------------------------------------------------------

require("lazy").setup({
    { "rebelot/kanagawa.nvim" },
    { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate" },
    { "mbbill/undotree" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "ibhagwan/fzf-lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "petertriho/nvim-scrollbar" },
    { "gbprod/stay-in-place.nvim" },
    { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "nvim-treesitter/nvim-treesitter-context" },
    { "rmagatti/auto-session" },
    { "windwp/nvim-ts-autotag" },
    { "stevearc/oil.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "nvim-mini/mini.nvim" },
})


-------------------------------------------------------------------------------------------------------------------------------
-- Options
-------------------------------------------------------------------------------------------------------------------------------

-- Must run before applying the colorscheme below; kanagawa defaults to italic comments (commentStyle = { italic = true }).
require("kanagawa").setup({
    commentStyle = { italic = false },
    -- @keyword.conditional.ternary (the ?/: in a ternary) has no explicit entry of its own in kanagawa's treesitter
    -- highlights, so it falls back to the base @keyword group, which - like all @keyword* groups - is italic via keywordStyle.
    -- Overriding it here (rather than setting keywordStyle = { italic = false }) keeps other keywords (if/else/ return/etc.)
    -- italic as before and only changes the ternary operator.
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
vim.opt.colorcolumn = { --[["80",]] "127" }
vim.o.termguicolors = true
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

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

vim.opt.listchars = { eol = "↵", tab = "→ ", nbsp = "␣", trail = "•", extends = "⟩", precedes = "⟨", }

vim.opt.list = true
vim.opt.textwidth = 127
vim.opt.wrap = false

vim.opt.spelllang = "en_us"
vim.opt.spell = true
vim.opt.spelloptions = "camel"

vim.opt.incsearch = true

vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = (os.getenv("HOME") or os.getenv("USERPROFILE")) .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.updatetime = 50

-- This is redundant with the lualine plugin and obscures status info in some contexts.
vim.opt.showmode = false

-- lsp.log grows infinitely; at one point it was over a gig, so just disable it.
vim.lsp.log.set_level("off")

if vim.loop.os_uname().sysname == "Windows_NT" then
    -- Idk why this worked before nvim 0.10, but undotree can't find default "diff" command so we have to specify on Windows.
    vim.g.undotree_DiffCommand = "FC"

    local user_profile = vim.fn.getenv("USERPROFILE")
    vim.g.python3_host_prog = user_profile .. "/.pyenv/pyenv-win/versions/3.8.10/python.exe"
end


-------------------------------------------------------------------------------------------------------------------------------
-- Keymaps
-------------------------------------------------------------------------------------------------------------------------------

vim.g.mapleader = " "

-- Open oil.nvim in the directory associated with the current buffer. This used to open netrw via vim.cmd.Ex, but oil's
-- default_file_explorer = true disables netrw entirely (rather than just intercepting it), so :Ex itself no longer works.
vim.keymap.set("n", "-", function() require("oil").open() end)

-- Toggle Undotree.
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Change the default behavior of pasting in visual mode; anything selected will be deleted, with the contents sent to the
-- black hole register, then the unnamed register contents will be pasted. This preserves the contents of the unnamed register
-- after the paste, which, frankly, is the behavior I expect. I don't ever find myself wanting to effectively paste and yank
-- something in the same operation.
vim.keymap.set("v", "p", '"_dP')

-- Re-center cursor when jumping around text.
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")
vim.keymap.set("n", "gg", "ggzz")
vim.keymap.set("n", "G", "Gzz")

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

-- Need a way to get back indentation on a line with whitespace cleared; deleted contents should go to the black hole register
-- as to not override anything.
vim.keymap.set("n", "<leader>i", '"_ddO')

-- Insert matching braces.
vim.keymap.set("i", "{<CR>", "{<CR>}<Esc>O")
vim.keymap.set("i", "(<CR>", "(<CR>)<Esc>O")
vim.keymap.set("i", "[<CR>", "[<CR>]<Esc>O")

local fzf = require("fzf-lua")

-- fzf-lua's built-in oldfiles picker pulls from v:oldfiles/the current session globally, so switching projects still surfaces
-- files from whatever project was open last. This rebuilds the same picker (icons, previewer, actions) but restricted to files
-- under the current working directory and capped to the 50 most recent - v:oldfiles is already most-recent-first thanks to the
-- BufWinEnter autocmd below, so taking the first 50 matches is correct.
local function projectOldfiles()
    local opts = require("fzf-lua.config").normalize_opts({}, "oldfiles")
    local make_entry = require("fzf-lua.make_entry")
    local cwd = vim.fn.getcwd():gsub("\\", "/"):lower() .. "/"
    local entries = {}
    for _, file in ipairs(vim.v.oldfiles) do
        local normalized = file:gsub("\\", "/"):lower()
        if vim.startswith(normalized, cwd) and vim.fn.filereadable(file) == 1 then
            table.insert(entries, make_entry.file(file, opts))
            if #entries >= 50 then break end
        end
    end
    fzf.fzf_exec(entries, opts)
end

-- Setup fzf-lua keymaps.
vim.keymap.set("n", "<leader>ff", fzf.files,         { desc = "Find files" })
vim.keymap.set("n", "<leader>gg", fzf.grep,          { desc = "Grep global" })
vim.keymap.set("n", "<leader>gb", fzf.lgrep_curbuf,  { desc = "Grep buffer" })
vim.keymap.set("n", "<leader>gl", fzf.grep_last,     { desc = "Grep last" })
vim.keymap.set("n", "<leader>gw", fzf.grep_cword,    { desc = "Grep word" })
vim.keymap.set("n", "<leader>gW", fzf.grep_cWORD,    { desc = "Grep WORD" })
vim.keymap.set("v", "<leader>gv", fzf.grep_visual,   { desc = "Grep visual" })
vim.keymap.set("n", "<leader>fh", projectOldfiles,   { desc = "File history (project)" })
vim.keymap.set("n", "<leader>fH", fzf.oldfiles,      { desc = "File history (global)" })
vim.keymap.set("n", "<leader>fb", fzf.buffers,       { desc = "File buffers" })
vim.keymap.set("n", "<leader>ss", fzf.spell_suggest, { desc = "Spell suggest" })

-- With search highlighting enabled (which it is by default) normally the terms will remain highlighted until the next search
-- is done or by pressing Ctrl + l. This remap means anytime escape is hit it will clear the highlights, which feels more
-- intuitive to me.
vim.keymap.set("n", "<Esc>", function() vim.cmd("noh") end)

-- I find I accidentally hit F1 a lot when going to hit escape which brings up help info, so we disable it here.
vim.keymap.set("i", "<F1>", "<Esc>")
vim.keymap.set("n", "<F1>", "<Esc>")
vim.keymap.set("v", "<F1>", "<Esc>")

-- These seem to jump up or down to the start or end of the scrolloff respectively. I don't ever use it and I find myself
-- accidentally hitting shift pretty often and it screws me up, so just remap these to "h" and "l".
vim.keymap.set("n", "H", "h")
vim.keymap.set("n", "L", "l")


-------------------------------------------------------------------------------------------------------------------------------
-- Autocommands
-------------------------------------------------------------------------------------------------------------------------------

-- This function removes all trailing whitespace and converts any tabs to spaces (width of 4). Prior to actually doing this, it
-- saves the current cursor position, then restores it afterwards; otherwise the cursor would move.
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    callback = function()
        local save_cursor = vim.fn.getpos(".")
        pcall(function() vim.cmd([[%s/\s\+$//e]]) end)
        pcall(function() vim.cmd([[%s/\t/    /eg]]) end)
        vim.fn.setpos(".", save_cursor)
    end,
})

-- This function will call check.py and pass it an argument, which is the file associated with the current buffer. check.py
-- parses the file and will note any invalid formatting if there is any via prints to stdout. This is Windows only.
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = { "*" },
    callback = function()
        -- Run check.py on the current buffer.
        pcall(function()
            if vim.loop.os_uname().sysname == "Windows_NT" and string.find(vim.fn.getcwd(), "C:\\working\\systems", 0) then
                local file = vim.api.nvim_buf_get_name(0)
                local checkScript = "C:/working/systems/shared/bin/check.py"
                local result = vim.fn.system(string.format([[%s -q %s]], checkScript, file))
                if result ~= nil and result ~= "" then
                    -- Print the result to the command line only if it is not empty.
                    print(result)
                end
            end
        end)
    end,
})

-- v:oldfiles is only loaded from shada at startup and otherwise doesn't update as files are visited within a session, so
-- fzf-lua's oldfiles picker (<leader>fh) would keep showing a static, launch-time snapshot. This replicates the one thing
-- gpanders/vim-oldfiles was doing for us: move the current file to the front of v:oldfiles every time it's displayed, same as
-- its own oldfiles#add().
vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*",
    callback = function(args)
        local fname = vim.api.nvim_buf_get_name(args.buf)
        if fname == "" or vim.fn.filereadable(fname) == 0 or not vim.bo[args.buf].buflisted then
            return
        end
        fname = vim.fn.fnamemodify(fname, ":p")
        local rest = vim.tbl_filter(function(f) return f ~= fname end, vim.v.oldfiles)
        table.insert(rest, 1, fname)
        vim.v.oldfiles = rest
    end,
})

-- Highlight any buffer whose language already has a parser installed. This is the `main`-branch replacement for the old
-- `highlight.enable = true` module; unlike the retired `auto_install = true`, it won't fetch a parser on first use of a new
-- filetype, only highlight ones already present.
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft) or ft
        if vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf, lang)
        end
    end,
})

-- This function gets run when an LSP attaches to a particular buffer. That is to say, every time a new file is opened that is
-- associated with an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this function will be executed to
-- configure the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
    callback = function(event)
        -- Route the buffer's completion mechanism to mini's LSP function
        vim.bo[event.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'

        -- Helper function to set the mode, buffer and description for each of the following remaps.
        local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Jump to the definition of the word under your cursor. This is where a variable was first declared, or where a
        -- function is defined, etc. To jump back, press <C-t>.
        map("gd", fzf.lsp_definitions, "[G]oto [D]efinition")

        -- Find references for the word under your cursor.
        map("gr", fzf.lsp_references, "[G]oto [R]eferences")

        -- Jump to the implementation of the word under your cursor. Useful when your language has ways of declaring types
        -- without an actual implementation.
        map("gi", fzf.lsp_implementations, "[G]oto [I]mplementation")

        -- Jump to the type of the word under your cursor. Useful when you're not sure what type a variable is and you want to
        -- see the definition of its *type*, not where it was *defined*.
        map("<leader>D", fzf.lsp_typedefs, "Type [D]efinition")

        -- Fuzzy find all the symbols in your current document. Symbols are things like variables, functions, types, etc.
        map("<leader>ds", fzf.lsp_document_symbols, "[D]ocument [S]ymbols")

        -- Fuzzy find all the symbols in your current workspace. Similar to document symbols, except searches over your whole
        -- project.
        map("<leader>ws", fzf.lsp_live_workspace_symbols, "[W]orkspace [S]ymbols")

        -- Rename the variable under your cursor Most Language Servers support renaming across files, etc.
        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

        -- Opens a popup that displays documentation about the word under your cursor.
        map("K", vim.lsp.buf.hover, "Hover Documentation")

        -- WARN: This is not Goto Definition, this is Goto Declaration. For example, in C this would take you to the header
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        -- These used to come from lsp-zero.nvim's default_keymaps(); kept here directly now that the (dead upstream) plugin is
        -- gone.
        map("go", vim.lsp.buf.type_definition, "[G]oto type definition")
        map("gs", vim.lsp.buf.signature_help, "Show [S]ignature help")
        map("gl", vim.diagnostic.open_float, "Show diagnostic")

        -- vim.diagnostic.goto_prev()/goto_next() are deprecated in favor of jump(); on_jump replicates their old default of
        -- opening a floating diagnostic window at the cursor after moving (passing `float = true` to jump() still works, but
        -- just triggers another deprecation notice).
        local function openDiagnosticFloatOnJump(_, bufnr)
            vim.diagnostic.open_float({
                bufnr = bufnr, scope = "cursor", focus = false
            })
        end
        map("[d", function() vim.diagnostic.jump({ count = -1, on_jump = openDiagnosticFloatOnJump }) end, "Prev diagnostic")
        map("]d", function() vim.diagnostic.jump({ count = 1, on_jump = openDiagnosticFloatOnJump }) end, "Next diagnostic")

        -- The following two autocommands are used to highlight references of the word under your cursor when your cursor rests
        -- there for a little while. See `:help CursorHold` for information about when this is executed. When you move your
        -- cursor, the highlights will be cleared (the second autocommand).
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

        local codeActionMethod = vim.lsp.protocol.Methods.textDocument_codeAction
        if client:supports_method(codeActionMethod) then
            map("<leader>ca", function()
                fzf.lsp_code_actions({
                    winopts = {
                        preview = { horizontal = "up:80%" },
                    },
                })
            end, "Code actions")
        end
    end,
})


-------------------------------------------------------------------------------------------------------------------------------
-- Plugin setup
-------------------------------------------------------------------------------------------------------------------------------

require("auto-session").setup({
    log_level = "error",
})

fzf.setup({
    lsp = {
        code_actions = {
            previewer = "codeaction_native",
            preview_pager = "delta --side-by-side --width=$FZF_PREVIEW_COLUMNS --hunk-header-style='omit' --file-style='omit'",
        },
    },
    -- Sort files in a search; this prevents the returned files from being in an indeterminate order.
    files = {
        rg_opts = "--sort=path --color=always --files --hidden --follow",
    },
})

require("mason").setup()

local mini_indentscope = require("mini.indentscope")
mini_indentscope.setup({
    draw = {
        delay = 250,
        animation = mini_indentscope.gen_animation.quadratic({ easing = "in", duration = 100, unit = "total" }),
    },
    symbol = "┃",
})

require("mini.cursorword").setup()

require("mini.comment").setup()

local mini_keymap = require("mini.keymap")
local mini_keymap_multistep = mini_keymap.map_multistep
mini_keymap.setup()
mini_keymap_multistep("i", "<Tab>",   { "pmenu_next" })
mini_keymap_multistep("i", "<S-Tab>", { "pmenu_prev" })
mini_keymap_multistep("i", "<CR>",    { "pmenu_accept", "minipairs_cr" })
mini_keymap_multistep("i", "<BS>",    { "minipairs_bs" })

require("mini.icons").setup()

require("mini.pairs").setup()

require("mini.snippets").setup()

require("mini.surround").setup()

local mini_completion = require("mini.completion")
mini_completion.setup({
    scroll_down = "<C-n>",
    scroll_up = "<C-p>",
})

require("lualine").setup({
    extensions = { "fzf", "lazy", "mason", "oil" },
    options = {
        globalstatus = true,
    },
    sections = {
        lualine_b = { require("auto-session.lib").current_session_name },
        lualine_c = { { "filename", path = 1 } },
    },
})

require("scrollbar").setup()

require("stay-in-place").setup()

-- oil.nvim always joins columns with a single hardcoded space (oil/util.lua's render_table does table.concat(pieces, " ")) and
-- has no per-column padding option. To get more breathing room and per-column colors, wrap each built-in column: delegate to
-- its original render function, then pad the result with extra trailing spaces and tag it with its own highlight group.
-- Registering under the same name overrides the built-in column (oil/columns.lua checks its own registry before falling back
-- to the adapter's), so the "columns" list below doesn't need to change. Note: on Windows, oil never registers a "permissions"
-- column at all (oil/adapters/files.lua guards it behind `if not fs.is_windows`), so it always renders as the empty "-"
-- placeholder no matter what - that's not fixable from config, since there's no data to show.
vim.api.nvim_set_hl(0, "OilColumnSize", { fg = "#7e9cd8", default = true })
vim.api.nvim_set_hl(0, "OilColumnMtime", { fg = "#98bb6c", default = true })
vim.api.nvim_set_hl(0, "OilColumnPermissions", { fg = "#957fb8", default = true })

-- Single-key sort presets, layered on top of oil's default keymaps (use_default_keymaps stays true, so "gs" is still there for
-- anything not covered here). Lowercase = descending, uppercase = ascending.
local function oilSortKeymap(column, order)
    return {
        callback = function() require("oil").set_sort({ { column, order } }) end,
        mode = "n",
        desc = string.format("Sort by %s (%s)", column, order),
    }
end

require("oil").setup({
    default_file_explorer = true,
    columns = { "icon", "permissions", "mtime", "size" },
    constrain_cursor = "name",
    watch_for_changes = true,
    keymaps = {
        ["n"] = oilSortKeymap("name", "asc"),
        ["N"] = oilSortKeymap("name", "desc"),
        ["m"] = oilSortKeymap("mtime", "desc"),
        ["M"] = oilSortKeymap("mtime", "asc"),
        ["z"] = oilSortKeymap("size", "desc"),
        ["Z"] = oilSortKeymap("size", "asc"),
    },
    view_options = {
        show_hidden = true,
        case_insensitive = true,
    },
})

-- Column definitions aren't resolved until a buffer is actually rendered, so overriding them here (after setup, which is when
-- oil.config finishes initializing its internal adapter registry) still takes effect for every oil buffer.
local function oilPadColumn(name, extraSpaces, hlGroup)
    local oilColumns = require("oil.columns")
    local adapter = require("oil.config").get_adapter_by_scheme("oil://")
    local original = oilColumns.get_column(adapter, name)
    if not original then
        return
    end
    local padding = string.rep(" ", extraSpaces)
    oilColumns.register(name, vim.tbl_extend("force", original, {
        render = function(entry, conf, bufnr)
            local chunk = original.render(entry, conf, bufnr)
            -- oil.nvim reuses a single shared table (columns.EMPTY) for every "no data" cell across every render, so mutating
            -- chunk[1] in place here would permanently grow that shared constant a little more on every redraw instead of just
            -- padding this one cell.
            if type(chunk) == "table" then
                return { chunk[1] .. padding, chunk[2] }
            elseif chunk and chunk ~= "" then
                return { chunk .. padding, hlGroup }
            end
            return chunk
        end,
    }))
end

oilPadColumn("icon", 1, nil)
oilPadColumn("permissions", 2, "OilColumnPermissions")
oilPadColumn("mtime", 2, "OilColumnMtime")
oilPadColumn("size", 2, "OilColumnSize")

-- "vim"/"vimdoc" are included even though nothing edits vimscript directly: Neovim core bundles its own (older) parsers for
-- them, but nvim-treesitter's query files target a newer grammar revision, causing "invalid node type" errors wherever lua's
-- injections.scm embeds vim syntax (e.g. vim.cmd([[...]]) blocks). Installing them here overrides core's bundled parser with
-- one that actually matches the query.
require("nvim-treesitter").install({ "c", "cpp", "c_sharp", "java", "python", "lua", "vim", "vimdoc" })

require("nvim-ts-autotag").setup()

require("treesitter-context").setup({
    max_lines = 10,
})


-------------------------------------------------------------------------------------------------------------------------------
-- LSP setup
-------------------------------------------------------------------------------------------------------------------------------

-- C/C++
vim.lsp.config("clangd", { capabilities = mini_completion.get_lsp_capabilities() })
vim.lsp.enable({ "clangd" })

-- C#
vim.lsp.config("omnisharp", { capabilities = mini_completion.get_lsp_capabilities() })
vim.lsp.enable({ "omnisharp" })

-- Lua
vim.lsp.config("lua-language-server", { capabilities = mini_completion.get_lsp_capabilities() })
vim.lsp.enable({ "lua-language-server" })

-- Protocol Buffers
vim.lsp.config("buf", { capabilities = mini_completion.get_lsp_capabilities() })
vim.lsp.enable({ "buf" })

-- Python
vim.lsp.config("pyright", { capabilities = mini_completion.get_lsp_capabilities() })
vim.lsp.enable({ "pyright" })
