local utils = require("neotest-boost-test.utils.utils")

local Job = require("plenary.job")

local M = {}

---@param dir string relative directory to search in
---@return string[] absolute paths of test executables
local function ctest_search_executables(dir)
	local lines, result_code = Job:new({
		command = "/bin/sh",
		args = {
			"-c",
			string.format("cd %q && ctest -V -N", dir),
		},
		enable_recording = true,
	}):sync()

	if result_code ~= 0 or not lines[1] then
		return {}
	end

	local executables = {}
	for _, line in pairs(lines) do
		local executable = utils.find_word_after(line, "command:")
		if executable ~= nil and string.find(executable, dir) then
			table.insert(executables, executable)
		end
	end
	return executables
end

-- TODO: Consider to extract digraph parsing to file

---@param executable string absolute path of boost test executable
---@return string digraph
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
function M.boost_test_get_digraph(executable)
	local lines, result_code = Job:new({
		command = "/bin/sh",
		args = {
			"-c",
			string.format("%q --list_content=DOT 2>&1", executable),
		},
		enable_recording = true,
	}):sync()

	if result_code ~= 0 or not lines[1] then
		return ""
	end

	return table.concat(lines, "\n")
end

---@param base_build_dir string
---@param test_file string absolute path to test file
---@return string specific build dir for test file
local function find_build_dir(base_build_dir, test_file)
	local file_path = utils.remove_file_name_from_path(test_file)

	-- Remove leading cwd
	local cwd = vim.fn.getcwd()
	if string.find(file_path, cwd) then
		file_path = file_path:sub(#cwd + 1)
	end

	return utils.concat_paths(base_build_dir, file_path)
end

---@param test_node neotest.Node test to search for
---@param build_dir string the directory to search in
---@return string | nil absolute path to test executable
function M.find_test_executable(test_node, build_dir)
	local test_dir = find_build_dir(build_dir, test_node.path)
	local executables = ctest_search_executables(test_dir)
	for _, test_executable in pairs(executables) do
		local digraph = M.boost_test_get_digraph(test_executable)
		local test_start_line = test_node.range[1]
		local search_str = test_node.path .. "(" .. test_start_line .. ")"
		if string.find(digraph, search_str, 0, true) then
			return test_executable
		end
	end
	return nil
end

return M
