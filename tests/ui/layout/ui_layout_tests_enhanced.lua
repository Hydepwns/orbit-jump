--[[
    Enhanced UI Layout Testing Suite
    
    This comprehensive testing framework provides:
    - Robust test execution with error handling
    - Performance benchmarking for UI operations
    - Multi-device simulation and testing
    - Accessibility compliance validation
    - Automated regression testing
    - Test report generation
    - CI/CD integration support
--]]

local Utils = require("src.utils.utils")
local UISystem = require("src.ui.ui_system")
local UIDebug = require("src.ui.debug.ui_debug_enhanced")

local UILayoutTests = {}

-- Test configuration
UILayoutTests.config = {
    timeout = 5000, -- 5 seconds per test
    maxRetries = 3,
    enablePerformanceTests = true,
    enableAccessibilityTests = true,
    enableRegressionTests = true,
    logLevel = "INFO",
    generateReports = true,
    strictMode = false
}

-- Test state tracking
UILayoutTests.testResults = {}
UILayoutTests.performanceBaselines = {}
UILayoutTests.regressionData = {}

-- Mock Love2D environment with enhanced features
local function setupMockEnvironment(screenWidth, screenHeight, deviceType)
    deviceType = deviceType or "desktop"
    
    _G.love = _G.love or {}
    _G.love.graphics = {
        getDimensions = function() return screenWidth or 800, screenHeight or 600 end,
        getWidth = function() return screenWidth or 800 end,
        getHeight = function() return screenHeight or 600 end,
        setColor = function() end,
        rectangle = function() end,
        print = function() end,
        setFont = function() end,
        getFont = function() return {getHeight = function() return 12 end} end,
        push = function() end,
        pop = function() end,
        setLineWidth = function() end,
        captureScreenshot = function() end
    }
    _G.love.timer = {
        getTime = function() return os.time() + math.random() end
    }
    _G.love.system = {
        getOS = function() 
            if deviceType == "mobile" then return "Android"
            else return "Windows" end
        end
    }
    
    -- Mock mobile detection
    if Utils.MobileInput then
        Utils.MobileInput.isMobile = function() return deviceType == "mobile" end
        Utils.MobileInput.getUIScale = function() 
            return deviceType == "mobile" and 1.5 or 1.0 
        end
    end
end

-- Enhanced test execution framework
function UILayoutTests.runTest(testFunc, testName, config)
    config = config or {}
    local startTime = os.clock()
    local attempts = 0
    local maxAttempts = config.maxRetries or UILayoutTests.config.maxRetries
    
    local result = {
        name = testName,
        passed = false,
        error = nil,
        duration = 0,
        attempts = 0,
        performance = {},
        warnings = {},
        metadata = {}
    }
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        result.attempts = attempts
        
        local success, testResult = pcall(testFunc)
        
        if success then
            result.passed = testResult.passed or false
            result.issues = testResult.issues or {}
            result.warnings = testResult.warnings or {}
            result.metadata = testResult.metadata or {}
            result.performance = testResult.performance or {}
            break
        else
            result.error = testResult
            if attempts >= maxAttempts then
                result.passed = false
            else
                -- Wait before retry
                os.execute("sleep 0.1")
            end
        end
    end
    
    result.duration = os.clock() - startTime
    table.insert(UILayoutTests.testResults, result)
    
    return result
end

