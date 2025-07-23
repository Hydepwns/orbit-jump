-- Test Coverage Tracker for Orbit Jump
-- Monitors test coverage across all modules

local TestCoverage = {}

-- Function counts per module (approximate based on code analysis)
TestCoverage.functions = {
    game_logic = 12,
    game_state = 8,
    ring_system = 15,
    progression_system = 20,
    achievement_system = 10,
    upgrade_system = 12,
    cosmic_events = 18,
    warp_zones = 16,
    world_generator = 8,
    planet_lore = 12,
    ui_system = 14,
    renderer = 12,
    sound_manager = 8,
    sound_generator = 6,
    performance_monitor = 10,
    camera = 6,
    utils = 25,
    config = 8,
    blockchain_integration = 12,
    dev_tools = 15
}

-- Currently tested functions (will be updated as we add tests)
TestCoverage.tested = {
    game_logic = 10,      -- Good coverage already
    game_state = 5,       -- Partial coverage
    ring_system = 0,      -- No tests yet
    progression_system = 20,  -- Now has comprehensive tests
    achievement_system = 10,  -- Now has comprehensive tests
    upgrade_system = 0,
    cosmic_events = 0,
    warp_zones = 0,
    world_generator = 8,  -- Now has comprehensive tests
    planet_lore = 0,
    ui_system = 14,       -- Now has comprehensive tests
    renderer = 0,
    sound_manager = 0,
    sound_generator = 0,
    performance_monitor = 0,
    camera = 0,
    utils = 0,
    config = 0,
    blockchain_integration = 0,
    dev_tools = 0
}

function TestCoverage.calculateCoverage()
    local total = 0
    local tested = 0
    
    for module, count in pairs(TestCoverage.functions) do
        total = total + count
        tested = tested + (TestCoverage.tested[module] or 0)
    end
    
    return (tested / total) * 100
end

function TestCoverage.getModuleCoverage(moduleName)
    local total = TestCoverage.functions[moduleName] or 0
    local tested = TestCoverage.tested[moduleName] or 0
    
    if total == 0 then return 0 end
    return (tested / total) * 100
end

function TestCoverage.generateReport()
    print("\n" .. string.rep("=", 60))
    print("TEST COVERAGE REPORT")
    print(string.rep("=", 60))
    
    local totalCoverage = TestCoverage.calculateCoverage()
    print(string.format("Overall Coverage: %.1f%%", totalCoverage))
    print()
    
    print("Module Coverage:")
    for module, count in pairs(TestCoverage.functions) do
        local coverage = TestCoverage.getModuleCoverage(module)
        local status = coverage >= 80 and "✅" or coverage >= 50 and "⚠️" or "❌"
        print(string.format("  %s %s: %.1f%% (%d/%d)", 
            status, module, coverage, TestCoverage.tested[module] or 0, count))
    end
    
    print("\nPriority for testing:")
    local priorities = {}
    for module, count in pairs(TestCoverage.functions) do
        local coverage = TestCoverage.getModuleCoverage(module)
        if coverage < 50 then
            table.insert(priorities, {module = module, coverage = coverage, count = count})
        end
    end
    
    table.sort(priorities, function(a, b) return a.coverage < b.coverage end)
    
    for i, priority in ipairs(priorities) do
        if i <= 5 then
            print(string.format("  %d. %s (%.1f%%)", i, priority.module, priority.coverage))
        end
    end
    
    print(string.rep("=", 60))
end

function TestCoverage.updateModule(moduleName, testedCount)
    TestCoverage.tested[moduleName] = testedCount
end

return TestCoverage 