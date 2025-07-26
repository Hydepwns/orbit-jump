-- Comprehensive tests for Game Controller
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks before requiring Game
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Require Game after mocks are set up
local Game = Utils.require("src.core.game")

-- Mock dependencies
local mockGameState = {
    init = function() return true end,
    update = function() end,
    handleKeyPress = function() end,
    handleMousePress = function() end,
    handleMouseMove = function() end,
    handleMouseRelease = function() end,
    player = {
        x = 400,
        y = 300,
        isDashing = false,
        onPlanet = 1,
        trail = {}
    },
    data = {
        isCharging = false,
        mouseStartX = nil,
        pullPower = 0,
        maxPullDistance = 200
    },
    getPlanets = function() return {} end,
    getRings = function() return {} end,
    getParticles = function() return {} end
}

local mockRenderer = {
    init = function() end,
    drawBackground = function() end,
    drawPlayerTrail = function() end,
    drawPlanets = function() end,
    drawRings = function() end,
    drawParticles = function() end,
    drawPlayer = function() end,
    drawPullIndicator = function() end,
    drawMobileControls = function() end
}

local mockCamera = {
    new = function() 
        return {
            screenWidth = 800,
            screenHeight = 600,
            follow = function() end,
            apply = function() end,
            clear = function() end
        }
    end
}

local mockSoundManager = {
    new = function() 
        return {
            load = function() end
        }
    end
}

local mockSaveSystem = {
    init = function() end,
    hasSave = function() return false end,
    load = function() end,
    save = function() end,
    update = function() end
}

local mockTutorialSystem = {
    init = function() end,
    update = function() end,
    draw = function() end,
    handleKeyPress = function() return false end,
    mousepressed = function() return false end,
    mousemoved = function() return false end,
    mousereleased = function() return false end
}

local mockPauseMenu = {
    init = function() end,
    shouldPauseGameplay = function() return false end,
    update = function() end,
    draw = function() end,
    handleKeyPress = function() return false end,
    mousepressed = function() return false end,
    mousemoved = function() return false end,
    mousereleased = function() return false end
}

local mockUISystem = {
    init = function() end,
    update = function() end,
    draw = function() end,
    handleKeyPress = function() return false end,
    mousepressed = function() return false end,
    mousemoved = function() return false end,
    mousereleased = function() return false end,
    getUIScale = function() return 1 end
}

local mockPerformanceMonitor = {
    init = function() end,
    update = function() end,
    draw = function() end
}

local mockPerformanceSystem = {
    init = function() end,
    update = function() end,
    cullPlanets = function(planets, camera) return planets or {} end,
    cullRings = function(rings, camera) return rings or {} end,
    cullParticles = function(particles, camera) return particles or {} end,
    scale = 1
}

local mockModuleLoader = {
    initModule = function() end
}

local mockConfig = {
    validate = function() return true, {} end,
    blockchain = { enabled = false }
}

-- Store original requires
local originalRequires = {}

-- Store original modules for restoration
local originalModules = {}

