return {
	'neoclide/coc.nvim',
	'ollykel/v-vim',
	'neovim/nvim-lspconfig',
	{
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
}
}
