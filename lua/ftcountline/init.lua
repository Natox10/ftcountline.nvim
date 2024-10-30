-- lua/line_counter/init.lua
local M = {}

-- Fonction pour compter les lignes d'une fonction
local function count_function_lines(bufnr, start_line, end_line)
	local count = end_line - start_line + 1
	return count
end

-- Fonction pour trouver les fonctions C dans le buffer
local function find_c_functions(bufnr)
	local functions = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local in_function = false
	local start_line = 0
	local brace_count = 0

	for i, line in ipairs(lines) do
		-- Détecte le début d'une fonction
		if not in_function and line:match("^%s*%w+%s+%w+%s*%(.*%)%s*$") then
			in_function = true
			start_line = i
		end

		-- Compte les accolades
		if in_function then
			brace_count = brace_count + select(2, line:gsub("{", ""))
			brace_count = brace_count - select(2, line:gsub("}", ""))

			-- Fin de la fonction
			if brace_count == 0 and line:match("}") then
				table.insert(functions, {
					start_line = start_line,
					end_line = i,
				})
				in_function = false
			end
		end
	end
	return functions
end

-- Affiche le nombre de lignes avec des extmarks
function M.display_line_counts()
	local bufnr = vim.api.nvim_get_current_buf()
	local namespace = vim.api.nvim_create_namespace("line_counter")
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

	local functions = find_c_functions(bufnr)
	for _, func in ipairs(functions) do
		local count = count_function_lines(bufnr, func.start_line, func.end_line)
		local text = string.format("Lignes: %d", count)

		-- Crée un extmark après la fonction
		vim.api.nvim_buf_set_extmark(bufnr, namespace, func.end_line, 0, {
			virt_text = { { text, "Comment" } },
			virt_text_pos = "eol",
		})
	end
end

-- Configuration du plugin
function M.setup()
	-- Crée une commande pour actualiser le comptage
	vim.api.nvim_create_user_command("CountLines", M.display_line_counts, {})

	-- Actualise automatiquement lors de la sauvegarde
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = { "*.c" },
		callback = M.display_line_counts,
	})
end

return M
