local collecting = require("neotest-boost-test.collecting")

describe("Results parsing:", function()
	-- Setup test data structures
	local TestCaseSkipped = {
		_attr = { name = "test", reason = "disabled", skipped = "yes" },
	}
	local DiagnosticInfo = {
		Info = {
			"check i == 0 has passed",
			_attr = {
				file = "boost_test_example/unit_test.cpp",
				line = "34",
			},
		},
	}
	local TestSuiteAttr = { _attr = { name = "Master Test Suite" } }

	describe("Preconditions:", function()
		it("Empty test output", function()
			---@diagnostic disable-next-line: param-type-mismatch
			assert.are.same({}, collecting.internals.flatten_to_test_cases(nil))
			assert.are.same({}, collecting.internals.flatten_to_test_cases({}))
			assert.are.same({}, collecting.internals.flatten_to_test_cases({ {} }))
		end)

		it("Tolerates Suites without _attr", function()
			assert.are.same(
				{
					{ _attr = TestCaseSkipped._attr },
				},
				collecting.internals.flatten_to_test_cases({
					TestSuite = {
						TestCase = TestCaseSkipped,
					},
				})
			)
		end)
	end)

	describe("No filtering:", function()
		it("Does not filter skipped tests", function()
			assert.are.same(
				{
					{ _attr = TestCaseSkipped._attr },
				},
				collecting.internals.flatten_to_test_cases({
					TestCase = TestCaseSkipped,
				})
			)
			assert.are.same(
				{
					{ _attr = TestCaseSkipped._attr },
				},
				collecting.internals.flatten_to_test_cases({
					TestSuite = {
						TestCase = TestCaseSkipped,
						_attr = TestSuiteAttr,
					},
				})
			)
		end)

		it("Does not filter duplicates", function()
			assert.are.same(
				{
					{ _attr = TestCaseSkipped._attr },
					{ _attr = TestCaseSkipped._attr },
				},
				collecting.internals.flatten_to_test_cases({
					TestSuite = {
						TestCase = TestCaseSkipped,
						TestSuite = {
							TestCase = TestCaseSkipped,
						},
					},
				})
			)
		end)
	end)

	it("Keeps diagnostic info", function()
		assert.are.same(
			{
				{
					Info = DiagnosticInfo,
					_attr = TestCaseSkipped._attr,
				},
			},
			collecting.internals.flatten_to_test_cases({
				TestSuite = {
					TestCase = {
						{
							Info = DiagnosticInfo,
							_attr = TestCaseSkipped._attr,
						},
					},
					_attr = { name = "Master Test Suite" },
				},
			})
		)
	end)

	it("Multiple same level TestCases", function()
		assert.are.same(
			{
				{ _attr = TestCaseSkipped._attr },
				{ _attr = TestCaseSkipped._attr },
			},
			collecting.internals.flatten_to_test_cases({
				TestSuite = {
					TestCase = {
						TestCaseSkipped,
						TestCaseSkipped,
					},
				},
			})
		)
	end)

	it("Multiple same level TestSuites", function()
		assert.are.same(
			{
				{ _attr = TestCaseSkipped._attr },
				{ _attr = TestCaseSkipped._attr },
			},
			collecting.internals.flatten_to_test_cases({
				TestSuite = {
					{
						TestCase = {
							TestCaseSkipped,
						},
						_attr = TestSuiteAttr,
					},
					{
						TestCase = {
							TestCaseSkipped,
						},
						_attr = TestSuiteAttr,
					},
				},
			})
		)
	end)
end)