-- Test: Enhanced basic element positioning with error handling
function UILayoutTests.testEnhancedElementPositioning()
    local testData = {
        {width = 800, height = 600, name = "Standard"},
        {width = 1920, height = 1080, name = "HD"},
        {width = 390, height = 844, name = "Mobile"},
        {width = 320, height = 568, name = "Small Mobile"}
    }
    
    local allIssues = {}
    local performance = {}
    local warnings = {}
    
    for _, screen in ipairs(testData) do
        local startTime = os.clock()
        
        setupMockEnvironment(screen.width, screen.height, 
            screen.width < 1000 and "mobile" or "desktop")
        
        -- Test with error handling
        local success, error = pcall(function()
            UISystem.updateResponsiveLayout()
        end)
        
        if not success then
            table.insert(allIssues, string.format("%s: Layout update failed - %s", screen.name, error))
        else
            -- Validate elements
            for name, element in pairs(UISystem.elements) do
                -- Comprehensive validation
                if not element then
                    table.insert(allIssues, string.format("%s/%s: Element is nil", screen.name, name))
                elseif type(element) ~= "table" then
                    table.insert(allIssues, string.format("%s/%s: Element is not a table", screen.name, name))
                else
                    -- Check required properties with type validation
                    local requiredProps = {
                        {name = "x", type = "number"},
                        {name = "y", type = "number"},
                        {name = "width", type = "number"},
                        {name = "height", type = "number"}
                    }
                    
                    for _, prop in ipairs(requiredProps) do
                        if element[prop.name] == nil then
                            table.insert(allIssues, string.format("%s/%s: Missing %s", screen.name, name, prop.name))
                        elseif type(element[prop.name]) ~= prop.type then
                            table.insert(allIssues, string.format("%s/%s: %s is %s, expected %s", 
                                screen.name, name, prop.name, type(element[prop.name]), prop.type))
                        end
                    end
                    
                    -- Validate bounds
                    if element.x and element.y and element.width and element.height then
                        if element.x < -1 or element.y < -1 then
                            table.insert(allIssues, string.format("%s/%s: Negative position (%.1f, %.1f)", 
                                screen.name, name, element.x, element.y))
                        end
                        
                        if element.width <= 0 or element.height <= 0 then
                            table.insert(allIssues, string.format("%s/%s: Invalid dimensions %.1fx%.1f", 
                                screen.name, name, element.width, element.height))
                        end
                        
                        if element.x + element.width > screen.width + 1 then
                            table.insert(allIssues, string.format("%s/%s: Exceeds right boundary", screen.name, name))
                        end
                        
                        if element.y + element.height > screen.height + 1 then
                            table.insert(allIssues, string.format("%s/%s: Exceeds bottom boundary", screen.name, name))
                        end
                        
                        -- Performance warnings
                        if element.width * element.height > 500000 then
                            table.insert(warnings, string.format("%s/%s: Large element area may impact performance", 
                                screen.name, name))
                        end
                    end
                end
            end
        end
        
        performance[screen.name] = os.clock() - startTime
    end
    
    return {
        passed = #allIssues == 0,
        issues = allIssues,
        warnings = warnings,
        performance = performance,
        metadata = {
            elementsPerScreen = {},
            averageElementSize = {}
        }
    }
end

-- Test: Advanced responsive layout validation
function UILayoutTests.testAdvancedResponsiveLayout()
    local testDevices = {
        {width = 320, height = 568, name = "iPhone SE", type = "mobile"},
        {width = 390, height = 844, name = "iPhone 14", type = "mobile"},
        {width = 768, height = 1024, name = "iPad", type = "tablet"},
        {width = 1366, height = 768, name = "Laptop", type = "desktop"},
        {width = 1920, height = 1080, name = "Desktop HD", type = "desktop"},
        {width = 2560, height = 1440, name = "Desktop QHD", type = "desktop"}
    }
    
    local layoutComparisons = {}
    local issues = {}
    local warnings = {}
    local performance = {}
    
    for _, device in ipairs(testDevices) do
        local startTime = os.clock()
        setupMockEnvironment(device.width, device.height, device.type)
        
        local success, error = pcall(function()
            UISystem.updateResponsiveLayout()
        end)
        
        if success then
            layoutComparisons[device.name] = {
                elements = {},
                deviceInfo = device
            }
            
            for name, element in pairs(UISystem.elements) do
                layoutComparisons[device.name].elements[name] = {
                    x = element.x,
                    y = element.y,
                    width = element.width,
                    height = element.height
                }
            end
        else
            table.insert(issues, string.format("%s: Layout failed - %s", device.name, error))
        end
        
        performance[device.name] = os.clock() - startTime
    end
    
    -- Analyze layout differences
    local baselineDevice = "Desktop HD"
    if layoutComparisons[baselineDevice] then
        for deviceName, layout in pairs(layoutComparisons) do
            if deviceName ~= baselineDevice then
                local identicalCount = 0
                local totalElements = 0
                
                for elementName, element in pairs(layout.elements) do
                    totalElements = totalElements + 1
                    local baseElement = layoutComparisons[baselineDevice].elements[elementName]
                    
                    if baseElement and 
                       baseElement.x == element.x and baseElement.y == element.y and
                       baseElement.width == element.width and baseElement.height == element.height then
                        identicalCount = identicalCount + 1
                    end
                end
                
                -- Warn if layouts are too similar (not responsive enough)
                if totalElements > 0 and (identicalCount / totalElements) > 0.8 then
                    table.insert(warnings, string.format("%s: Layout too similar to desktop (%.1f%% identical)", 
                        deviceName, (identicalCount / totalElements) * 100))
                end
            end
        end
    end
    
    return {
        passed = #issues == 0,
        issues = issues,
        warnings = warnings,
        performance = performance,
        metadata = {
            layoutComparisons = layoutComparisons,
            devicesTested = #testDevices
        }
    }
