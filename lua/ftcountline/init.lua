local M = {}

local function is_function_declaration(line)
	-- Détecte une déclaration de fonction C
	-- Gère: type_retour nom_fonction(params)
	return line:match("^%s*[%w_*]+%s+[%w_]+%s*%(.*%)%s*$")
		and not line:match("^%s*typedef%s+")
		and not line:match("^%s*extern%s+")
		and not line:match("^%s*static%s+inline%s+")
end

local function is_comment(line)
	return line:match("^%s*//") or line:match("^%s*/%*") or line:match("^%s*%*")
end

local function is_empty_line(line)
	return line:match("^%s*$")
end

local function find_c_functions(bufnr)
	local functions = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local in_function = false
	local start_line = 0
	local brace_count = 0
	local in_multiline_comment = false
	local potential_declaration = false
	local declaration_line = 0

	for i, line in ipairs(lines) do
		-- Gestion des commentaires multi-lignes
		if line:match("/%*") then
			in_multiline_comment = true
		end
		if line:match("%*/") then
			in_multiline_comment = false
		end

		if not in_multiline_comment then
			-- Détection de déclaration de fonction
			if not in_function then
				if is_function_declaration(line) then
					potential_declaration = true
					declaration_line = i
				end

				if potential_declaration and line:match("{") then
					in_function = true
					start_line = declaration_line
					brace_count = 1
					potential_declaration = false
				end
			else
				-- Comptage des accolades dans le corps de la fonction
				brace_count = brace_count + select(2, line:gsub("{", ""))
				brace_count = brace_count - select(2, line:gsub("}", ""))

				if brace_count == 0 then
					-- Calcul du nombre de lignes en excluant les lignes vides et commentaires
					local real_start = start_line
					local real_end = i
					local actual_lines = 0

					for j = start_line, i do
						local line_content = lines[j]
						if not is_empty_line(line_content) and not is_comment(line_content) then
							actual_lines = actual_lines + 1
						end
					end

					table.insert(functions, {
						start_line = start_line,
						end_line = i,
						line_count = actual_lines,
					})
					in_function = false
				end
			end
		end
	end
	return functions
end

function M.display_line_counts()
	local bufnr = vim.api.nvim_get_current_buf()
	local namespace = vim.api.nvim_create_namespace("ftcountline")
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

	local functions = find_c_functions(bufnr)
	for _, func in ipairs(functions) do
		local text = string.format("Lignes: %d", func.line_count)

		vim.api.nvim_buf_set_extmark(bufnr, namespace, func.end_line, 0, {
			virt_text = { { text, "Comment" } },
			virt_text_pos = "eol",
		})
	end
end

function M.setup(opts)
	opts = opts or {}

	vim.api.nvim_create_user_command("CountLines", M.display_line_counts, {})

	if opts.auto_update ~= false then
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			pattern = { "*.c" },
			callback = M.display_line_counts,
		})
	end
end

return M
