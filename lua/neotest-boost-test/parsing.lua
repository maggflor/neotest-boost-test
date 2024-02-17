local lib = require("neotest.lib")
local utils = require("neotest-boost-test.utils")

local M = {}

--- Analyzes the path to determine whether the file is a C++ test file or not.
---@async
---@param file_path string the path to analyze
---@return boolean true if `path` is a test file, false otherwise.
function M.is_test_file(file_path)
	local path_elements = vim.split(file_path, lib.files.sep, { plain = true })
	local filename = path_elements[#path_elements]
	if filename == "" then -- directory
		return false
	end

	local valid_extensions = {
		["cpp"] = true,
		["cppm"] = true,
		["cc"] = true,
		["cxx"] = true,
		["c++"] = true,
	}
	local filename_elements = vim.split(filename, ".", { plain = true })
	local extension = filename_elements[#filename_elements]
	if not valid_extensions[extension] then
		return false
	end
	return true
end

---Filter directories when searching for test files
---@async
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function M.filter_dir(rel_path, root)
	-- TODO: Make feature optional
	if M.current_file ~= nil then
		local absolute_path = utils.concat_paths(root, rel_path)
		local is_part_of_current_path = string.find(M.current_file, absolute_path)
		if not is_part_of_current_path then
			return false
		end
	end
	if string.find(rel_path, "test") or string.find(rel_path, "Test") then
		return true
	end
	if
		string.find(rel_path, "/lib")
		or string.find(rel_path, "/src")
		or string.find(rel_path, "/doc")
		or string.find(rel_path, "/include")
	then
		return false
	end
	return true
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function M.discover_positions(file_path)
	local query = [[
        ;; TODO: test suites
        ;; test cases
        (function_definition
            declarator: (function_declarator
                ;; TODO: Match also fixture test cases
                ;; TODO: Match also data test cases
                declarator: (identifier) @function_name (#eq? @function_name "BOOST_AUTO_TEST_CASE")
                parameters: (parameter_list
                    (parameter_declaration
                        type: (type_identifier) @test.name)))
        ) @test.definition
    ]]

	return lib.treesitter.parse_positions(file_path, query)
end

return M
