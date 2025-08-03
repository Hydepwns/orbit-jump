-- Test file for Constants
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Test suite
local tests = {
    ["test constants module structure"] = function()
        local Constants = Utils.require("src.utils.constants")
        TestFramework.assert.notNil(Constants, "Constants module should exist")
        TestFramework.assert.notNil(Constants.GAME, "GAME constants should exist")
        TestFramework.assert.notNil(Constants.UI, "UI constants should exist")
        TestFramework.assert.notNil(Constants.COLORS, "COLORS constants should exist")
        TestFramework.assert.notNil(Constants.PERFORMANCE, "PERFORMANCE constants should exist")
    end,
    ["test game constants values"] = function()
        local Constants = Utils.require("src.utils.constants")
        TestFramework.assert.equal(0, Constants.GAME.STARTING_SCORE, "STARTING_SCORE should be 0")
        TestFramework.assert.equal(100, Constants.GAME.MAX_COMBO, "MAX_COMBO should be 100")
        TestFramework.assert.equal(10, Constants.GAME.RING_VALUE, "RING_VALUE should be 10")
        TestFramework.assert.equal(300, Constants.GAME.JUMP_POWER, "JUMP_POWER should be 300")
        TestFramework.assert.equal(500, Constants.GAME.DASH_POWER, "DASH_POWER should be 500")
        TestFramework.assert.equal(15000, Constants.GAME.GRAVITY, "GRAVITY should be 15000")
        TestFramework.assert.equal(3.0, Constants.GAME.COMBO_TIMEOUT, "COMBO_TIMEOUT should be 3.0")
    end,
    ["test ui constants values"] = function()
        local Constants = Utils.require("src.utils.constants")
        TestFramework.assert.equal(16, Constants.UI.FONT_SIZE_REGULAR, "FONT_SIZE_REGULAR should be 16")
        TestFramework.assert.equal(16, Constants.UI.FONT_SIZE_BOLD, "FONT_SIZE_BOLD should be 16")
        TestFramework.assert.equal(16, Constants.UI.FONT_SIZE_LIGHT, "FONT_SIZE_LIGHT should be 16")
        TestFramework.assert.equal(24, Constants.UI.FONT_SIZE_EXTRA_BOLD, "FONT_SIZE_EXTRA_BOLD should be 24")
        TestFramework.assert.equal(150, Constants.UI.MAX_PULL_DISTANCE, "MAX_PULL_DISTANCE should be 150")
    end,
    ["test colors constants structure"] = function()
        local Constants = Utils.require("src.utils.constants")
        TestFramework.assert.notNil(Constants.COLORS.BACKGROUND, "BACKGROUND color should exist")
        TestFramework.assert.notNil(Constants.COLORS.WHITE, "WHITE color should exist")
        TestFramework.assert.notNil(Constants.COLORS.RED, "RED color should exist")
        TestFramework.assert.notNil(Constants.COLORS.GREEN, "GREEN color should exist")
        TestFramework.assert.notNil(Constants.COLORS.BLUE, "BLUE color should exist")
    end,
    ["test colors constants values"] = function()
        local Constants = Utils.require("src.utils.constants")
        -- Test BACKGROUND color
        TestFramework.assert.equal(0.05, Constants.COLORS.BACKGROUND[1], "BACKGROUND R should be 0.05")
        TestFramework.assert.equal(0.05, Constants.COLORS.BACKGROUND[2], "BACKGROUND G should be 0.05")
        TestFramework.assert.equal(0.1, Constants.COLORS.BACKGROUND[3], "BACKGROUND B should be 0.1")
        -- Test WHITE color
        TestFramework.assert.equal(1, Constants.COLORS.WHITE[1], "WHITE R should be 1")
        TestFramework.assert.equal(1, Constants.COLORS.WHITE[2], "WHITE G should be 1")
        TestFramework.assert.equal(1, Constants.COLORS.WHITE[3], "WHITE B should be 1")
        -- Test RED color
        TestFramework.assert.equal(1, Constants.COLORS.RED[1], "RED R should be 1")
        TestFramework.assert.equal(0, Constants.COLORS.RED[2], "RED G should be 0")
        TestFramework.assert.equal(0, Constants.COLORS.RED[3], "RED B should be 0")
        -- Test GREEN color
        TestFramework.assert.equal(0, Constants.COLORS.GREEN[1], "GREEN R should be 0")
        TestFramework.assert.equal(1, Constants.COLORS.GREEN[2], "GREEN G should be 1")
        TestFramework.assert.equal(0, Constants.COLORS.GREEN[3], "GREEN B should be 0")
        -- Test BLUE color
        TestFramework.assert.equal(0, Constants.COLORS.BLUE[1], "BLUE R should be 0")
        TestFramework.assert.equal(0, Constants.COLORS.BLUE[2], "BLUE G should be 0")
        TestFramework.assert.equal(1, Constants.COLORS.BLUE[3], "BLUE B should be 1")
    end,
    ["test performance constants values"] = function()
        local Constants = Utils.require("src.utils.constants")
        TestFramework.assert.equal(1000, Constants.PERFORMANCE.PARTICLE_LIMIT, "PARTICLE_LIMIT should be 1000")
        TestFramework.assert.equal(100, Constants.PERFORMANCE.SPATIAL_GRID_SIZE, "SPATIAL_GRID_SIZE should be 100")
        TestFramework.assert.equal(50, Constants.PERFORMANCE.OBJECT_POOL_SIZE, "OBJECT_POOL_SIZE should be 50")
    end,
    ["test constants type validation"] = function()
        local Constants = Utils.require("src.utils.constants")
        -- Test that all game constants are numbers
        for key, value in pairs(Constants.GAME) do
            TestFramework.assert.type("number", value, "GAME constant " .. key .. " should be a number")
        end
        -- Test that all UI constants are numbers
        for key, value in pairs(Constants.UI) do
            TestFramework.assert.type("number", value, "UI constant " .. key .. " should be a number")
        end
        -- Test that all performance constants are numbers
        for key, value in pairs(Constants.PERFORMANCE) do
            TestFramework.assert.type("number", value, "PERFORMANCE constant " .. key .. " should be a number")
        end
        -- Test that all color constants are tables
        for key, value in pairs(Constants.COLORS) do
            TestFramework.assert.type("table", value, "COLOR constant " .. key .. " should be a table")
        end
    end,
    ["test color constants have 3 components"] = function()
        local Constants = Utils.require("src.utils.constants")
        for colorName, colorValue in pairs(Constants.COLORS) do
            TestFramework.assert.equal(3, #colorValue, "Color " .. colorName .. " should have 3 components")
        end
    end,
    ["test color constants are in valid range"] = function()
        local Constants = Utils.require("src.utils.constants")
        for colorName, colorValue in pairs(Constants.COLORS) do
            for i, component in ipairs(colorValue) do
                TestFramework.assert.greaterThanOrEqual(0, component,
                    "Color " .. colorName .. " component " .. i .. " should be >= 0")
                TestFramework.assert.lessThanOrEqual(1, component,
                    "Color " .. colorName .. " component " .. i .. " should be <= 1")
            end
        end
    end,
    ["test game constants are positive"] = function()
        local Constants = Utils.require("src.utils.constants")
        local positiveConstants = {"MAX_COMBO", "RING_VALUE", "JUMP_POWER", "DASH_POWER", "GRAVITY", "COMBO_TIMEOUT"}
        for _, constantName in ipairs(positiveConstants) do
            TestFramework.assert.greaterThan(0, Constants.GAME[constantName],
                "GAME constant " .. constantName .. " should be positive")
        end
    end,
    ["test ui constants are positive"] = function()
        local Constants = Utils.require("src.utils.constants")
        for constantName, value in pairs(Constants.UI) do
            TestFramework.assert.greaterThan(0, value,
                "UI constant " .. constantName .. " should be positive")
        end
    end,
    ["test performance constants are positive"] = function()
        local Constants = Utils.require("src.utils.constants")
        for constantName, value in pairs(Constants.PERFORMANCE) do
            TestFramework.assert.greaterThan(0, value,
                "PERFORMANCE constant " .. constantName .. " should be positive")
        end
    end,
    ["test constants accessibility"] = function()
        local Constants = Utils.require("src.utils.constants")
        -- Test that constants can be accessed from different contexts
        local gameScore = Constants.GAME.STARTING_SCORE
        local uiFontSize = Constants.UI.FONT_SIZE_REGULAR
        local colorWhite = Constants.COLORS.WHITE
        local perfLimit = Constants.PERFORMANCE.PARTICLE_LIMIT
        TestFramework.assert.equal(0, gameScore, "Should access GAME constant")
        TestFramework.assert.equal(16, uiFontSize, "Should access UI constant")
        TestFramework.assert.equal(1, colorWhite[1], "Should access COLOR constant")
        TestFramework.assert.equal(1000, perfLimit, "Should access PERFORMANCE constant")
    end,
    ["test constants consistency"] = function()
        local Constants = Utils.require("src.utils.constants")
        -- Test that constants are consistent across multiple loads
        local Constants2 = Utils.require("src.utils.constants")
        TestFramework.assert.equal(Constants.GAME.STARTING_SCORE, Constants2.GAME.STARTING_SCORE,
            "Constants should be consistent across loads")
        TestFramework.assert.equal(Constants.UI.FONT_SIZE_REGULAR, Constants2.UI.FONT_SIZE_REGULAR,
            "Constants should be consistent across loads")
        TestFramework.assert.equal(Constants.COLORS.WHITE[1], Constants2.COLORS.WHITE[1],
            "Constants should be consistent across loads")
    end,
    ["test constants structure integrity"] = function()
        local Constants = Utils.require("src.utils.constants")
        -- Test that all expected constants exist
        local expectedGameConstants = {"STARTING_SCORE", "MAX_COMBO", "RING_VALUE", "JUMP_POWER", "DASH_POWER", "GRAVITY", "COMBO_TIMEOUT"}
        local expectedUIConstants = {"FONT_SIZE_REGULAR", "FONT_SIZE_BOLD", "FONT_SIZE_LIGHT", "FONT_SIZE_EXTRA_BOLD", "MAX_PULL_DISTANCE"}
        local expectedColorConstants = {"BACKGROUND", "WHITE", "RED", "GREEN", "BLUE"}
        local expectedPerformanceConstants = {"PARTICLE_LIMIT", "SPATIAL_GRID_SIZE", "OBJECT_POOL_SIZE"}
        for _, constantName in ipairs(expectedGameConstants) do
            TestFramework.assert.notNil(Constants.GAME[constantName],
                "Expected GAME constant " .. constantName .. " should exist")
        end
        for _, constantName in ipairs(expectedUIConstants) do
            TestFramework.assert.notNil(Constants.UI[constantName],
                "Expected UI constant " .. constantName .. " should exist")
        end
        for _, constantName in ipairs(expectedColorConstants) do
            TestFramework.assert.notNil(Constants.COLORS[constantName],
                "Expected COLOR constant " .. constantName .. " should exist")
        end
        for _, constantName in ipairs(expectedPerformanceConstants) do
            TestFramework.assert.notNil(Constants.PERFORMANCE[constantName],
                "Expected PERFORMANCE constant " .. constantName .. " should exist")
        end
    end
}
return tests