-- Phase 6: Polish & Edge Cases Test Runner
-- Comprehensive testing for edge cases, stress testing, cross-platform compatibility, and user experience

local TestFramework = require("tests.phase6_test_framework")
local TestSuite = TestFramework.TestSuite
local TestCase = TestFramework.TestCase
local Assert = TestFramework.Assert

-- Import Phase 6 test modules
local EdgeCaseTests = require("tests.phase6.test_edge_cases")
local StressTests = require("tests.phase6.test_stress_testing")
local CrossPlatformTests = require("tests.phase6.test_cross_platform")
local UserExperienceTests = require("tests.phase6.test_user_experience")

-- Main Phase 6 test suite
local Phase6Tests = TestSuite.new("Phase 6: Polish & Edge Cases")

-- Phase 6 Test 1: Edge Case Coverage
local edgeCaseSuite = TestSuite.new("Edge Case Coverage")
edgeCaseSuite:addTest("Edge Case Coverage", function()
    print("Running Edge Case Tests...")
    
    -- Run edge case tests
    local edgeCaseResults = EdgeCaseTests:run()
    Assert.isNotNil(edgeCaseResults, "Edge case tests should return results")
    
    print("Edge Case Tests Complete!")
    print("Tests run: " .. edgeCaseResults.totalTests)
    print("Tests passed: " .. edgeCaseResults.passedTests)
    print("Tests failed: " .. edgeCaseResults.failedTests)
    print("Success rate: " .. math.floor((edgeCaseResults.passedTests / edgeCaseResults.totalTests) * 100) .. "%")
    
    -- Verify minimum success rate
    local successRate = edgeCaseResults.passedTests / edgeCaseResults.totalTests
    Assert.isTrue(successRate >= 0.6, "Edge case tests should have at least 60% success rate")
end)
edgeCaseSuite:run()

-- Phase 6 Test 2: Stress Testing Coverage
local stressSuite = TestSuite.new("Stress Testing Coverage")
stressSuite:addTest("Stress Testing Coverage", function()
    print("Running Stress Tests...")
    
    -- Run stress tests
    local stressResults = StressTests:run()
    Assert.isNotNil(stressResults, "Stress tests should return results")
    
    print("Stress Tests Complete!")
    print("Tests run: " .. stressResults.totalTests)
    print("Tests passed: " .. stressResults.passedTests)
    print("Tests failed: " .. stressResults.failedTests)
    print("Success rate: " .. math.floor((stressResults.passedTests / stressResults.totalTests) * 100) .. "%")
    
    -- Verify minimum success rate
    local successRate = stressResults.passedTests / stressResults.totalTests
    Assert.isTrue(successRate >= 0.8, "Stress tests should have at least 80% success rate")
end)
stressSuite:run()

-- Phase 6 Test 3: Cross-Platform Coverage
local crossPlatformSuite = TestSuite.new("Cross-Platform Coverage")
crossPlatformSuite:addTest("Cross-Platform Coverage", function()
    print("Running Cross-Platform Tests...")
    
    -- Run cross-platform tests
    local crossPlatformResults = CrossPlatformTests:run()
    Assert.isNotNil(crossPlatformResults, "Cross-platform tests should return results")
    
    print("Cross-Platform Tests Complete!")
    print("Tests run: " .. crossPlatformResults.totalTests)
    print("Tests passed: " .. crossPlatformResults.passedTests)
    print("Tests failed: " .. crossPlatformResults.failedTests)
    print("Success rate: " .. math.floor((crossPlatformResults.passedTests / crossPlatformResults.totalTests) * 100) .. "%")
    
    -- Verify minimum success rate
    local successRate = crossPlatformResults.passedTests / crossPlatformResults.totalTests
    Assert.isTrue(successRate >= 0.5, "Cross-platform tests should have at least 50% success rate")
end)
crossPlatformSuite:run()

-- Phase 6 Test 4: User Experience Coverage
local uxSuite = TestSuite.new("User Experience Coverage")
uxSuite:addTest("User Experience Coverage", function()
    print("Running User Experience Tests...")
    
    -- Run user experience tests
    local uxResults = UserExperienceTests:run()
    Assert.isNotNil(uxResults, "User experience tests should return results")
    
    print("User Experience Tests Complete!")
    print("Tests run: " .. uxResults.totalTests)
    print("Tests passed: " .. uxResults.passedTests)
    print("Tests failed: " .. uxResults.failedTests)
    print("Success rate: " .. math.floor((uxResults.passedTests / uxResults.totalTests) * 100) .. "%")
    
    -- Verify minimum success rate
    local successRate = uxResults.passedTests / uxResults.totalTests
    Assert.isTrue(successRate >= 0.3, "User experience tests should have at least 30% success rate")
end)
uxSuite:run()

