require("config.lazy")

vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 999
vim.o.wrap = false 

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = "*.lang",
    callback = function()
        vim.bo.filetype = "odin"
    end,
})
