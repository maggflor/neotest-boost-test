local async = require("neotest.async")
local lib = require("neotest.lib")
local strategy = require("neotest-boost-test.strategy")

local searching = require("neotest-boost-test.utils.searching")
local utils = require("neotest-boost-test.utils.utils")

local M = {}

---@param test_node neotest.Node test to search for
---@param executable string absolute path to test executable
---@return string filter to run only this test (i.e. inclusive surrounding test suites)
local function boost_test_get_filter(test_node, executable)
	local digraph = searching.boost_test_get_digraph(executable)

	local test_start_line = test_node.range[1]
	local test_location_str = test_node.path .. "(" .. test_start_line .. ")"

	local scope = {}
	local lines = vim.split(digraph, "\n", { plain = true })
	for i, line in ipairs(lines) do
		if string.find(line, test_location_str, 0, true) then
			return table.concat(scope) .. test_node.name
		end

		if line == "{" then
			local match = string.match(lines[i - 2], 'label="(.*)|')
			if match then
				table.insert(scope, match .. "/")
			else
				table.insert(scope, "")
			end
		elseif line == "}" then
			table.remove(scope, #scope)
		end
	end

	vim.notify("Could not determine scope of test '" .. test_node.name .. "' in test file.", vim.log.levels.ERROR)
	return ""
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function M.build_spec(args)
	---@type neotest.Node
	local test_node = args.tree:to_list()[1]
	if test_node.type ~= "test" then
		-- TODO: Support test suites
		return
	end

	-- TODO: Make build dir configurable
	local build_dir = utils.build_root_from_compile_commands() or "build/"
	local executable = searching.find_test_executable(test_node, build_dir)
	if not executable then
		vim.notify(
			"Test executable not found.\n"
				.. "The test may not be built or the build directory '"
				.. build_dir
				.. "' may not be correct.",
			vim.log.levels.ERROR
		)
		return
	end
	local executable_path = utils.remove_file_name_from_path(executable)

	local last_modified_test = vim.uv.fs_stat(executable).mtime.sec
	local last_modified_source = vim.uv.fs_stat(test_node.path).mtime.sec
	if last_modified_source > last_modified_test then
		local path_elements = vim.split(executable, lib.files.sep, { plain = true })
		local executable_name = path_elements[#path_elements]
		vim.notify("Test source is newer than test executable.", vim.log.levels.WARN)
		vim.notify("Try to build the target '" .. executable_name .. "' ...", vim.log.levels.INFO)
		-- TODO: Start with toggleterm, detach, etc.
	end

	local test_filter = boost_test_get_filter(test_node, executable)
	local log_path = async.fn.tempname()
	local report_path = async.fn.tempname()
	local arguments = {
		"--run_test=" .. test_filter,
		"--log_format=XML",
		"--log_level=all",
		"--log_sink=" .. string.format("%q", log_path),
		"--report_format=HRF",
		-- TODO: Make report level configurable
		"--report_level=detailed",
		"--report_sink=" .. string.format("%q", report_path),
		args.extra_args,
	}
	local command = utils.tbl_flatten({
		-- TODO: Make configurable whether to switch dir
		string.format("cd %q", executable_path),
		"&&",
		string.format("%q", executable),
		arguments,
	})

	return {
		command = { "/bin/sh", "-c", table.concat(command, " ") },
		-- No env needed
		env = nil,
		cwd = build_dir,
		---@type TestContext
		context = {
			test_id = test_node.id,
			file = test_node.path,
			line = test_node.range[1],
			end_line = test_node.range[3],
			filter = test_filter,
			log_path = log_path,
			report_path = report_path,
		},
		strategy = strategy:create_strategy(args.strategy, executable, executable_path, arguments),
	}
end

return M
