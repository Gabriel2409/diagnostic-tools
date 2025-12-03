local M = {}

-- Default configuration
M.config = {
	sources = {
		Ruff = {
			format = "# noqa: %s",
			url_path = "user_data.lsp.codeDescription.href",
		},
		ty = {
			format = "# ty: ignore[%s]",
			url_path = "user_data.lsp.codeDescription.href",
		},
	},
}

-- Helper to get nested field from a dot-separated path
local function get_nested_field(obj, path)
	local keys = vim.split(path, ".", { plain = true })
	local current = obj

	for _, key in ipairs(keys) do
		if current == nil then
			return nil
		end
		current = current[key]
	end

	return current
end

-- Debug diagnostic: pretty print all diagnostics on current line
function M.debug_diagnostic()
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

-- Suppress diagnostic: add ignore comment based on configured sources
function M.suppress_diagnostic()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	local diagnostics = vim.diagnostic.get(bufnr, { lnum = line_num - 1 })

	if #diagnostics == 0 then
		print("No diagnostics on current line")
		return
	end

	local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]

	-- Check if comment already exists
	if line:match("#%s*noqa") or line:match("#%s*ty:%s*ignore") then
		print("Line already has ignore comment")
		return
	end

	-- Collect codes by source
	local codes_by_source = {}

	for _, diagnostic in ipairs(diagnostics) do
		local source = diagnostic.source
		local code = diagnostic.code

		if source and code and M.config.sources[source] then
			if not codes_by_source[source] then
				codes_by_source[source] = {}
			end
			table.insert(codes_by_source[source], code)
		end
	end

	if vim.tbl_count(codes_by_source) == 0 then
		print("No configured diagnostics found")
		return
	end

	-- Build comment string
	local comment_parts = {}

	for source, codes in pairs(codes_by_source) do
		local format = M.config.sources[source].format
		local codes_str = table.concat(codes, ", ")
		local comment = format:format(codes_str)
		table.insert(comment_parts, comment)
	end

	local new_line = line .. "  " .. table.concat(comment_parts, "  ")
	vim.api.nvim_buf_set_lines(bufnr, line_num - 1, line_num, false, { new_line })

	print("Added: " .. table.concat(comment_parts, "  "))
end

-- Open diagnostic docs: open URL from configured path
function M.open_diagnostic_docs()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	local diagnostics = vim.diagnostic.get(bufnr, { lnum = line_num - 1 })

	if #diagnostics == 0 then
		print("No diagnostics on current line")
		return
	end

	for _, d in ipairs(diagnostics) do
		local source = d.source

		if source and M.config.sources[source] then
			local url_path = M.config.sources[source].url_path
			local url = get_nested_field(d, url_path)

			if url then
				vim.ui.open(url)
				print("Opening: " .. url)
				return
			end
		end
	end

	print("No URL found in configured diagnostics")
end

function M.setup(opts)
	opts = opts or {}

	-- Merge user config with defaults
	if opts.sources then
		M.config.sources = opts.sources
	end
end

return M
