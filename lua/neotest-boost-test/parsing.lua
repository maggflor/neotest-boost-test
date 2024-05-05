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
	local success, current_file = pcall(function()
		return require("nio").api.nvim_buf_get_name(0)
	end)

	if success then
		local absolute_path = utils.concat_paths(root, rel_path)
		local is_part_of_current_path = string.find(current_file, absolute_path)
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
		;;(expression_statement
		;;	(call_expression
		;;		function: (identifier) @suite_name (#eq? @suite_name "BOOST_FIXTURE_TEST_SUITE")
		;;		arguments: (argument_list
		;;			(identifier) @namespace.name))
		;;) @namespace.definition

		;; auto, fixture and data test cases
		(function_definition
			declarator: (function_declarator
				declarator: (identifier) @function_name (#match? @function_name "BOOST_[A-Z]+_TEST_CASE")
				parameters: (parameter_list
					(parameter_declaration
						type: (type_identifier) @test.name
					)
				)
			)
			.
			body: (compound_statement) @test.definition
		)

		;; BOOST_DATA_TEST_CASE_F
		(
			(expression_statement
				(call_expression
					function: (identifier) @function_name (#eq? @function_name "BOOST_DATA_TEST_CASE_F")
					arguments: (argument_list
						(identifier)
						.
						(identifier) @test.name
					)
				)
			)
			.
			(compound_statement) @test.definition
		)
	]]

	---@diagnostic disable-next-line: missing-parameter
	return lib.treesitter.parse_positions(file_path, query)
end

---@diagnostic disable-next-line: unused-function, unused-local
local function test_treesitter_query()
	local bufnr = 8

	local language_tree = vim.treesitter.get_parser(bufnr, "cpp")
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()

	print(vim.inspect(vim.treesitter.query.list_directives()))
	local query = vim.treesitter.query.parse(
		"cpp",
		[[
			(
				(comment) @_start
					.
				(expression_statement
					(call_expression
						function: (identifier) @_suite_name (#eq? @_suite_name "BOOST_FIXTURE_TEST_SUITE")
						arguments: (argument_list
							(identifier) @namespace.name))
				) @_end
				;;_*
				;;(expression_statement
				;;	(call_expression
				;;		function: (identifier) @suite_name (#eq? @suite_name "BOOST_AUTO_TEST_SUITE_END"))
				;;) @end
			)
			(#make-range! "namespace" @_start @_end)
		]]
	)

	---@diagnostic disable-next-line: missing-parameter, unused-local
	for _, capture, metadata in query:iter_captures(root, bufnr) do
		print(vim.inspect(vim.treesitter.get_node_text(capture, bufnr)))
	end
end
-- test_treesitter_query()

return M
