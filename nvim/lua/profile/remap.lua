vim.g.mapleader = " "

-- Jump to netrw in the directory associated with the current buffer.
vim.keymap.set("n", "<leader>v", vim.cmd.Ex)

-- Toggle Undotree.
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Change the default behavior of pasting in visual mode; anything selected will
-- be deleted, with the contents sent to the black hole register, then the
-- unnamed register contents will be pasted. This preserves the contents of the
-- unnamed register after the paste, which frankly is the behavior I expect not
-- coming from Vim. I don't ever find myself wanting to effectively paste and
-- yank something in the same operation.
vim.keymap.set("v", "p", "\"_dP")

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
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- Need a way to get back indentation on a line with whitespace cleared; deleted
-- contents should go to the black hole register as to not override anything.
vim.keymap.set("n", "<leader>i", "\"_ddO")

-- Insert matching braces.
vim.keymap.set("i", "{<CR>", "{<CR>}<Esc>O")
vim.keymap.set("i", "(<CR>", "(<CR>)<Esc>O")
vim.keymap.set("i", "[<CR>", "[<CR>]<Esc>O")

local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>ff", fzf.files, {})            -- "find files"
vim.keymap.set("n", "<leader>gg", fzf.grep, {})             -- "grep global"
vim.keymap.set("n", "<leader>gb", fzf.lgrep_curbuf, {})     -- "grep buffer"
vim.keymap.set("n", "<leader>gl", fzf.grep_last, {})        -- "grep last"
vim.keymap.set("n", "<leader>gw", fzf.grep_cword, {})       -- "grep word"
vim.keymap.set("n", "<leader>gW", fzf.grep_cWORD, {})       -- "grep WORD"
vim.keymap.set("v", "<leader>gv", fzf.grep_visual, {})      -- "grep visual"
vim.keymap.set("n", "<leader>fh", fzf.oldfiles, {})         -- "file history"
vim.keymap.set("n", "<leader>fb", fzf.buffers, {})          -- "file buffers"
vim.keymap.set("n", "<leader>ss", fzf.spell_suggest, {})    -- "spell suggest"

-- This is because I'm lazy - it selects all lines in the current buffer.
vim.keymap.set("n", "<C-a>", "ggVGzz")

-- With search highlighting enabled (which it is by default) normally the terms
-- will remain highlighted until the next search is done or by pressing Ctrl +
-- l. This remap means anytime escape is hit it will clear the highlights, which
-- feels more intuitive to me.
vim.keymap.set("n", "<Esc>", function() vim.cmd("noh") end)

-- I find I accidentally hit F1 a lot when going to hit escape which brings up
-- help info so disable it.
vim.keymap.set("i", "<F1>", "<Esc>")
vim.keymap.set("n", "<F1>", "<Esc>")
vim.keymap.set("v", "<F1>", "<Esc>")

-- These seem to jump up or down to the start or end of the scrolloff
-- respectively. I don't ever use it and I find myself accidentally hitting
-- shift pretty often and it screws me up so just remap these to 'h' and 'l'.
vim.keymap.set("n", "H", "h")
vim.keymap.set("n", "L", "l")
