local M = {}

---@param strategy string i.e. "dap"
---@param test_executable string Test executable
---@param directory string Directory from where to launch test_executable
---@param args table? extra arguments for executable
---@return table? configuration Dap configuration similar to what is specified in launch.json. Schema can be found here: https://raw.githubusercontent.com/mfussenegger/dapconfig-schema/master/dapconfig-schema.json
function M:create_strategy(strategy, test_executable, directory, args)
	if strategy == "dap" then
		return {
			type = "cppdbg",
			name = "Neotest Debugger",
			request = "launch",
			program = test_executable,
			cwd = directory,
			args = args,
			stopAtEntry = false,
			setupCommands = {
				{
					text = "-enable-pretty-printing",
					description = "enable pretty printing",
					ignoreFailures = false,
				},
			},
		}
	elseif strategy == "integrated" then
		return nil
	else
		vim.notify("Strategy '" .. strategy .. "' not supported, yet.", vim.log.levels.ERROR)
		return nil
	end
end

return M
