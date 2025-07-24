-- Unit Test Runner for Orbit Jump
-- Uses the new test framework to run comprehensive unit tests

local Utils = require("src.utils.utils")
local ModernTestFramework = Utils.require("tests.modern_test_framework")

-- Initialize the framework
ModernTestFramework.init()

-- Import test suites
local GameLogicTests = Utils.require("tests.unit.game_logic_tests")
local RendererTests = Utils.require("tests.unit.renderer_tests")
local SaveSystemTests = Utils.require("tests.unit.save_system_tests")
local UtilsTests = Utils.require("tests.unit.utils_tests")
local CameraTests = Utils.require("tests.unit.camera_tests")
local CollisionTests = Utils.require("tests.unit.collision_tests")

-- Collect all test suites
local allTestSuites = {
    ["Game Logic"] = GameLogicTests,
    ["Renderer"] = RendererTests,
    ["Save System"] = SaveSystemTests,
    ["Utils"] = UtilsTests,
    ["Camera"] = CameraTests,
    ["Collision"] = CollisionTests
}

-- Run all test suites
local allPassed = ModernTestFramework.runAllSuites(allTestSuites)

-- Exit with appropriate code
if allPassed then
    print("\n🎉 All unit tests passed!")
    os.exit(0)
else
    print("\n💥 Some unit tests failed!")
    os.exit(1)
end 