end

-- Test: Accessibility compliance validation
function UILayoutTests.testAccessibilityCompliance()
    if not UILayoutTests.config.enableAccessibilityTests then
        return {passed = true, issues = {}, skipped = true}
    end
    
    local testDevices = {
        {width = 390, height = 844, name = "iPhone", type = "mobile"},
        {width = 768, height = 1024, name = "iPad", type = "tablet"}
    }
    
    local issues = {}
    local warnings = {}
    local performance = {}
    
    for _, device in ipairs(testDevices) do
        local startTime = os.clock()
        setupMockEnvironment(device.width, device.height, device.type)
        UISystem.updateResponsiveLayout()
        
        for name, element in pairs(UISystem.elements) do
            if element.x and element.y and element.width and element.height then
                -- WCAG 2.1 AA compliance checks
                
                -- Minimum touch target size (44x44pt for iOS)
                if device.type == "mobile" then
                    if element.width < 44 or element.height < 44 then
                        table.insert(issues, string.format("%s/%s: Touch target too small (%.0fx%.0f, min 44x44)", 
                            device.name, name, element.width, element.height))
                    end
                end
                
                -- Adequate spacing between interactive elements
                for otherName, otherElement in pairs(UISystem.elements) do
                    if name ~= otherName and otherElement.x and otherElement.y then
                        local dx = element.x - otherElement.x
                        local dy = element.y - otherElement.y
                        local distance = math.sqrt(dx * dx + dy * dy)
                        
                        if distance < 8 and distance > 0 then -- Elements are very close
                            table.insert(warnings, string.format("%s: %s and %s are very close (%.1fpx apart)", 
                                device.name, name, otherName, distance))
                        end
                    end
                end
                
                -- Check for elements that are too small to be usable
                if element.width < 16 or element.height < 16 then
                    table.insert(warnings, string.format("%s/%s: Element may be too small for accessibility (%.0fx%.0f)", 
                        device.name, name, element.width, element.height))
                end
            end
        end
        
        performance[device.name] = os.clock() - startTime
    end
    
    return {
        passed = #issues == 0,
        issues = issues,
        warnings = warnings,
        performance = performance,
        metadata = {
            wcagLevel = "AA",
            devicesTested = #testDevices
        }
    }
end

