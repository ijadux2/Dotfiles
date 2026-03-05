return {
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		opts = {
			default_file_explorer = true,
			columns = {
				"icon",
				"permissions",
				"size",
				"mtime",
			},
			view_options = {
				show_hidden = false,
				natural_order = true,
			},
			use_default_keymaps = true,
			cleanup_delay_ms = 2500,
			confirm = {
				trash = true,
				remove = true,
			},
			trash = {
				allow_trash_on_modified_buffer = true,
			},
		},
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
	},
}
