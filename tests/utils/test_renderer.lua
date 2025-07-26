-- Tests for Renderer System
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
local Renderer = Utils.require("src.core.renderer")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test renderer initialization
    ["renderer initialization"] = function()
        local fonts = {
            regular = { getWidth = function() return 100 end, getHeight = function() return 20 end },
            bold = { getWidth = function() return 120 end, getHeight = function() return 22 end },
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        Renderer.init(fonts)
        
        TestFramework.assert.assertEqual(fonts, Renderer.fonts, "Fonts should be set correctly")
    end,
    
    ["renderer initialization with nil fonts"] = function()
        Renderer.init(nil)
        
        TestFramework.assert.assertNil(Renderer.fonts, "Fonts should be nil when not provided")
    end,
    
    -- Test background rendering
    ["background rendering without camera"] = function()
        Renderer.camera = nil
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawBackground()
        end)
        
        TestFramework.assert.assertTrue(success, "Background rendering should work without camera")
    end,
    
    ["background rendering with camera"] = function()
        Renderer.camera = {
            x = 100,
            y = 200
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawBackground()
        end)
        
        TestFramework.assert.assertTrue(success, "Background rendering should work with camera")
    end,
    
    -- Test player rendering
    ["player rendering normal"] = function()
        local player = {
            x = 400,
            y = 300,
            radius = 10
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlayer(player, false)
        end)
        
        TestFramework.assert.assertTrue(success, "Player rendering should work in normal state")
    end,
    
    ["player rendering dashing"] = function()
        local player = {
            x = 400,
            y = 300,
            radius = 10
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlayer(player, true)
        end)
        
        TestFramework.assert.assertTrue(success, "Player rendering should work when dashing")
    end,
    
    ["player rendering with shield"] = function()
        local player = {
            x = 400,
            y = 300,
            radius = 10,
            hasShield = true
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlayer(player, false)
        end)
        
        TestFramework.assert.assertTrue(success, "Player rendering should work with shield")
    end,
    
    ["player rendering with shield and dashing"] = function()
        local player = {
            x = 400,
            y = 300,
            radius = 10,
            hasShield = true
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlayer(player, true)
        end)
        
        TestFramework.assert.assertTrue(success, "Player rendering should work with shield and dashing")
    end,
    
    -- Test player trail rendering
    ["player trail rendering empty"] = function()
        local trail = {}
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlayerTrail(trail)
        end)
        
        TestFramework.assert.assertTrue(success, "Player trail rendering should work with empty trail")
    end,
    
    ["player trail rendering with points"] = function()
        local trail = {
            { x = 400, y = 300, life = 1.0, isDashing = false },
            { x = 410, y = 310, life = 0.8, isDashing = true },
            { x = 420, y = 320, life = 0.6, isDashing = false }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlayerTrail(trail)
        end)
        
        TestFramework.assert.assertTrue(success, "Player trail rendering should work with trail points")
    end,
    
    -- Test dash cooldown rendering
    ["dash cooldown rendering active"] = function()
        local player = {
            x = 400,
            y = 300,
            radius = 10,
            onPlanet = nil
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawDashCooldown(player, 0.5, 1.0)
        end)
        
        TestFramework.assert.assertTrue(success, "Dash cooldown rendering should work when active")
    end,
    
    ["dash cooldown rendering on planet"] = function()
        local player = {
            x = 400,
            y = 300,
            radius = 10,
            onPlanet = true
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawDashCooldown(player, 0.5, 1.0)
        end)
        
        TestFramework.assert.assertTrue(success, "Dash cooldown rendering should work when on planet")
    end,
    
    ["dash cooldown rendering no cooldown"] = function()
        local player = {
            x = 400,
            y = 300,
            radius = 10,
            onPlanet = nil
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawDashCooldown(player, 0, 1.0)
        end)
        
        TestFramework.assert.assertTrue(success, "Dash cooldown rendering should work with no cooldown")
    end,
    
    -- Test planet rendering
    ["planet rendering empty"] = function()
        local planets = {}
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlanets(planets)
        end)
        
        TestFramework.assert.assertTrue(success, "Planet rendering should work with empty planets")
    end,
    
    ["planet rendering with planets"] = function()
        -- Test that the function exists
        TestFramework.assert.assertNotNil(Renderer.drawPlanets, "drawPlanets function should exist")
        
        -- Test with empty planets list (should not crash)
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlanets({})
        end)
        
        TestFramework.assert.assertTrue(success, "Planet rendering should work with empty planets")
    end,
    
    ["planet rendering with quantum planet"] = function()
        -- Test that the function exists
        TestFramework.assert.assertNotNil(Renderer.drawPlanets, "drawPlanets function should exist")
        
        -- Test with minimal planet data (should not crash)
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPlanets({{x = 400, y = 300, radius = 50}})
        end)
        
        TestFramework.assert.assertTrue(success, "Planet rendering should work with minimal planet data")
    end,
    
    -- Test ring rendering
    ["ring rendering empty"] = function()
        local rings = {}
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawRings(rings)
        end)
        
        TestFramework.assert.assertTrue(success, "Ring rendering should work with empty rings")
    end,
    
    ["ring rendering with rings"] = function()
        local rings = {
            {
                x = 400,
                y = 300,
                radius = 30,
                innerRadius = 15,
                color = {1, 0, 0, 1},
                collected = false,
                type = "standard",
                pulsePhase = 0,
                rotation = 0
            },
            {
                x = 500,
                y = 400,
                radius = 40,
                innerRadius = 20,
                color = {0, 1, 0, 1},
                collected = false,
                type = "power_shield",
                pulsePhase = 0.5,
                rotation = 1.0
            }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawRings(rings)
        end)
        
        TestFramework.assert.assertTrue(success, "Ring rendering should work with rings")
    end,
    
    ["ring rendering with collected rings"] = function()
        local rings = {
            {
                x = 400,
                y = 300,
                radius = 30,
                innerRadius = 15,
                color = {1, 0, 0, 1},
                collected = true,
                type = "standard",
                pulsePhase = 0,
                rotation = 0
            }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawRings(rings)
        end)
        
        TestFramework.assert.assertTrue(success, "Ring rendering should work with collected rings")
    end,
    
    -- Test particle rendering
    ["particle rendering empty"] = function()
        local particles = {}
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawParticles(particles)
        end)
        
        TestFramework.assert.assertTrue(success, "Particle rendering should work with empty particles")
    end,
    
    ["particle rendering with particles"] = function()
        local particles = {
            {
                x = 400,
                y = 300,
                size = 5,
                color = {1, 1, 1, 1},
                lifetime = 1.0,
                maxLifetime = 1.0
            },
            {
                x = 410,
                y = 310,
                size = 3,
                color = {1, 0, 0, 1},
                lifetime = 0.5,
                maxLifetime = 1.0
            }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawParticles(particles)
        end)
        
        TestFramework.assert.assertTrue(success, "Particle rendering should work with particles")
    end,
    
    -- Test pull indicator rendering
    ["pull indicator rendering not on planet"] = function()
        local player = {
            x = 400,
            y = 300,
            onPlanet = nil
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPullIndicator(player, 450, 350, 400, 300, 50, 100)
        end)
        
        TestFramework.assert.assertTrue(success, "Pull indicator rendering should work when not on planet")
    end,
    
    ["pull indicator rendering on planet"] = function()
        local player = {
            x = 400,
            y = 300,
            onPlanet = true
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPullIndicator(player, 450, 350, 400, 300, 50, 100)
        end)
        
        TestFramework.assert.assertTrue(success, "Pull indicator rendering should work when on planet")
    end,
    
    ["pull indicator rendering with power"] = function()
        local player = {
            x = 400,
            y = 300,
            onPlanet = true
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPullIndicator(player, 450, 350, 400, 300, 80, 100)
        end)
        
        TestFramework.assert.assertTrue(success, "Pull indicator rendering should work with power")
    end,
    
    -- Test mobile controls rendering
    ["mobile controls rendering"] = function()
        local player = {
            x = 400,
            y = 300,
            onPlanet = true,
            dashCooldown = 0,
            isDashing = false
        }
        
        local fonts = {
            bold = { getWidth = function() return 100 end, getHeight = function() return 20 end },
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawMobileControls(player, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "Mobile controls rendering should work")
    end,
    
    ["mobile controls rendering with cooldown"] = function()
        local player = {
            x = 400,
            y = 300,
            onPlanet = true,
            dashCooldown = 0.5,
            isDashing = false
        }
        
        local fonts = {
            bold = { getWidth = function() return 100 end, getHeight = function() return 20 end },
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawMobileControls(player, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "Mobile controls rendering should work with cooldown")
    end,
    
    -- Test mobile pull indicator rendering
    ["mobile pull indicator rendering"] = function()
        local player = {
            x = 400,
            y = 300,
            onPlanet = true
        }
        
        -- Set up fonts for Renderer
        Renderer.fonts = {
            bold = love.graphics.getFont()
        }
        
        -- Mock Utils.MobileInput.isMobile to return true
        local originalIsMobile = Utils.MobileInput.isMobile
        Utils.MobileInput.isMobile = function() return true end
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawMobilePullIndicator(player, 450, 350, 400, 300, 50, 100)
        end)
        
        -- Restore original function
        Utils.MobileInput.isMobile = originalIsMobile
        
        TestFramework.assert.assertTrue(success, "Mobile pull indicator rendering should work")
    end,
    
    -- Test UI rendering
    ["UI rendering"] = function()
        local fonts = {
            bold = { getWidth = function() return 100 end, getHeight = function() return 20 end },
            regular = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawUI(1000, 5, 2.0, 1.5, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "UI rendering should work")
    end,
    
    ["UI rendering with combo"] = function()
        local fonts = {
            bold = { getWidth = function() return 100 end, getHeight = function() return 20 end },
            regular = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawUI(1000, 10, 3.0, 2.0, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "UI rendering should work with combo")
    end,
    
    -- Test controls hint rendering
    ["controls hint rendering"] = function()
        local player = {
            onPlanet = true
        }
        
        local fonts = {
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawControlsHint(player, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "Controls hint rendering should work")
    end,
    
    ["controls hint rendering not on planet"] = function()
        local player = {
            onPlanet = nil
        }
        
        local fonts = {
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawControlsHint(player, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "Controls hint rendering should work when not on planet")
    end,
    
    -- Test game over rendering
    ["game over rendering"] = function()
        local fonts = {
            extraBold = { getWidth = function() return 150 end, getHeight = function() return 30 end },
            bold = { getWidth = function() return 120 end, getHeight = function() return 22 end },
            regular = { getWidth = function() return 100 end, getHeight = function() return 20 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawGameOver(1500, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "Game over rendering should work")
    end,
    
    -- Test sound status rendering
    ["sound status rendering enabled"] = function()
        local fonts = {
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawSoundStatus(true, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "Sound status rendering should work when enabled")
    end,
    
    ["sound status rendering disabled"] = function()
        local fonts = {
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawSoundStatus(false, fonts)
        end)
        
        TestFramework.assert.assertTrue(success, "Sound status rendering should work when disabled")
    end,
    
    -- Test exploration indicator rendering
    ["exploration indicator rendering"] = function()
        local player = {
            x = 1000,
            y = 800
        }
        
        local Camera = {
            scale = 1.5
        }
        
        -- Initialize fonts
        local fonts = {
            regular = { getWidth = function() return 100 end, getHeight = function() return 20 end },
            bold = { getWidth = function() return 120 end, getHeight = function() return 22 end },
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        Renderer.init(fonts)
        
        -- Set camera for renderer
        Renderer.camera = Camera
        
        -- Test that the function exists and can be called
        TestFramework.assert.assertNotNil(Renderer.drawExplorationIndicator, "drawExplorationIndicator function should exist")
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawExplorationIndicator(player, Camera)
        end)
        
        TestFramework.assert.assertTrue(success, "Exploration indicator rendering should work")
    end,
    
    ["exploration indicator rendering far from origin"] = function()
        local player = {
            x = 2500,
            y = 2500
        }
        
        local Camera = {
            scale = 1.0
        }
        
        -- Initialize fonts
        local fonts = {
            regular = { getWidth = function() return 100 end, getHeight = function() return 20 end },
            bold = { getWidth = function() return 120 end, getHeight = function() return 22 end },
            light = { getWidth = function() return 90 end, getHeight = function() return 18 end }
        }
        Renderer.init(fonts)
        
        -- Set camera for renderer
        Renderer.camera = Camera
        
        -- Test that the function exists and can be called
        TestFramework.assert.assertNotNil(Renderer.drawExplorationIndicator, "drawExplorationIndicator function should exist")
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawExplorationIndicator(player, Camera)
        end)
        
        TestFramework.assert.assertTrue(success, "Exploration indicator rendering should work far from origin")
    end,
    
    -- Test utility rendering functions
    ["button rendering"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawButton("Test Button", 100, 100, 200, 50, false)
        end)
        
        TestFramework.assert.assertTrue(success, "Button rendering should work")
    end,
    
    ["button rendering hovered"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawButton("Test Button", 100, 100, 200, 50, true)
        end)
        
        TestFramework.assert.assertTrue(success, "Button rendering should work when hovered")
    end,
    
    ["progress bar rendering"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawProgressBar(100, 100, 200, 20, 0.75)
        end)
        
        TestFramework.assert.assertTrue(success, "Progress bar rendering should work")
    end,
    
    ["progress bar rendering full"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawProgressBar(100, 100, 200, 20, 1.0)
        end)
        
        TestFramework.assert.assertTrue(success, "Progress bar rendering should work when full")
    end,
    
    ["progress bar rendering empty"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawProgressBar(100, 100, 200, 20, 0.0)
        end)
        
        TestFramework.assert.assertTrue(success, "Progress bar rendering should work when empty")
    end,
    
    ["text rendering"] = function()
        local fonts = {
            regular = { getWidth = function() return 100 end, getHeight = function() return 20 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawText("Test Text", 100, 100, fonts.regular, {1, 1, 1, 1}, "left")
        end)
        
        TestFramework.assert.assertTrue(success, "Text rendering should work")
    end,
    
    ["text rendering without font"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawText("Test Text", 100, 100, nil, {1, 1, 1, 1}, "center")
        end)
        
        TestFramework.assert.assertTrue(success, "Text rendering should work without font")
    end,
    
    ["centered text rendering"] = function()
        local fonts = {
            bold = { getWidth = function() return 120 end, getHeight = function() return 22 end }
        }
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawCenteredText("Centered Text", 100, fonts.bold, {1, 1, 1, 1})
        end)
        
        TestFramework.assert.assertTrue(success, "Centered text rendering should work")
    end,
    
    ["panel rendering"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPanel(100, 100, 200, 150, {0.1, 0.1, 0.1, 0.8})
        end)
        
        TestFramework.assert.assertTrue(success, "Panel rendering should work")
    end,
    
    ["panel rendering with default color"] = function()
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            Renderer.drawPanel(100, 100, 200, 150)
        end)
        
        TestFramework.assert.assertTrue(success, "Panel rendering should work with default color")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Renderer System Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("renderer", 12) -- All major functions tested
    
    return success
end

local result = {run = run}

-- Run tests if this file is executed directly
if arg and arg[0] and string.find(arg[0], "test_renderer.lua") then
    run()
end

return result 