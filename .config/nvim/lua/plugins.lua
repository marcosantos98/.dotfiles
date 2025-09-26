-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
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
    --{ 'projekt0n/github-nvim-theme', config = function() 
    --        require('github-theme').setup({
    --    	options = {
    --    	    transparent = true,
    --    	}
    --        })    
    --        vim.cmd.colorscheme "github_light" 
    --    end 
    --},
    { "marcosantos98/clang-format.nvim", config = function()
	require('clang-format').setup({
	    clangFormatPath = "/home/marco/.clang-format",
	})
	end
    },
    { "ellisonleao/gruvbox.nvim", config = function() 
	 require('gruvbox').setup({
	     transparent_mode = true
	 })
	 vim.cmd.colorscheme "gruvbox" end },
    --{ "folke/tokyonight.nvim", config = function() vim.cmd.colorscheme "tokyonight" end },
    { "echasnovski/mini.nvim", 
    	config = function()
	    local statusline = require 'mini.statusline'
	    statusline.setup { use_icons = true }
	end
    },
    { "nvim-treesitter/nvim-treesitter", 
	build = ":TSUpdate",
	config = function()
	    require'nvim-treesitter.configs'.setup {
	      ensure_installed = { "rust", "odin", "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
	      auto_install = false,
	      highlight = {
	        enable = true,
	    
	        disable = function(lang, buf)
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
            "hrsh7th/cmp-nvim-lsp",  -- LSP source for nvim-cmp
            "hrsh7th/cmp-buffer",    -- Buffer completions
            "hrsh7th/cmp-path",      -- Path completions
            "saadparwaiz1/cmp_luasnip", -- Snippet completions
            "L3MON4D3/LuaSnip",      -- Snippet engine
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

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
                    { name = "buffer" },  -- Buffer completions
                    { name = "path" },    -- Path completions
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

	    local caps = require('cmp_nvim_lsp').default_capabilities()
	    require'lspconfig'.ols.setup{ capabilites = caps}
	    require'lspconfig'.rust_analyzer.setup({
		capabilites = caps,
		settings = {
		    ['rust-analyzer'] = {
		        checkOnSave = { command = 'clippy' },
		        cargo = { allFeatures = true },
		    },
		},
	    })
	    require'lspconfig'.clangd.setup{capabilites = caps}

	    vim.api.nvim_create_autocmd('LspAttach', {
		callback = function(args)
		    local client = vim.lsp.get_client_by_id(args.data.client_id)
		    if not client then return end

		    if client.supports_method('textDocument/formatting') then
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
    }
  },
})
