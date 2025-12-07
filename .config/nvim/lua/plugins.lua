-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out,                            "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		{
			"ej-shafran/compile-mode.nvim",
			version = "^5.0.0",
			-- you can just use the latest version:
			-- branch = "latest",
			-- or the most up-to-date updates:
			-- branch = "nightly",
			dependencies = {
				"nvim-lua/plenary.nvim",
				-- if you want to enable coloring of ANSI escape codes in
				-- compilation output, add:
				-- { "m00qek/baleia.nvim", tag = "v1.3.0" },
			},
			config = function()
				---@type CompileModeOpts
				vim.g.compile_mode = {
					-- if you use something like `nvim-cmp` or `blink.cmp` for completion,
					-- set this to fix tab completion in command mode:
					-- input_word_completion = true,

					-- to add ANSI escape code support, add:
					-- baleia_setup = true,

					-- to make `:Compile` replace special characters (e.g. `%`) in
					-- the command (and behave more like `:!`), add:
					-- bang_expansion = true,
				}
			end
		},
		{
			"zaldih/themery.nvim",
			lazy = false,
			config = function()
				require("themery").setup({
					themes = {
						"gruvbox",
						"github_dark",
						"tokyonight",
						"rose-pine",
						"github-monochrome-dark",
						"github-monochrome-rosepine",
						"github-monochrome-tokyonight",
					},
					livePreview = true,
				})
			end
		},
		{
			"marcosantos98/clang-format.nvim",
			config = function()
				require('clang-format').setup({
					clangFormatPath = "/home/marco/.clang-format",
				})
			end
		},
		{
			"ellisonleao/gruvbox.nvim",
			config = function()
				require('gruvbox').setup({
					transparent_mode = true
				})
				vim.cmd.colorscheme "gruvbox"
			end
		},
		{
			"echasnovski/mini.nvim",
			config = function()
				local statusline = require 'mini.statusline'
				statusline.setup { use_icons = true }
			end
		},
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			config = function()
				require 'nvim-treesitter.configs'.setup {
					ensure_installed = { "rust", "odin", "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
					auto_install = false,
					highlight = {
						enable = true,

						disable = function(_, buf)
							local max_filesize = 100 * 1024 -- 100 KB
							local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
							if ok and stats and stats.size > max_filesize then
								return true
							end
						end,
						additional_vim_regex_highlighting = false,
					},
				}
			end
		},
		{
			"hrsh7th/nvim-cmp",
			dependencies = {
				"hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
				"hrsh7th/cmp-buffer", -- Buffer completions
				"hrsh7th/cmp-path", -- Path completions
				"saadparwaiz1/cmp_luasnip", -- Snippet completions
				"L3MON4D3/LuaSnip", -- Snippet engine
			},
			config = function()
				local cmp = require("cmp")

				cmp.setup({
					snippet = {
						expand = function(args)
							require("luasnip").lsp_expand(args.body)
						end,
					},
					mapping = cmp.mapping.preset.insert({
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),
						["<C-Space>"] = cmp.mapping.complete(),
						["<C-e>"] = cmp.mapping.abort(),
						["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept selected item
					}),
					sources = cmp.config.sources({
						{ name = "nvim_lsp" }, -- LSP completions
						{ name = "luasnip" }, -- Snippet completions
					}, {
						{ name = "buffer" }, -- Buffer completions
						{ name = "path" }, -- Path completions
					}),
				})
			end,
		},
		{
			"neovim/nvim-lspconfig",
			dependencies = { "hrsh7th/nvim-cmp" },
			config = function()
				vim.keymap.set('n', 'gd', vim.lsp.buf.definition);
				vim.keymap.set('n', 'gr', vim.lsp.buf.references);
				vim.keymap.set('n', 'gi', vim.lsp.buf.implementation);

				vim.lsp.config('*', {})

				vim.lsp.config("lua_ls", {
					settings = {
						Lua = {
							diagnostics = {
								globals = {
									"vim"
								}
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false, -- Important to avoid annoying prompts
							},
							telemetry = { enable = false },
						}
					}
				})

				vim.lsp.enable({
					"zls",
					"ols",
					"rust_analyzer",
					"clangd",
					"lua_ls",
				})

				vim.api.nvim_create_autocmd('LspAttach', {
					callback = function(args)
						local client = vim.lsp.get_client_by_id(args.data.client_id)
						if not client then return end

						if client.supports_method("textDocument/formatting") then
							vim.api.nvim_create_autocmd('BufWritePre', {
								buffer = args.buf,
								callback = function()
									vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
								end
							})
						end
					end
				})
			end
		},
		{
			"nvim-telescope/telescope.nvim",
			dependencies = {
				"nvim-lua/plenary.nvim"
			},
			config = function()
				vim.keymap.set("n", "<space>f", require('telescope.builtin').find_files)
				vim.keymap.set("n", "<space>d", require('telescope.builtin').diagnostics)
				vim.keymap.set("n", "<space>g", require('telescope.builtin').live_grep)
				vim.keymap.set("n", "<space>l", require('lazygit').lazygit)
				vim.keymap.set("n", "<space>en", function()
					require('telescope.builtin').find_files {
						cwd = vim.fn.stdpath("config")
					}
				end)
			end
		},
		{
			"simrat39/rust-tools.nvim"
		},
		{
			'stevearc/oil.nvim',
			opts = {},
			dependencies = { { "echasnovski/mini.icons", opts = {} } },
			-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
			lazy = false,
		},
		{
			enabled = false,
			'github/copilot.vim',
		},
		{
			'MeanderingProgrammer/render-markdown.nvim',
			dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
			opts = {},
		},
		{
			"kdheepak/lazygit.nvim",
			lazy = true,
			cmd = {
				"LazyGit",
				"LazyGitConfig",
				"LazyGitCurrentFile",
				"LazyGitFilter",
				"LazyGitFilterCurrentFile",
			},
			dependencies = {
				"nvim-lua/plenary.nvim",
			},
			keys = {
				{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
			}
		},
		-- :theme
		{
			"idr4n/github-monochrome.nvim",
			lazy = false,
			priority = 1000,
			opts = {},
		},
		{
			'projekt0n/github-nvim-theme',
			config = function()
				require('github-theme').setup({
					options = {
						transparent = true,
					}
				})
				vim.cmd.colorscheme "github_dark"
			end
		},
		{
			"folke/tokyonight.nvim",
			config = function()
				vim.cmd.colorscheme "tokyonight"
			end
		},
		{
			"rose-pine/neovim",
			name = "rose-pine",
			config = function()
				vim.cmd("colorscheme rose-pine")
			end
		},
	},
})
