require("auto-save").setup({
    debounce_delay = 300,
    condition = function(buf)
        if vim.bo[buf].buftype ~= "" then return false end
        if vim.fn.expand("%:p") == "" then return false end
        return true
    end,
})
