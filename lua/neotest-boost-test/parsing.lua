local lib = require("neotest.lib")

local M = {}

--- Analyzes the path to determine whether the file is a C++ test file or not.
---@async
--- @param file_path string the path to analyze
--- @return boolean true if `path` is a test file, false otherwise.
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
---@return boolean
---@diagnostic disable-next-line: unused-local
function M.filter_dir(rel_path)
	if string.find(rel_path, "test") or string.find(rel_path, "Test") then
		return true
	end
	return false
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