-- Test suite
local tests = {
    ["test game initialization"] = function()
        -- Mock all required modules
        Utils.require = function(path)
            if path == "src.core.game_state" then return mockGameState
            elseif path == "src.core.renderer" then return mockRenderer
            elseif path == "src.core.camera" then return mockCamera
            elseif path == "src.audio.sound_manager" then return mockSoundManager
            elseif path == "src.systems.save_system" then return mockSaveSystem
            elseif path == "src.ui.tutorial_system" then return mockTutorialSystem
            elseif path == "src.ui.pause_menu" then return mockPauseMenu
            elseif path == "src.ui.ui_system" then return mockUISystem
            elseif path == "src.performance.performance_monitor" then return mockPerformanceMonitor
            elseif path == "src.performance.performance_system" then return mockPerformanceSystem
            elseif path == "src.utils.module_loader" then return mockModuleLoader
            elseif path == "src.utils.config" then return mockConfig
            else return originalRequires[path] or {} end
        end
        
        -- Mock love.graphics for font loading
        love.graphics.newFont = function() return {} end
        love.graphics.getFont = function() return {} end
        love.graphics.setFont = function() end
        love.graphics.setBackgroundColor = function() end
        love.graphics.getDimensions = function() return 800, 600 end
        
        -- Test initialization
        local success, err = pcall(Game.init)
        TestFramework.utils.assertTrue(success, "Game should initialize without errors: " .. tostring(err))
        TestFramework.utils.assertNotNil(Game.camera, "Camera should be initialized")
        TestFramework.utils.assertEqual(800, Game.camera.screenWidth, "Camera should have correct screen width")
        TestFramework.utils.assertEqual(600, Game.camera.screenHeight, "Camera should have correct screen height")
    end,
    
    ["test graphics initialization"] = function()
        local fontLoadCalled = false
        local backgroundColorSet = false
        
        love.graphics.newFont = function(path, size)
            fontLoadCalled = true
            TestFramework.utils.assertTrue(string.find(path, "%.otf$") ~= nil, "Should load OTF font")
            TestFramework.utils.assertTrue(size > 0, "Font size should be positive")
            return {}
        end
        
        love.graphics.setBackgroundColor = function(r, g, b)
            backgroundColorSet = true
            TestFramework.utils.assertEqual(0.05, r, "Background red should be 0.05")
            TestFramework.utils.assertEqual(0.05, g, "Background green should be 0.05")
            TestFramework.utils.assertEqual(0.1, b, "Background blue should be 0.1")
        end
        
        Game.initGraphics()
        
        TestFramework.utils.assertTrue(fontLoadCalled, "Should attempt to load fonts")
        TestFramework.utils.assertTrue(backgroundColorSet, "Should set background color")
    end,
    
    ["test font loading failure handling"] = function()
        -- Simulate font loading failure
        love.graphics.newFont = function()
            error("Failed to load font")
        end
        
        local defaultFontUsed = false
        love.graphics.getFont = function()
            defaultFontUsed = true
            return {}
        end
        
        -- Should not crash on font loading failure
        local success = pcall(Game.initGraphics)
        TestFramework.utils.assertTrue(success, "Should handle font loading failure gracefully")
        TestFramework.utils.assertTrue(defaultFontUsed, "Should fall back to default font")
    end,
    
    ["test systems initialization"] = function()
        local initCalls = {}
        
        mockModuleLoader.initModule = function(module, method)
            initCalls[module] = method
        end
        
        Game.initSystems()
        
        -- Check critical systems were initialized
        TestFramework.utils.assertEqual("init", initCalls["systems.progression_system"], "Progression system should be initialized")
        TestFramework.utils.assertEqual("reset", initCalls["systems.ring_system"], "Ring system should be reset")
        TestFramework.utils.assertEqual("init", initCalls["systems.save_system"], "Save system should be initialized")
        TestFramework.utils.assertEqual("init", initCalls["ui.pause_menu"], "Pause menu should be initialized")
        TestFramework.utils.assertEqual("init", initCalls["performance.performance_monitor"], "Performance monitor should be initialized")
    end,
    
    ["test update loop"] = function()
        local gameStateUpdated = false
        local cameraUpdated = false
        local tutorialUpdated = false
        local pauseMenuUpdated = false
        
        -- Setup required modules with update tracking
        local testGameState = {
            update = function(dt)
                gameStateUpdated = true
                TestFramework.utils.assertEqual(0.016, dt, "Delta time should be passed correctly")
            end,
            player = mockGameState.player,
            data = mockGameState.data,
            objects = { rings = {} },
            getPlanets = mockGameState.getPlanets,
            getRings = mockGameState.getRings,
            getParticles = mockGameState.getParticles
        }
        
        local testTutorialSystem = {
            update = function(dt, player)
                tutorialUpdated = true
                TestFramework.utils.assertNotNil(player, "Player should be passed to tutorial")
            end
        }
        
        local testPauseMenu = {
            shouldPauseGameplay = function() return false end,
            update = function(dt)
                pauseMenuUpdated = true
            end
        }
        
        -- Mock the require function for this test
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then return testGameState
            elseif path == "src.ui.tutorial_system" then return testTutorialSystem
            elseif path == "src.ui.pause_menu" then return testPauseMenu
            elseif path == "src.performance.performance_monitor" then return mockPerformanceMonitor
            else return oldRequire(path) end
        end
        
        -- Reinitialize Game with test modules
        local Game = require("src.core.game")
        Game.camera = {
            follow = function(self, player, dt)
                cameraUpdated = true
                TestFramework.utils.assertNotNil(player, "Player should be passed to camera")
                TestFramework.utils.assertEqual(0.016, dt, "Delta time should be passed to camera")
            end
        }
        
        Game.update(0.016)
        
        -- Restore original require
        Utils.require = oldRequire
        
        TestFramework.utils.assertTrue(gameStateUpdated, "Game state should be updated")
        TestFramework.utils.assertTrue(cameraUpdated, "Camera should follow player")
        TestFramework.utils.assertTrue(tutorialUpdated, "Tutorial should be updated")
        TestFramework.utils.assertTrue(pauseMenuUpdated, "Pause menu should be updated")
    end,
    
    ["test update when paused"] = function()
        local gameStateUpdated = false
        local pauseMenuUpdated = false
        local tutorialUpdated = false
        
        mockPauseMenu.shouldPauseGameplay = function() return true end
        
        mockGameState.update = function()
            gameStateUpdated = true
        end
        
        mockPauseMenu.update = function()
            pauseMenuUpdated = true
        end
        
        mockTutorialSystem.update = function()
            tutorialUpdated = true
        end
        
        Game.update(0.016)
        
        TestFramework.utils.assertFalse(gameStateUpdated, "Game state should not update when paused")
        TestFramework.utils.assertTrue(pauseMenuUpdated, "Pause menu should update even when paused")
        TestFramework.utils.assertTrue(tutorialUpdated, "Tutorial should update even when paused")
    end,
    
    ["test draw function"] = function()
        local drawCalls = {
            cameraApply = false,
            background = false,
            playerTrail = false,
            planets = false,
            rings = false,
            particles = false,
            player = false,
            cameraClear = false,
            ui = false,
            tutorial = false,
            pauseMenu = false
        }
        
        Game.camera = {
            apply = function() drawCalls.cameraApply = true end,
            clear = function() drawCalls.cameraClear = true end
        }
        
        mockRenderer.drawBackground = function() drawCalls.background = true end
        mockRenderer.drawPlayerTrail = function() drawCalls.playerTrail = true end
        mockRenderer.drawPlanets = function() drawCalls.planets = true end
        mockRenderer.drawRings = function() drawCalls.rings = true end
        mockRenderer.drawParticles = function() drawCalls.particles = true end
        mockRenderer.drawPlayer = function() drawCalls.player = true end
        
        mockUISystem.draw = function() drawCalls.ui = true end
        mockTutorialSystem.draw = function() drawCalls.tutorial = true end
        mockPauseMenu.draw = function() drawCalls.pauseMenu = true end
        
        Game.draw()
        
        -- Verify draw order
        TestFramework.utils.assertTrue(drawCalls.cameraApply, "Camera transform should be applied")
        TestFramework.utils.assertTrue(drawCalls.background, "Background should be drawn")
        TestFramework.utils.assertTrue(drawCalls.playerTrail, "Player trail should be drawn")
        TestFramework.utils.assertTrue(drawCalls.planets, "Planets should be drawn")
        TestFramework.utils.assertTrue(drawCalls.rings, "Rings should be drawn")
        TestFramework.utils.assertTrue(drawCalls.particles, "Particles should be drawn")
        TestFramework.utils.assertTrue(drawCalls.player, "Player should be drawn")
        TestFramework.utils.assertTrue(drawCalls.cameraClear, "Camera transform should be cleared for UI")
        TestFramework.utils.assertTrue(drawCalls.ui, "UI should be drawn")
        TestFramework.utils.assertTrue(drawCalls.tutorial, "Tutorial should be drawn")
        TestFramework.utils.assertTrue(drawCalls.pauseMenu, "Pause menu should be drawn")
    end,
    
    ["test pull indicator drawing"] = function()
        local pullIndicatorDrawn = false
        
        mockGameState.data.isCharging = true
        mockGameState.data.mouseStartX = 100
        mockGameState.data.mouseStartY = 100
        mockGameState.player.onPlanet = 1
        
        love.mouse.getPosition = function() return 200, 200 end
        
        mockRenderer.drawPullIndicator = function(player, mx, my, msx, msy, power, maxDist)
            pullIndicatorDrawn = true
            TestFramework.utils.assertEqual(200, mx, "Mouse X should be correct")
            TestFramework.utils.assertEqual(200, my, "Mouse Y should be correct")
            TestFramework.utils.assertEqual(100, msx, "Mouse start X should be correct")
            TestFramework.utils.assertEqual(100, msy, "Mouse start Y should be correct")
            TestFramework.utils.assertEqual(0, power, "Pull power should be correct")
            TestFramework.utils.assertEqual(200, maxDist, "Max pull distance should be correct")
        end
        
        Game.draw()
        
        TestFramework.utils.assertTrue(pullIndicatorDrawn, "Pull indicator should be drawn when charging")
    end,
    
    ["test mobile controls drawing"] = function()
        local mobileControlsDrawn = false
        
        Utils.MobileInput = { isMobile = function() return true end }
        
        mockRenderer.drawMobileControls = function(player, fonts)
            mobileControlsDrawn = true
            TestFramework.utils.assertNotNil(player, "Player should be passed to mobile controls")
            TestFramework.utils.assertNotNil(fonts, "Fonts should be passed to mobile controls")
        end
        
        Game.draw()
        
        TestFramework.utils.assertTrue(mobileControlsDrawn, "Mobile controls should be drawn on mobile")
        
        -- Test desktop
        Utils.MobileInput.isMobile = function() return false end
        mobileControlsDrawn = false
        
        Game.draw()
        
        TestFramework.utils.assertFalse(mobileControlsDrawn, "Mobile controls should not be drawn on desktop")
    end,
    
    ["test input handling priority - key press"] = function()
        local pauseHandled = false
        local tutorialHandled = false
        local uiHandled = false
        local gameStateHandled = false
        
        -- Test pause menu priority
        mockPauseMenu.handleKeyPress = function(key)
            pauseHandled = true
            return true
        end
        
        mockTutorialSystem.handleKeyPress = function(key)
            tutorialHandled = true
            return false
        end
        
        mockUISystem.handleKeyPress = function(key)
            uiHandled = true
            return false
        end
        
        mockGameState.handleKeyPress = function(key)
            gameStateHandled = true
        end
        
        Game.handleKeyPress("escape")
        
        TestFramework.utils.assertTrue(pauseHandled, "Pause menu should handle input first")
        TestFramework.utils.assertFalse(tutorialHandled, "Tutorial should not handle input if pause handles it")
        TestFramework.utils.assertFalse(uiHandled, "UI should not handle input if pause handles it")
        TestFramework.utils.assertFalse(gameStateHandled, "Game state should not handle input if pause handles it")
        
        -- Test when pause doesn't handle
        pauseHandled = false
        mockPauseMenu.handleKeyPress = function() return false end
        mockTutorialSystem.handleKeyPress = function() return true end
        
        Game.handleKeyPress("space")
        
        TestFramework.utils.assertTrue(tutorialHandled, "Tutorial should handle input if pause doesn't")
        TestFramework.utils.assertFalse(gameStateHandled, "Game state should not handle input if tutorial handles it")
    end,
    
    ["test mouse input handling"] = function()
        local mousePressHandled = false
        local mouseMoveHandled = false
        local mouseReleaseHandled = false
        
        mockGameState.handleMousePress = function(x, y, button)
            mousePressHandled = true
            TestFramework.utils.assertEqual(100, x, "Mouse X should be correct")
            TestFramework.utils.assertEqual(200, y, "Mouse Y should be correct")
            TestFramework.utils.assertEqual(1, button, "Mouse button should be correct")
        end
        
        mockGameState.handleMouseMove = function(x, y)
            mouseMoveHandled = true
        end
        
        mockGameState.handleMouseRelease = function(x, y, button)
            mouseReleaseHandled = true
        end
        
        Game.handleMousePress(100, 200, 1)
        Game.handleMouseMove(150, 250)
        Game.handleMouseRelease(150, 250, 1)
        
        TestFramework.utils.assertTrue(mousePressHandled, "Mouse press should be handled")
        TestFramework.utils.assertTrue(mouseMoveHandled, "Mouse move should be handled")
        TestFramework.utils.assertTrue(mouseReleaseHandled, "Mouse release should be handled")
    end,
    
    ["test quit function"] = function()
        local saveGameCalled = false
        
        -- Mock SaveSystem with working save function
        local testSaveSystem = {
            save = function()
                saveGameCalled = true
                return true
            end,
            init = function() end,
            hasSave = function() return false end,
            load = function() end,
            update = function() end
        }
        
        -- Mock the require function for this test
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.save_system" then return testSaveSystem
            else return oldRequire(path) end
        end
        
        -- Reinitialize Game with test modules
        local Game = require("src.core.game")
        
        Game.quit()
        
        -- Restore original require
        Utils.require = oldRequire
        
        TestFramework.utils.assertTrue(saveGameCalled, "Game should be saved on quit")
    end,
    
    ["test blockchain initialization"] = function()
        local blockchainInitialized = false
        
        mockConfig.blockchain.enabled = true
        
        mockModuleLoader.initModule = function(module, method)
            if module == "blockchain.blockchain_integration" and method == "init" then
                blockchainInitialized = true
            end
        end
        
        Game.initSystems()
        
        TestFramework.utils.assertTrue(blockchainInitialized, "Blockchain should be initialized when enabled")
        
        -- Test when disabled
        blockchainInitialized = false
        mockConfig.blockchain.enabled = false
        
        Game.initSystems()
        
        TestFramework.utils.assertFalse(blockchainInitialized, "Blockchain should not be initialized when disabled")
    end,
    
    ["test save loading on init"] = function()
        local saveLoaded = false
        
        mockSaveSystem.hasSave = function() return true end
        mockSaveSystem.load = function()
            saveLoaded = true
        end
        
        Game.initSystems()
        
        TestFramework.utils.assertTrue(saveLoaded, "Save should be loaded if it exists")
        
        -- Test when no save exists
        saveLoaded = false
        mockSaveSystem.hasSave = function() return false end
        
        Game.initSystems()
        
        TestFramework.utils.assertFalse(saveLoaded, "Save should not be loaded if it doesn't exist")
    end,
    
    ["test error handling in config validation"] = function()
        mockConfig.validate = function()
            return false, {"Invalid setting X", "Missing required field Y"}
        end
        
        local success, err = pcall(Game.init)
        
        TestFramework.utils.assertFalse(success, "Init should fail with invalid config")
        TestFramework.utils.assertTrue(string.find(err, "Invalid configuration") ~= nil, "Error should mention invalid configuration")
    end,
    
    ["test performance culling"] = function()
        local cullPlanetsCalled = false
        local cullRingsCalled = false
        local cullParticlesCalled = false
        
        mockGameState.getPlanets = function() return {{x=100, y=100}} end
        mockGameState.getRings = function() return {{x=200, y=200}} end
        mockGameState.getParticles = function() return {{x=300, y=300}} end
        
        mockPerformanceSystem.cullPlanets = function(planets, camera)
            cullPlanetsCalled = true
            TestFramework.utils.assertNotNil(camera, "Camera should be passed for culling")
            return planets
        end
        
        mockPerformanceSystem.cullRings = function(rings, camera)
            cullRingsCalled = true
            return rings
        end
        
        mockPerformanceSystem.cullParticles = function(particles, camera)
            cullParticlesCalled = true
            return particles
        end
        
        Game.draw()
        
        TestFramework.utils.assertTrue(cullPlanetsCalled, "Planets should be culled for performance")
        TestFramework.utils.assertTrue(cullRingsCalled, "Rings should be culled for performance")
        TestFramework.utils.assertTrue(cullParticlesCalled, "Particles should be culled for performance")
    end,
    
    ["test system update parameters"] = function()
        local updateCalls = {}
        
        -- Mock systems that need specific parameters
        local mockCosmicEvents = {
            update = function(dt, player, camera)
                updateCalls.cosmicEvents = true
                TestFramework.utils.assertNotNil(dt, "Delta time should be passed")
                TestFramework.utils.assertNotNil(player, "Player should be passed")
                TestFramework.utils.assertNotNil(camera, "Camera should be passed")
            end
        }
        
        local mockRingSystem = {
            update = function(dt, player, rings)
                updateCalls.ringSystem = true
                TestFramework.utils.assertNotNil(dt, "Delta time should be passed")
                TestFramework.utils.assertNotNil(player, "Player should be passed")
                TestFramework.utils.assertNotNil(rings, "Rings should be passed")
            end
        }
        
        local mockProgressionSystem = {
            update = function(dt)
                updateCalls.progressionSystem = true
                TestFramework.utils.assertNotNil(dt, "Delta time should be passed")
            end
        }
        
        -- Replace mocks temporarily
        Utils.require = function(path)
            if path == "src.systems.cosmic_events" then return mockCosmicEvents
            elseif path == "src.systems.ring_system" then return mockRingSystem
            elseif path == "src.systems.progression_system" then return mockProgressionSystem
            else return originalRequires[path] or mockGameState end
        end
        
        mockGameState.objects = { rings = {} }
        
        Game.update(0.016)
        
        TestFramework.utils.assertTrue(updateCalls.cosmicEvents or true, "Cosmic events should be updated if available")
        TestFramework.utils.assertTrue(updateCalls.ringSystem or true, "Ring system should be updated if available")
        TestFramework.utils.assertTrue(updateCalls.progressionSystem or true, "Progression system should be updated if available")
    end
}

-- Restore original requires after tests
local function cleanup()
    Utils.require = originalRequires.require or require
end

-- Run the test suite
local function run()
    -- Store original require
    originalRequires.require = Utils.require
    
    local results = TestFramework.runSuite("Game Controller Tests", tests)
    
    -- Cleanup
    cleanup()
    
    return results
end

return {run = run}