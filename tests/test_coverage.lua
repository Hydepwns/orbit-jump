-- Test Coverage Tracker for Orbit Jump
-- Monitors test coverage across all modules

local Utils = require("src.utils.utils")

local TestCoverage = {}

-- Function counts per module (approximate based on code analysis)
TestCoverage.functions = {
    game = 12,            -- Main game controller
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
    performance_system = 14,
    camera = 6,
    utils = 25,
    config = 8,
    blockchain_integration = 12,
    dev_tools = 15,
    save_system = 10,     -- Save system
    player_system = 15,   -- Player system
    artifact_system = 12, -- Artifact system
    warp_drive = 8,       -- Warp drive
    map_system = 10,      -- Map system
    ring_constellations = 8,  -- Ring constellations
    lore_viewer = 11,     -- Lore viewer UI
    tutorial_system = 14, -- Tutorial system
    settings_menu = 14,   -- Settings menu
    pause_menu = 10       -- Pause menu
}

-- Currently tested functions (will be updated as we add tests)
TestCoverage.tested = {
    game = 9,             -- Game controller tests added
    game_logic = 10,      -- Good coverage already
    game_state = 5,       -- Partial coverage
    ring_system = 0,      -- No tests yet
    progression_system = 20,  -- Now has comprehensive tests
    achievement_system = 10,  -- Now has comprehensive tests
    upgrade_system = 0,
    cosmic_events = 0,
    warp_zones = 0,
    world_generator = 8,  -- Now has comprehensive tests
    planet_lore = 12,      -- Full coverage achieved!
    ui_system = 14,       -- Now has comprehensive tests
    renderer = 12,       -- Full coverage achieved!
    sound_manager = 8,    -- Full coverage achieved!
    sound_generator = 6,  -- Full coverage achieved!
    performance_monitor = 10, -- Full coverage achieved!
    performance_system = 14, -- Full coverage achieved!
    camera = 6,            -- Full coverage achieved!
    utils = 25,           -- Full coverage achieved!
    config = 0,
    blockchain_integration = 0,
    dev_tools = 0,
    save_system = 10,     -- Full coverage achieved!
    player_system = 15,   -- Full coverage achieved!
    artifact_system = 12, -- Full coverage achieved!
    warp_drive = 8,       -- Full coverage achieved!
    map_system = 10,     -- Full coverage achieved!
    ring_constellations = 8,  -- Full coverage achieved!
    lore_viewer = 11,     -- Full coverage achieved!
    tutorial_system = 14, -- Full coverage achieved!
    settings_menu = 14,   -- Full coverage achieved!
    pause_menu = 10,      -- Full coverage achieved!
    config = 8            -- Full coverage achieved!
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
    Utils.Logger.info("\n" .. string.rep("=", 60))
    Utils.Logger.info("TEST COVERAGE REPORT")
    Utils.Logger.info(string.rep("=", 60))
    
    local totalCoverage = TestCoverage.calculateCoverage()
    Utils.Logger.info("Overall Coverage: %.1f%%", totalCoverage)
    Utils.Logger.info("")
    
    Utils.Logger.info("Module Coverage:")
    for module, count in pairs(TestCoverage.functions) do
        local coverage = TestCoverage.getModuleCoverage(module)
        local status = coverage >= 80 and "✅" or coverage >= 50 and "⚠️" or "❌"
        Utils.Logger.info("  %s %s: %.1f%% (%d/%d)", 
            status, module, coverage, TestCoverage.tested[module] or 0, count)
    end
    
    Utils.Logger.info("\nPriority for testing:")
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
            Utils.Logger.info("  %d. %s (%.1f%%)", i, priority.module, priority.coverage)
        end
    end
    
    Utils.Logger.info(string.rep("=", 60))
end

function TestCoverage.updateModule(moduleName, testedCount)
    TestCoverage.tested[moduleName] = testedCount
end

return TestCoverage 