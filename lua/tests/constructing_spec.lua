local constructing = require("neotest-boost-test.constructing")

describe("Finding test case:", function()
	describe("Matching test range:", function()
		it("Finds simple example", function()
			assert.are.same(true, constructing.internals.contains_test_range("path(420)", "path", nil))
		end)

		it("Matches the range", function()
			assert.are.same(false, constructing.internals.contains_test_range("(420)", "", { 42, 0, 42, 0 }))
			assert.are.same(true, constructing.internals.contains_test_range("(420)", "", { 420, 0, 420, 0 }))
		end)

		it("Does not match outside range", function()
			assert.are.same(false, constructing.internals.contains_test_range("(40)", "", { 42, 0, 420, 0 }))
			assert.are.same(false, constructing.internals.contains_test_range("(440)", "", { 42, 0, 420, 0 }))
		end)
	end)
end)
