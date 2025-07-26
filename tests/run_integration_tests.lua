-- Integration Test Runner for Orbit Jump
-- Runs all integration tests and displays results

package.path = package.path .. ";../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")

-- Initialize test framework
TestFramework.init()

print("=== Orbit Jump Integration Tests ===")
print()

-- Run integration tests
local integrationTests = require("tests.integration_tests.test_integration")
local success = integrationTests.run()

print()
if success then
    print("✅ All integration tests passed!")
else
    print("❌ Some integration tests failed!")
end

print()
print("=== Integration Test Summary ===")
print("Phase 5: Integration & Advanced Features")
print("- Complete game session flow")
print("- System interactions")
print("- Progression integration")
print("- World generation and discovery")
print("- Ring system with progression")
print("- Achievement system integration")
print("- Upgrade system integration")
print("- Particle system integration")
print("- Camera and player interaction")
print("- Sound system integration")
print("- Performance monitoring integration")
print("- Mobile input integration")
print("- Save and load integration")
print("- Error handling integration")
print("- Full game loop simulation")

return success 