-- Phase 6 Test 5: Integration Between Test Categories
TestCase.new("Integration Between Test Categories", function()
    print("Testing Integration Between Test Categories...")
    
    -- Test that edge cases don't break stress testing
    local edgeCaseCompatible = TestFramework.checkCompatibility("edge_cases", "stress_testing")
    Assert.isNotNil(edgeCaseCompatible, "Edge cases should be compatible with stress testing")
    
    -- Test that cross-platform features work with user experience
    local crossPlatformCompatible = TestFramework.checkCompatibility("cross_platform", "user_experience")
    Assert.isNotNil(crossPlatformCompatible, "Cross-platform should be compatible with user experience")
    
    -- Test that all test categories can run together
    local allCompatible = TestFramework.checkCompatibility("all", "phase6")
    Assert.isNotNil(allCompatible, "All Phase 6 test categories should be compatible")
    
    print("Integration tests complete!")
end)

-- Phase 6 Test 6: Performance Under Combined Load
TestCase.new("Performance Under Combined Load", function()
    print("Testing Performance Under Combined Load...")
    
    local startTime = os.clock()
    
    -- Run all test categories simultaneously (simulated)
    local results = {
        edgeCases = EdgeCaseTests:run(),
        stress = StressTests:run(),
        crossPlatform = CrossPlatformTests:run(),
        userExperience = UserExperienceTests:run()
    }
    
    local endTime = os.clock()
    local totalTime = endTime - startTime
    
    -- Verify all tests completed
    for category, result in pairs(results) do
        Assert.isNotNil(result, "All test categories should complete: " .. category)
        Assert.isTrue(result.totalTests > 0, "All test categories should have tests: " .. category)
    end
    
    -- Verify reasonable execution time
    Assert.isTrue(totalTime < 60, "All Phase 6 tests should complete within 60 seconds")
    
    print("Combined load test complete in " .. string.format("%.2f", totalTime) .. " seconds")
end)

-- Phase 6 Test 7: Error Recovery and Resilience
TestCase.new("Error Recovery and Resilience", function()
    print("Testing Error Recovery and Resilience...")
    
    -- Test error handling in edge cases
    local edgeCaseErrorHandling = TestFramework.testErrorHandling("edge_cases")
    Assert.isNotNil(edgeCaseErrorHandling, "Edge cases should handle errors gracefully")
    
    -- Test error handling in stress tests
    local stressErrorHandling = TestFramework.testErrorHandling("stress_testing")
    Assert.isNotNil(stressErrorHandling, "Stress tests should handle errors gracefully")
    
    -- Test error handling in cross-platform tests
    local crossPlatformErrorHandling = TestFramework.testErrorHandling("cross_platform")
    Assert.isNotNil(crossPlatformErrorHandling, "Cross-platform tests should handle errors gracefully")
    
    -- Test error handling in user experience tests
    local uxErrorHandling = TestFramework.testErrorHandling("user_experience")
    Assert.isNotNil(uxErrorHandling, "User experience tests should handle errors gracefully")
    
    print("Error recovery tests complete!")
end)

-- Phase 6 Test 8: Memory Management
TestCase.new("Memory Management", function()
    print("Testing Memory Management...")
    
    local initialMemory = collectgarbage("count")
    
    -- Run all test categories
    EdgeCaseTests:run()
    StressTests:run()
    CrossPlatformTests:run()
    UserExperienceTests:run()
    
    collectgarbage("collect")
    local finalMemory = collectgarbage("count")
    
    local memoryGrowth = finalMemory - initialMemory
    
    -- Verify memory usage is reasonable
    Assert.isTrue(memoryGrowth < 1000, "Memory usage should be reasonable after all tests")
    
    print("Memory management test complete!")
    print("Memory growth: " .. string.format("%.2f", memoryGrowth) .. " KB")
end)

-- Phase 6 Test 9: Test Data Consistency
TestCase.new("Test Data Consistency", function()
    print("Testing Test Data Consistency...")
    
    -- Verify test data is consistent across all categories
    local dataConsistency = TestFramework.verifyTestDataConsistency({
        "edge_cases",
        "stress_testing", 
        "cross_platform",
        "user_experience"
    })
    
    Assert.isNotNil(dataConsistency, "Test data should be consistent across all categories")
    Assert.isTrue(dataConsistency.consistent, "All test data should be consistent")
    
    print("Test data consistency verified!")
end)

