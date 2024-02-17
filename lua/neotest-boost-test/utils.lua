local lib = require("neotest.lib")

local M = {}

---@param line string a line of text that can be split into words
---@param search_word string word to look for
---@return string | nil word after the given word if found
function M.find_word_after(line, search_word)
	local words = vim.split(line, " ", { plain = true })
	for i_word, word in pairs(words) do
		if word == search_word and i_word < #words then
			return words[i_word + 1]
		end
	end
	return nil
end

---@param file_path string path to file including file name
---@return string path to file without file name
function M.remove_file_name_from_path(file_path)
	local path_elements = vim.split(file_path, lib.files.sep, { plain = true })
	table.remove(path_elements, #path_elements)
	return table.concat(path_elements, lib.files.sep)
end

---@param left_path string left part of the path
---@param right_path string right part of the path
---@return string concatenated path without duplicated separators
function M.concat_paths(left_path, right_path)
	if left_path:sub(#left_path) == lib.files.sep then
		left_path = left_path:sub(1, #left_path - 1)
	end
	if right_path:sub(1, 1) == lib.files.sep then
		right_path = right_path:sub(2)
	end
	return left_path .. lib.files.sep .. right_path
end

return M
