require("lualine").setup({
    sections = {
        lualine_c = {
            {
                'filename',
                path = 1,   -- 0: Just the filename
                            -- 1: Relative path
                            -- 2: Absolute path
                            -- 3: Absolute path, with tilde as the home directory
                            -- 4: Filename and parent dir, with tilde as the home directory
            }
        }
    }
})