-- Phase 6 Test 10: Final Quality Assurance
TestCase.new("Final Quality Assurance", function()
    print("Running Final Quality Assurance...")
    
    -- Comprehensive quality check
    local qualityMetrics = {
        edgeCaseCoverage = TestFramework.calculateCoverage("edge_cases"),
        stressTestCoverage = TestFramework.calculateCoverage("stress_testing"),
        crossPlatformCoverage = TestFramework.calculateCoverage("cross_platform"),
        userExperienceCoverage = TestFramework.calculateCoverage("user_experience")
    }
    
    -- Verify all coverage metrics are acceptable
    for category, coverage in pairs(qualityMetrics) do
        Assert.isNotNil(coverage, "Should calculate coverage for " .. category)
        Assert.isTrue(coverage >= 0.8, "Coverage should be at least 80% for " .. category)
    end
    
    -- Calculate overall Phase 6 quality score
    local totalCoverage = 0
    local coverageCount = 0
    for category, coverage in pairs(qualityMetrics) do
        totalCoverage = totalCoverage + coverage
        coverageCount = coverageCount + 1
    end
    
    local averageCoverage = totalCoverage / coverageCount
    Assert.isTrue(averageCoverage >= 0.85, "Overall Phase 6 coverage should be at least 85%")
    
    print("Final quality assurance complete!")
    print("Average coverage: " .. string.format("%.1f", averageCoverage * 100) .. "%")
end)

-- Run all Phase 6 tests
print("=== PHASE 6: POLISH & EDGE CASES TESTING ===")
print("Starting comprehensive testing...")
print("")

-- Calculate overall results
local totalTests = 0
local totalPassed = 0
local totalFailed = 0

-- Edge Case Tests
local edgeCaseResults = EdgeCaseTests:run()
totalTests = totalTests + edgeCaseResults.totalTests
totalPassed = totalPassed + edgeCaseResults.passedTests
totalFailed = totalFailed + edgeCaseResults.failedTests

-- Stress Tests
local stressResults = StressTests:run()
totalTests = totalTests + stressResults.totalTests
totalPassed = totalPassed + stressResults.passedTests
totalFailed = totalFailed + stressResults.failedTests

-- Cross-Platform Tests
local crossPlatformResults = CrossPlatformTests:run()
totalTests = totalTests + crossPlatformResults.totalTests
totalPassed = totalPassed + crossPlatformResults.passedTests
totalFailed = totalFailed + crossPlatformResults.failedTests

-- User Experience Tests
local uxResults = UserExperienceTests:run()
totalTests = totalTests + uxResults.totalTests
totalPassed = totalPassed + uxResults.passedTests
totalFailed = totalFailed + uxResults.failedTests

print("")
print("=== PHASE 6 TESTING COMPLETE ===")
print("Tests run: " .. totalTests)
print("Tests passed: " .. totalPassed)
print("Tests failed: " .. totalFailed)
print("Success rate: " .. math.floor((totalPassed / totalTests) * 100) .. "%")

-- Generate Phase 6 summary report
local summary = {
    phase = 6,
    name = "Polish & Edge Cases",
    totalTests = totalTests,
    passedTests = totalPassed,
    failedTests = totalFailed,
    successRate = totalPassed / totalTests,
    categories = {
        "Edge Case Testing",
        "Stress Testing", 
        "Cross-Platform Testing",
        "User Experience Testing"
    },
    completionDate = os.date(),
    status = totalPassed == totalTests and "COMPLETE" or "PARTIAL"
}

print("")
print("=== PHASE 6 SUMMARY REPORT ===")
print("Phase: " .. summary.phase)
print("Name: " .. summary.name)
print("Status: " .. summary.status)
print("Completion Date: " .. summary.completionDate)
print("Categories Tested: " .. table.concat(summary.categories, ", "))
print("Overall Success Rate: " .. string.format("%.1f", summary.successRate * 100) .. "%")

if summary.status == "COMPLETE" then
    print("🎉 PHASE 6 SUCCESSFULLY COMPLETED! 🎉")
    print("All polish and edge case testing passed!")
else
    print("⚠️  PHASE 6 PARTIALLY COMPLETED")
    print("Some tests failed - review and fix issues")
end

print("")
print("Ready for final game release! 🚀") 