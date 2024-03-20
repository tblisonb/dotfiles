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

-- Re-center cursor when jumping up/down a half page.
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")

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

-- Insert matching braces.
vim.keymap.set("i", "{<CR>", "{<CR>}<Esc>O")
vim.keymap.set("i", "(<CR>", "(<CR>)<Esc>O")
vim.keymap.set("i", "[<CR>", "[<CR>]<Esc>O")
