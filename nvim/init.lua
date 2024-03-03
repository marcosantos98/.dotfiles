vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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

require("lazy").setup("plugins")
require("nvim-tree").setup()
require("clang-format").setup({
	clangFormatPath = "/home/marco/.clang-format"
}
)

vim.g.v_autofmt_bufwritepre = true
vim.wo.number = true
vim.opt.sw = 4
vim.opt.ts = 4
