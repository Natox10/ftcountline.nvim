local M = {}

local function count_lines_in_function(lines, start_index, end_index)
	-- Compte toutes les lignes entre les accolades inclusivement
	return end_index - start_index - 1
end

local function find_function_end(lines, start_index)
	local brace_count = 0
	local found_opening = false

	for i = start_index, #lines do
		local line = lines[i]

		-- Compte les accolades
		local opening = select(2, line:gsub("{", ""))
		local closing = select(2, line:gsub("}", ""))

		if opening > 0 then
			found_opening = true
		end

		if found_opening then
			brace_count = brace_count + opening - closing
			if brace_count == 0 then
				return i
			end
		end
	end
	return nil
end

local function find_c_functions(bufnr)
	local functions = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local i = 1
	while i <= #lines do
		local line = lines[i]
		-- Recherche les dÃ©clarations de fonction
		if line:match("^[%s*]*[%w_]+%s+[%w_]+%s*%(.*%)%s*$") then
			local start_line = i
			local brace_line = i

			-- Cherche l'accolade ouvrante
			while brace_line <= #lines and not lines[brace_line]:match("{") do
				brace_line = brace_line + 1
			end

			if brace_line <= #lines then
				local end_line = find_function_end(lines, brace_line)
				if end_line then
					-- Le comptage inclut les accolades et toutes les lignes entre elles
					local count = count_lines_in_function(lines, brace_line, end_line)
					table.insert(functions, {
						start_line = start_line - 1,
						end_line = end_line - 1,
						line_count = count,
					})
					i = end_line
				end
			end
		end
		i = i + 1
	end
	return functions
end

function M.display_line_counts()
	local bufnr = vim.api.nvim_get_current_buf()
	local namespace = vim.api.nvim_create_namespace("ftcountline")
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

	local functions = find_c_functions(bufnr)
	for _, func in ipairs(functions) do
		vim.api.nvim_buf_set_extmark(bufnr, namespace, func.end_line, 0, {
			virt_text = { { string.format("Lignes: %d", func.line_count), "Comment" } },
			virt_text_pos = "eol",
		})
	end
end

function M.setup(opts)
	opts = opts or {}

	-- Commande pour actualisation manuelle
	vim.api.nvim_create_user_command("CountLines", M.display_line_counts, {})

	-- Actualisation automatique lors de la modification du texte
	vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
		pattern = { "*.c", "*.h" },
		callback = M.display_line_counts,
	})

	-- Affichage initial lors de l'ouverture d'un fichier
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = { "*.c", "*.h" },
		callback = M.display_line_counts,
	})
end

return M