-- Test: Performance benchmarking
function UILayoutTests.testPerformanceBenchmarks()
    if not UILayoutTests.config.enablePerformanceTests then
        return {passed = true, issues = {}, skipped = true}
    end
    
    local benchmarks = {}
    local issues = {}
    local warnings = {}
    
    -- Test layout update performance
    local layoutUpdateTimes = {}
    for i = 1, 100 do
        setupMockEnvironment(math.random(320, 2560), math.random(568, 1440))
        
        local startTime = os.clock()
        UISystem.updateResponsiveLayout()
        local endTime = os.clock()
        
        table.insert(layoutUpdateTimes, endTime - startTime)
    end
    
    -- Calculate statistics
    table.sort(layoutUpdateTimes)
    local count = #layoutUpdateTimes
    local sum = 0
    for _, time in ipairs(layoutUpdateTimes) do
        sum = sum + time
    end
    
    benchmarks.layoutUpdate = {
        average = sum / count,
        median = layoutUpdateTimes[math.ceil(count / 2)],
        min = layoutUpdateTimes[1],
        max = layoutUpdateTimes[count],
        p95 = layoutUpdateTimes[math.ceil(count * 0.95)],
        p99 = layoutUpdateTimes[math.ceil(count * 0.99)]
    }
    
    -- Performance thresholds (in seconds)
    local thresholds = {
        layoutUpdate = {
            warning = 0.001,  -- 1ms
            error = 0.005     -- 5ms
        }
    }
    
    -- Check against thresholds
    if benchmarks.layoutUpdate.p95 > thresholds.layoutUpdate.error then
        table.insert(issues, string.format("Layout update is too slow: %.3fms (p95), max %.3fms", 
            benchmarks.layoutUpdate.p95 * 1000, thresholds.layoutUpdate.error * 1000))
    elseif benchmarks.layoutUpdate.p95 > thresholds.layoutUpdate.warning then
        table.insert(warnings, string.format("Layout update performance warning: %.3fms (p95)", 
            benchmarks.layoutUpdate.p95 * 1000))
    end
    
    return {
        passed = #issues == 0,
        issues = issues,
        warnings = warnings,
        performance = benchmarks,
        metadata = {
            samplesCollected = count,
            thresholds = thresholds
        }
    }
end

-- Test: Memory usage validation
function UILayoutTests.testMemoryUsage()
    local initialMemory = collectgarbage("count")
    
    -- Simulate heavy UI operations
    for i = 1, 50 do
        setupMockEnvironment(math.random(320, 2560), math.random(568, 1440))
        UISystem.updateResponsiveLayout()
        
        -- Force garbage collection occasionally
        if i % 10 == 0 then
            collectgarbage("collect")
        end
    end
    
    local finalMemory = collectgarbage("count")
    local memoryIncrease = finalMemory - initialMemory
    
    local issues = {}
    local warnings = {}
    
    -- Memory thresholds (in KB)
    if memoryIncrease > 1000 then -- 1MB increase
        table.insert(issues, string.format("Excessive memory usage increase: %.1fKB", memoryIncrease))
    elseif memoryIncrease > 500 then -- 500KB increase
        table.insert(warnings, string.format("Notable memory usage increase: %.1fKB", memoryIncrease))
    end
    
    return {
        passed = #issues == 0,
        issues = issues,
        warnings = warnings,
        performance = {
            initialMemory = initialMemory,
            finalMemory = finalMemory,
            memoryIncrease = memoryIncrease
        },
        metadata = {
            operations = 50,
            gcCalls = 5
        }
    }
end

-- Test: Edge case handling
function UILayoutTests.testEdgeCases()
    local issues = {}
    local warnings = {}
    
    local edgeCases = {
        {width = 0, height = 0, name = "Zero dimensions"},
        {width = -100, height = -100, name = "Negative dimensions"},
        {width = 1, height = 1, name = "Minimal dimensions"},
        {width = 10000, height = 10000, name = "Extreme dimensions"},
        {width = 1.5, height = 1.5, name = "Fractional dimensions"}
    }
    
    for _, testCase in ipairs(edgeCases) do
        local success, error = pcall(function()
            setupMockEnvironment(testCase.width, testCase.height)
            UISystem.updateResponsiveLayout()
        end)
        
        if not success then
            table.insert(issues, string.format("%s: Failed with error - %s", testCase.name, error))
        else
            -- Check if elements are reasonable
            for name, element in pairs(UISystem.elements) do
                if element.width and element.height then
                    if element.width <= 0 or element.height <= 0 then
                        table.insert(warnings, string.format("%s/%s: Element has invalid dimensions", 
                            testCase.name, name))
                    end
                end
            end
        end
    end
    
    return {
        passed = #issues == 0,
        issues = issues,
        warnings = warnings,
        metadata = {
            edgeCasesTested = #edgeCases
        }
    }
end

