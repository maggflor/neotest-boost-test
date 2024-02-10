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

	local parts = vim.split(data.stdout, "\n", { plain = true })
	for _, part in pairs(parts) do
		local words = vim.split(part, " ", { plain = true })
		for _, word in pairs(words) do
			if word == "command:" then
				-- TODO: More than one test executable
				return { words[#words] }
			end
		end
	end
	return {}
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function M.build_spec(args)
	if #args.tree:to_list() ~= 1 then
		-- TODO: Support more than one test
		vim.notify("Only one test at a time, sorry :(", "error")
		return
	end
	---@type neotest.Node
	local test = args.tree:to_list()[1]
	-- vim.notify("Running test " .. vim.inspect(test))

	local executables = ctest_search_executables("build/")
	-- TODO: Find executable with --list_content=DOT containing our test file
	-- TODO: Error when our test case is contained multiple times
	--       In that case, we have to know about the test suite, which is not implemented yet
	local executable = "build/boost_test_example"

	local command = vim.tbl_flatten({
		executable,
		-- TODO: Dynamically determine */
		"--run_test=*/" .. test.name,
		args.extra_args,
	})

	return {
		command = command,
		-- No env needed
		env = nil,
		-- TODO: Select location of test
		cwd = nil,
		-- We don't need any context preserved for now
		context = nil,
		-- No dap strategy for now
		strategy = nil,
	}
end

return M
