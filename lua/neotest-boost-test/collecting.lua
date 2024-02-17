local lib = require("neotest.lib")
local ResultStatus = require("neotest.types").ResultStatus

local M = {}

---@class TestContext
---@field test_id string
---@field file string
---@field line integer
---@field filter string
---@field log_path string
---@field report_path string

-- TODO: Consider to extract boost types to file

---@class TestOutput
---@field TestLog TestLog

---@class TestLog
---@field TestSuite? TestSuiteResult[] | TestSuiteResult
---@field TestCase? TestCaseResult[] | TestCaseResult

---@class TestSuiteResult
---@field TestSuite? TestSuiteResult[] | TestSuiteResult
---@field TestCase? TestCaseResult[] | TestCaseResult
---@field _attr TestResultAttributes

---@class TestCaseResult
---@field _attr TestResultAttributes
---@field Error? TestError[] | TestError
---@field Info? any

---@class TestResultAttributes
---@field name string
---@field skipped? string "yes"
---@field reason? string
---@field file? string
---@field line? string "integer" starting from "1"

---@class TestError
---@field first_element string
---@field _attr TestErrorAttributes

---@class TestErrorAttributes
---@field file string
---@field line string "integer" starting from "1"

---@param test_log TestLog | TestSuiteResult
---@return TestCaseResult[] test cases
---Example TestLog
---{
---TestSuite = {
---  TestCase = {
---	_attr = {
---	  name = "test3",
---	  reason = "disabled",
---	  skipped = "yes"
---	}
---  },
---  TestSuite = {
---	TestCase = { {
---		_attr = {
---		  name = "test1",
---		  reason = "disabled",
---		  skipped = "yes"
---		}
---	  }, {
---		Info = { "check i == 0 has passed",
---		  _attr = {
---			file = "/home/florianm/Dokumente/workspace/boost_test_example/unit_test.cpp",
---			line = "34"
---		  }
---		},
---		TestingTime = "23",
---		_attr = {
---		  file = "/home/florianm/Dokumente/workspace/boost_test_example/unit_test.cpp",
---		  line = "28",
---		  name = "test2"
---		}
---	  } },
---	_attr = {
---	  file = "/home/florianm/Dokumente/workspace/boost_test_example/unit_test.cpp",
---	  line = "13",
---	  name = "TestSuite"
---	}
---  },
---  _attr = {
---	name = "Master Test Suite"
---  }
---}
---}
local function flatten_to_test_cases(test_log)
	---@type TestCaseResult[]
	local test_cases = {}
	if not test_log then
		return test_cases
	end

	if test_log.TestSuite then
		for _, test_case in pairs(flatten_to_test_cases(test_log.TestSuite)) do
			table.insert(test_cases, test_case)
		end
	end
	if test_log.TestCase then
		if test_log.TestCase._attr then
			table.insert(test_cases, test_log.TestCase)
		else
			for _, test_case in pairs(test_log.TestCase) do
				table.insert(test_cases, test_case)
			end
		end
	end
	return test_cases
end

---@param log_path string
---@param test_file string
---@param test_line integer
---@return TestCaseResult | nil
local function read_test_result(log_path, test_file, test_line)
	local success, data = pcall(lib.files.read, log_path)
	if not success then
		vim.notify("Failed to read file " .. log_path, "error")
		return
	end
	---@type TestOutput
	local test_output = lib.xml.parse(data)
	if not test_output then
		vim.notify("Test results not in XML format " .. log_path, "error")
		return
	end
	-- vim.notify(vim.inspect(test_output.TestLog))
	local test_cases = flatten_to_test_cases(test_output.TestLog)
	if #test_cases == 0 then
		vim.notify("No test case results found in test output " .. log_path, "error")
		return
	end
	-- vim.notify(vim.inspect(test_cases))

	---@param test_case TestCaseResult
	local function find_test_case(test_case)
		if test_case._attr.skipped then
			return false
		end
		if test_case._attr.file == test_file and test_case._attr.line == tostring(test_line) then
			return true
		end
		return false
	end
	test_cases = vim.tbl_filter(find_test_case, test_cases)
	if #test_cases > 1 then
		vim.notify("No unique result found for test case.", "warn")
	end
	local test_case = vim.tbl_values(test_cases)[1]
	return test_case
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
--- NOTE: Key string is id from neotest.Node
---@return table<string, neotest.Result>
function M.results(spec, result, tree)
	---@type TestContext
	local context = spec.context

	local test_result = read_test_result(context.log_path, context.file, context.line)
	-- vim.notify(vim.inspect(test_case))
	if not test_result then
		vim.notify("Failed to read test results from " .. context.log_path, "error")
		return {}
	end

	local failed = test_result.Error ~= nil

	local errors = test_result.Error or {}
	if errors._attr ~= nil then
		errors = { errors }
	end
	---@type neotest.Error[]
	local parsed_errors = {}
	for _, error in pairs(errors) do
		table.insert(parsed_errors, {
			message = error[1],
			-- NOTE: Line has to be one less than actual line (0 based)
			line = error._attr.line - 1,
		})
	end

	local success, report = pcall(lib.files.read, context.report_path)
	if not success then
		report = ""
	end

	---@type table<string, neotest.Result>
	local results = {}
	-- TODO: Are there ever more than one result here?
	results[context.test_id] = {
		status = failed and ResultStatus.failed or ResultStatus.passed,
		short = 'Ran test "' .. context.filter .. '":\n' .. report,
		output = result.output,
		errors = parsed_errors,
	}
	return results
end

return M
