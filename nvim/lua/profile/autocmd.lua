vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    callback = function()
        -- Save the current cursor position.
        local save_cursor = vim.fn.getpos(".")
        -- Remove trailing whitespace.
        pcall(function() vim.cmd [[%s/\s\+$//e]] end)
        -- Convert tabs to spaces (width of 4).
        pcall(function() vim.cmd [[%s/\t/    /eg]] end)
        -- Restore the original cursor position; otherwise the cursor gets reset
        -- to the beginning of the current line.
        vim.fn.setpos(".", save_cursor)
    end,
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = { "*" },
    callback = function()
        -- Run check.py on the current buffer.
        pcall(function()
            if (string.find(vim.fn.getcwd(), "C:\\working\\systems\\cobra", 0)) then
                local file = vim.api.nvim_buf_get_name(0)
                local result = vim.fn.system(string.format([[check.py -q %s]], file))
                print(result)
            end
        end)
    end,
})
