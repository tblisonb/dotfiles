local fzf = require('fzf-lua')
vim.keymap.set('n', '<leader>pf', fzf.files, {})
vim.keymap.set('n', '<leader>ph', fzf.oldfiles, {})
vim.keymap.set('n', '<leader>pg', fzf.grep, {})
