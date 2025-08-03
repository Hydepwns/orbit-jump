-- Simple tests for Player System using working patterns
package.path = package.path .. ";../../../?.lua"
local Utils = require("src.utils.utils")
Utils.require("tests.busted")
-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
-- Mock dependencies
local mockGameLogic = {
    applyGravity = function(player, planets, dt) end,
    checkCollisions = function(player, planets) return nil end,
    isOutOfBounds = function(player) return false end
}
local mockTrail = {
    addPoint = function() end,
    update = function() end
}
local mockAnalytics = {
    recordJump = function() end,
    recordLanding = function() end,
    updateMovement = function() end
}
local mockParticleSystem = {
    createJumpEffect = function() end,
    createLandingEffect = function() end,
    burst = function() end,
    create = function() end
}
local mockSoundManager = {
    playJumpSound = function() end,
    playLandingSound = function() end,
    playDashSound = function() end,
    playSound = function() end
}
local mockCamera = {
    addShake = function() end,
    setTargetZoom = function() end
}
-- Mock Utils.require
local originalUtilsRequire = Utils.require
Utils.require = function(module)
    if module == "src.core.game_logic" then
        return mockGameLogic
    elseif module == "src.systems.trail" then
        return mockTrail
    elseif module == "src.systems.player_analytics" then
        return mockAnalytics
    elseif module == "src.systems.particle_system" then
        return mockParticleSystem
    elseif module == "src.audio.sound_manager" then
        return mockSoundManager
    elseif module == "src.core.camera" then
        return mockCamera
    elseif module == "src.core.constants" then
        return {
            WORLD_SIZE = 2000,
            PLAYER_RADIUS = 8,
            DASH_DISTANCE = 150
        }
    end
    return originalUtilsRequire(module)
end
-- Add direct assignment for global references
ParticleSystem = mockParticleSystem
SoundManager = mockSoundManager
-- Load systems
local PlayerMovement = require("src.systems.player.player_movement")
local PlayerAbilities = require("src.systems.player.player_abilities")
local PlayerState = require("src.systems.player.player_state")
local PlayerSystem = require("src.systems.player_system")
describe("Player System - Core Tests", function()
    local testPlayer
    before_each(function()
        -- Reset systems
        PlayerMovement.init()
        PlayerAbilities.init()
        PlayerState.init()
        PlayerSystem.init()
        -- Create test player object with all expected fields
        testPlayer = {
            x = 100, y = 100,
            vx = 0, vy = 0,
            landed = false,
            jumpCooldown = 0,
            dashCooldown = 0,
            health = 100,
            energy = 100,
            maxHealth = 100,
            maxEnergy = 100,
            powerUps = {},
            trail = {points = {}},
            landedPlanet = nil,
            lastPosition = {x = 100, y = 100},
            profile = {
                skillLevel = 0.5,
                preferences = {}
            }
        }
    end)
    describe("Module Loading", function()
        it("should load all player modules without errors", function()
            assert.is_type("table", PlayerMovement)
            assert.is_type("table", PlayerAbilities)
            assert.is_type("table", PlayerState)
            assert.is_type("table", PlayerSystem)
        end)
        it("should have required initialization functions", function()
            assert.is_type("function", PlayerMovement.init)
            assert.is_type("function", PlayerAbilities.init)
            assert.is_type("function", PlayerState.init)
            assert.is_type("function", PlayerSystem.init)
        end)
    end)
    describe("Player Movement Functions", function()
        it("should have movement functions", function()
            assert.is_type("function", PlayerMovement.updateMovement)
            assert.is_type("function", PlayerMovement.updateTrail)
            assert.is_type("function", PlayerMovement.checkBoundaries)
        end)
        it("should have prediction functions", function()
            assert.is_type("function", PlayerMovement.predictLandingPosition)
        end)
    end)
    describe("Player Abilities Functions", function()
        it("should have ability check functions", function()
            assert.is_type("function", PlayerAbilities.canJump)
            assert.is_type("function", PlayerAbilities.canDash)
        end)
        it("should have action functions", function()
            assert.is_type("function", PlayerAbilities.jump)
            assert.is_type("function", PlayerAbilities.dash)
        end)
        it("should have power-up functions", function()
            assert.is_type("function", PlayerAbilities.applyPowerUp)
            assert.is_type("function", PlayerAbilities.hasPowerUp)
        end)
    end)
    describe("Player State Functions", function()
        it("should have landing functions", function()
            assert.is_type("function", PlayerState.onPlanetLanding)
        end)
        it("should have stats functions", function()
            assert.is_type("function", PlayerState.updateSessionStats)
            assert.is_type("function", PlayerState.recordPlayerState)
        end)
        it("should have save/load functions", function()
            assert.is_type("function", PlayerState.savePlayerState)
            assert.is_type("function", PlayerState.loadPlayerState)
        end)
        it("should have profile functions", function()
            assert.is_type("function", PlayerState.getPlayerProfile)
        end)
    end)
    describe("Player System Facade Functions", function()
        it("should initialize without errors", function()
            local success = PlayerSystem.init()
            assert.is_true(success)
        end)
        it("should have core functions", function()
            assert.is_type("function", PlayerSystem.update)
            assert.is_type("function", PlayerSystem.jump)
            assert.is_type("function", PlayerSystem.dash)
        end)
        it("should have movement functions", function()
            assert.is_type("function", PlayerSystem.updateOnPlanet)
            assert.is_type("function", PlayerSystem.updateInSpace)
        end)
        it("should have detection functions", function()
            assert.is_type("function", PlayerSystem.detectEmergencyDash)
        end)
        it("should have landing functions", function()
            assert.is_type("function", PlayerSystem.onPlanetLanding)
        end)
    end)
end)