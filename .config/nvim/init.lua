require("plugins")

vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 999
vim.o.wrap = false

vim.o.updatetime = 250

vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, {
			focusable = false,
			close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
			scope = "cursor",
			source = "always",
			prefix = "",
			border = "rounded",
		})
	end,
})

vim.keymap.set("v", "<C-S-C>", '"+y', { noremap = true, silent = true })
vim.cmd.colorscheme("github-monochrome-dark")
