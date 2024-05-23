return {
	{ "ellisonleao/gruvbox.nvim", priority = 1000 , config = true, opts = ...},
	'ollykel/v-vim',
	'nvim-tree/nvim-tree.lua',
	'nvim-tree/nvim-web-devicons',
	{
		'neoclide/coc.nvim',
		branch = "release"
	},--'marcosantos98/clang-format.nvim',
	{
		dir = "~/dev/open/clang-format.nvim",
	},
	{
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },
}
