vim.cmd.colorscheme("kanagawa")
vim.opt.colorcolumn = { '80', '127' }
vim.o.termguicolors = true
vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.diagnostic.config({ virtual_text = false, virtual_lines = { current_line = true },})

vim.opt.scrolloff = 10
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.cindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.listchars= { eol = "↵" , tab = "→ " , nbsp = "␣", trail = "•",
                     extends = "⟩", precedes = "⟨"  }

vim.opt.list = true
vim.opt.textwidth = 127
vim.opt.wrap = false

vim.opt.spelllang = 'en_us'
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
vim.lsp.set_log_level("off")

if vim.loop.os_uname().sysname == "Windows_NT" then
    -- Idk how this worked before nvim 0.10 but undotree can't find default 'diff'
    -- command so we have to specify on Windows.
    vim.g.undotree_DiffCommand = "FC"

    local user_profile = vim.fn.getenv 'USERPROFILE'
    vim.g.python3_host_prog = user_profile .. '/.pyenv/pyenv-win/versions/3.8.10/python.exe'
end
