local process = require("neotest.lib.process")

local M = {}

---@class neotest.Node
---@field id string
---@field name string
---@field path string
---@field range integer[4]
---@field type string

---@param dir string relative directory to search in
---@return string[] absolute paths of test executables
local function ctest_search_executables(dir)
	local result, data = process.run({
		"bash",
		"-c",
		"cd " .. dir .. " && " .. "ctest -V -N",
	}, { stdout = true, stderr = false })
	if result ~= 0 then
		return {}
	end

	local lines = vim.split(data.stdout, "\n", { plain = true })
	for _, line in pairs(lines) do
		local words = vim.split(line, " ", { plain = true })
		for _, word in pairs(words) do
			if word == "command:" then
				-- TODO: More than one test executable
				return { words[#words] }
			end
		end
	end
	return {}
end

---@param executable string absolute path of boost test executable
---@return string digraph
local function boost_test_get_digraph(executable)
	local result, data = process.run({
		"bash",
		"-c",
		executable .. " --list_content=DOT",
	}, { stdout = false, stderr = true })
	if result ~= 0 then
		return ""
	end

	return data.stderr
end

---@param test_node neotest.Node test to search for
---@param build_dir string the directory to search in
---@return string absolute path to test executable
local function find_test_executable(test_node, build_dir)
	for _, test_executable in pairs(ctest_search_executables(build_dir)) do
		local digraph = boost_test_get_digraph(test_executable)
		-- Convert from 0 based to 1 based
		local test_start_line = test_node.range[1] + 1
		local search_str = test_node.path .. "(" .. test_start_line .. ")"
		if string.find(digraph, search_str, 0, true) then
			return test_executable
		end
	end
	return ""
end

---@param test_node neotest.Node test to search for
---@param executable string absolute path to test executable
---@return string filter to run only this test (i.e. inclusive surrounding test suites)
---Example digraph
---digraph G {rankdir=LR;
---tu1[shape=ellipse,peripheries=2,fontname=Helvetica,color=green,label="Master Test Suite"];
---{
---tu65536[shape=Mrecord,fontname=Helvetica,color=green,label="test3|/home/user/Dokumente/workspace/boost_test_example/unit_test.cpp(4)"];
---tu1 -> tu65536;
---tu2[shape=Mrecord,fontname=Helvetica,color=green,label="TestSuite|/home/user/Dokumente/workspace/boost_test_example/unit_test.cpp(13)"];
---tu1 -> tu2;
---{
---tu65537[shape=Mrecord,fontname=Helvetica,color=green,label="test1|/home/user/Dokumente/workspace/boost_test_example/unit_test.cpp(19)"];
---tu2 -> tu65537;
---tu65538[shape=Mrecord,fontname=Helvetica,color=green,label="test2|/home/user/Dokumente/workspace/boost_test_example/unit_test.cpp(28)"];
---tu2 -> tu65538;
---}
---}
---}
local function boost_test_get_filter(test_node, executable)
	local digraph = boost_test_get_digraph(executable)

	-- Convert from 0 based to 1 based
	local test_start_line = test_node.range[1] + 1
	local test_location_str = test_node.path .. "(" .. test_start_line .. ")"

	local scope = {}
	local lines = vim.split(digraph, "\n", { plain = true })
	for i, line in ipairs(lines) do
		if string.find(line, test_location_str, 0, true) then
			return table.concat(scope) .. test_node.name
		end
		if line == "{" then
			local match = string.match(lines[i - 2], 'label="(.*)|')
			-- vim.notify(vim.inspect(match))
			if match then
				table.insert(scope, match .. "/")
			end
		end
	end

	vim.notify("Could not determine scope of test '" .. test_node.name .. "' in test file.", "error")
	return ""
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function M.build_spec(args)
	if #args.tree:children() > 0 then
		local results = {}
		for i, child in ipairs(args.tree:children()) do
			results[i] = M.build_spec({
				tree = child,
				strategy = args.strategy,
				extra_args = args.extra_args,
			})
		end
		return results
	end

	---@type neotest.Node
	local test_node = args.tree:to_list()[1]
	-- vim.notify("Running test " .. vim.inspect(test_node))
	if test_node.type ~= "test" then
		-- TODO: Support test suites
		vim.notify("'" .. test_node.type .. "' tests are not supported, yet.", "error")
		return
	end

	-- TODO: Make build dir configurable
	local build_dir = "build/"
	local executable = find_test_executable(test_node, build_dir)
	if executable == "" then
		vim.notify(
			"Test executable not found.\n"
				.. "The test may not be built or the build directory '"
				.. build_dir
				.. "' may not be correct.",
			"error"
		)
		return
	end
	-- TODO: Warn if executable is older than test file

	local test_filter = boost_test_get_filter(test_node, executable)
	local command = vim.tbl_flatten({
		executable,
		"--run_test=" .. test_filter,
		args.extra_args,
	})

	return {
		command = command,
		-- No env needed
		env = nil,
		cwd = build_dir,
		-- We don't need any context preserved for now
		context = nil,
		-- No dap strategy for now
		strategy = nil,
	}
end

return M
