local M = {}

function M.toggle_type_warning()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	-- Get diagnostics for current line
	local diagnostics = vim.diagnostic.get(bufnr, { lnum = line_num - 1 })

	if #diagnostics == 0 then
		print("No diagnostics on current line")
		return
	end

	-- Get the current line content
	local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]

	-- Check if comment already exists
	if line:match("#%s*noqa") or line:match("#%s*ty:%s*ignore") then
		print("Line already has ignore comment")
		return
	end

	-- Collect error codes by source
	local ruff_codes = {}
	local ty_codes = {}

	for _, diagnostic in ipairs(diagnostics) do
		local source = diagnostic.source
		local code = diagnostic.code

		if source == "Ruff" and code then
			table.insert(ruff_codes, code)
		elseif source == "ty" and code then
			table.insert(ty_codes, code)
		end
	end

	-- Build comment string
	local comment_parts = {}

	if #ruff_codes > 0 then
		table.insert(comment_parts, "# noqa: " .. table.concat(ruff_codes, ", "))
	end

	if #ty_codes > 0 then
		table.insert(comment_parts, "# ty: ignore[" .. table.concat(ty_codes, ", ") .. "]")
	end

	if #comment_parts == 0 then
		print("No ruff or ty diagnostics found")
		return
	end

	-- Append to line
	local new_line = line .. "  " .. table.concat(comment_parts, "  ")
	vim.api.nvim_buf_set_lines(bufnr, line_num - 1, line_num, false, { new_line })

	print("Added: " .. table.concat(comment_parts, "  "))
end

function M.print_diagnostics()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	local diagnostics = vim.diagnostic.get(bufnr, { lnum = line_num - 1 })

	if #diagnostics == 0 then
		print("No diagnostics on current line")
		return
	end

	for i, d in ipairs(diagnostics) do
		print("Diagnostic " .. i .. ":")
		vim.print(d)
	end
end

function M.open_diagnostic_url()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	local diagnostics = vim.diagnostic.get(bufnr, { lnum = line_num - 1 })

	if #diagnostics == 0 then
		print("No diagnostics on current line")
		return
	end

	-- Try to find a URL in the diagnostics
	for _, d in ipairs(diagnostics) do
		local url = nil

		-- Check for codeDescription.href in user_data.lsp
		if d.user_data and d.user_data.lsp and d.user_data.lsp.codeDescription then
			url = d.user_data.lsp.codeDescription.href
		end

		if url then
			vim.ui.open(url)
			print("Opening: " .. url)
			return
		end
	end

	print("No URL found in diagnostics")
end

function M.setup(opts)
	opts = opts or {}

	if opts.keybinding then
		vim.keymap.set("n", opts.keybinding, M.toggle_type_warning, {
			desc = "Add ignore comment for diagnostic",
			silent = true,
		})
	end

	if opts.print_keybinding then
		vim.keymap.set("n", opts.print_keybinding, M.print_diagnostics, {
			desc = "Print diagnostic info",
			silent = true,
		})
	end

	if opts.url_keybinding then
		vim.keymap.set("n", opts.url_keybinding, M.open_diagnostic_url, {
			desc = "Open diagnostic URL",
			silent = true,
		})
	end
end

return M
