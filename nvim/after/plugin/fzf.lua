local fzflua = require("fzf-lua")
fzflua.setup({
    lsp = {
        code_actions = {
            previewer = "codeaction_native",
            preview_pager = "delta --side-by-side --width=$FZF_PREVIEW_COLUMNS --hunk-header-style='omit' --file-style='omit'",
        },
    },
    -- Sort files in a search; this prevents the returned files from being in a indeterminate order.
    files = {
        rg_opts = "--sort=path --color=always --files --hidden --follow",
    },
    -- grep = {
    --     rg_opts = "--sort=path --color=always --hidden --follow --line-number --column --multiline",
    -- },
})