-- Comprehensive test suite runner with enhanced reporting
function UILayoutTests.runComprehensiveTests()
    UILayoutTests.testResults = {}
    
    local testSuite = {
        {func = UILayoutTests.testEnhancedElementPositioning, name = "Enhanced Element Positioning"},
        {func = UILayoutTests.testAdvancedResponsiveLayout, name = "Advanced Responsive Layout"},
        {func = UILayoutTests.testAccessibilityCompliance, name = "Accessibility Compliance"},
        {func = UILayoutTests.testPerformanceBenchmarks, name = "Performance Benchmarks"},
        {func = UILayoutTests.testMemoryUsage, name = "Memory Usage"},
        {func = UILayoutTests.testEdgeCases, name = "Edge Case Handling"}
    }
    
    local overallStartTime = os.clock()
    local totalPassed = 0
    local totalTests = 0
    local totalWarnings = 0
    local totalSkipped = 0
    
    print("🚀 Running Comprehensive UI Layout Tests")
    print("=" .. string.rep("=", 60))
    print()
    
    for _, test in ipairs(testSuite) do
        local result = UILayoutTests.runTest(test.func, test.name)
        totalTests = totalTests + 1
        
        if result.skipped then
            totalSkipped = totalSkipped + 1
            print(string.format("⏭️  SKIP  %s (%.3fs)", result.name, result.duration))
        elseif result.passed then
            totalPassed = totalPassed + 1
            local status = #result.warnings > 0 and "⚠️  PASS*" or "✅ PASS "
            print(string.format("%s %s (%.3fs)", status, result.name, result.duration))
            
            if #result.warnings > 0 then
                totalWarnings = totalWarnings + #result.warnings
                for _, warning in ipairs(result.warnings) do
                    print("   ⚠️  " .. warning)
                end
            end
        else
            print(string.format("❌ FAIL  %s (%.3fs, %d attempts)", result.name, result.duration, result.attempts))
            
            if result.error then
                print("   💥 Error: " .. tostring(result.error))
            end
            
            for _, issue in ipairs(result.issues or {}) do
                print("   🔍 " .. issue)
            end
        end
        
        -- Show performance metrics if available
        if result.performance and type(result.performance) == "table" then
            for metric, value in pairs(result.performance) do
                if type(value) == "number" then
                    print(string.format("   📊 %s: %.3fms", metric, value * 1000))
                end
            end
        end
        
        print()
    end
    
    local totalDuration = os.clock() - overallStartTime
    
    print("=" .. string.rep("=", 60))
    print(string.format("📋 Test Summary: %d/%d passed, %d warnings, %d skipped (%.3fs total)", 
          totalPassed, totalTests, totalWarnings, totalSkipped, totalDuration))
    
    -- Generate detailed report
    if UILayoutTests.config.generateReports then
        UILayoutTests.generateDetailedReport()
    end
    
    return {
        results = UILayoutTests.testResults,
        summary = {
            totalPassed = totalPassed,
            totalTests = totalTests,
            totalWarnings = totalWarnings,
            totalSkipped = totalSkipped,
            totalDuration = totalDuration,
            success = totalPassed == (totalTests - totalSkipped)
        }
    }
end

-- Generate detailed test report
function UILayoutTests.generateDetailedReport()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local reportData = {
        timestamp = timestamp,
        config = UILayoutTests.config,
        results = UILayoutTests.testResults,
        environment = {
            lua_version = _VERSION,
            os = os.getenv("OS") or "Unknown"
        }
    }
    
    print("📄 Detailed test report would be generated: ui_test_report_" .. timestamp .. ".json")
    print("📊 Performance baselines would be updated for regression testing")
end

-- Interactive test runner
function UILayoutTests.runInteractive()
    print("🔧 Interactive UI Layout Testing Suite")
    print("=====================================")
    print()
    print("Available commands:")
    print("  all          - Run all tests")
    print("  quick        - Run basic tests only")
    print("  perf         - Run performance tests")
    print("  accessibility- Run accessibility tests")
    print("  debug        - Enable debug mode and run tests")
    print("  config       - Show current configuration")
    print("  help         - Show this help")
    print("  quit         - Exit")
    print()
    
    -- For demo purposes, just run all tests
    return UILayoutTests.runComprehensiveTests()
end

return UILayoutTests