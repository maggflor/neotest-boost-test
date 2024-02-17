local parsing = require("neotest-boost-test.parsing")
local constructing = require("neotest-boost-test.constructing")
local collecting = require("neotest-boost-test.collecting")

---@type neotest.Adapter
---@class NeotestAdapter
---@field name string
local NeotestAdapter = { name = "neotest-boost-test" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function NeotestAdapter.root(dir)
	-- We do not need the root dir ATM
	return nil
end

--- Analyzes the path to determine whether the file is a C++ test file or not.
---@async
---@param file_path string the path to analyze
---@return boolean true if `path` is a test file, false otherwise.
function NeotestAdapter.is_test_file(file_path)
	return parsing.is_test_file(file_path)
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function NeotestAdapter.filter_dir(name, rel_path, root)
	return parsing.filter_dir(rel_path, root)
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function NeotestAdapter.discover_positions(file_path)
	return parsing.discover_positions(file_path)
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function NeotestAdapter.build_spec(args)
	return constructing.build_spec(args)
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function NeotestAdapter.results(spec, result, tree)
	return collecting.results(spec, result, tree)
end

return NeotestAdapter
