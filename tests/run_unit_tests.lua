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
local SoundManagerTests = Utils.require("tests.unit.test_sound_manager")
local SoundGeneratorTests = Utils.require("tests.unit.test_sound_generator")
local PerformanceMonitorTests = Utils.require("tests.unit.test_performance_monitor")
local PerformanceSystemTests = Utils.require("tests.unit.test_performance_system")
local ErrorHandlerTests = Utils.require("tests.utils.test_error_handler")
local ModuleLoaderTests = Utils.require("tests.utils.test_module_loader")
local ConstantsTests = Utils.require("tests.utils.test_constants")

-- New test suites
local SystemOrchestratorTests = Utils.require("tests.core.test_system_orchestrator")
local EventBusTests = Utils.require("tests.utils.test_event_bus")
local SpatialGridTests = Utils.require("tests.utils.test_spatial_grid")
local EmotionalFeedbackTests = Utils.require("tests.systems.test_emotional_feedback")
local PlayerAnalyticsTests = Utils.require("tests.systems.test_player_analytics")
local ObjectPoolTests = Utils.require("tests.utils.test_object_pool")
local RenderBatchTests = Utils.require("tests.utils.test_render_batch")
local AssetLoaderTests = Utils.require("tests.utils.test_asset_loader")

-- Collect all test suites
local allTestSuites = {
    ["Game Logic"] = GameLogicTests,
    ["Renderer"] = RendererTests,
    ["Save System"] = SaveSystemTests,
    ["Utils"] = UtilsTests,
    ["Camera"] = CameraTests,
    ["Collision"] = CollisionTests,
    ["Sound Manager"] = SoundManagerTests,
    ["Sound Generator"] = SoundGeneratorTests,
    ["Performance Monitor"] = PerformanceMonitorTests,
    ["Performance System"] = PerformanceSystemTests,
    ["Error Handler"] = ErrorHandlerTests,
    ["Module Loader"] = ModuleLoaderTests,
    ["Constants"] = ConstantsTests,
    ["System Orchestrator"] = SystemOrchestratorTests,
    ["Event Bus"] = EventBusTests,
    ["Spatial Grid"] = SpatialGridTests,
    ["Emotional Feedback"] = EmotionalFeedbackTests,
    ["Player Analytics"] = PlayerAnalyticsTests,
    ["Object Pool"] = ObjectPoolTests,
    ["Render Batch"] = RenderBatchTests,
    ["Asset Loader"] = AssetLoaderTests
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