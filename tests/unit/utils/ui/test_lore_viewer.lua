-- Comprehensive tests for Lore Viewer
local Utils = require("src.utils.utils")
local TestFramework = require("tests.modern_test_framework")
local Mocks = require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Mock ArtifactSystem
local mockArtifacts = {
  {
    id = 1,
    name = "Crystal of Origins",
    lore =
    "This ancient crystal holds the secrets of the universe's creation. It pulses with primordial energy that predates the stars themselves.",
    discovered = true,
    requiresAll = false,
    hint = "Found near the center of the galaxy"
  },
  {
    id = 2,
    name = "Void Compass",
    lore =
    "A mysterious device that points to dimensions beyond our understanding. Its needle spins eternally, seeking paths through the cosmic void.",
    discovered = true,
    requiresAll = false,
    hint = "Hidden in the darkest regions of space"
  },
  {
    id = 3,
    name = "Stellar Codex",
    lore =
    "Written in a language of light and mathematics, this codex contains the fundamental laws that govern stellar evolution and death.",
    discovered = false,
    requiresAll = false,
    hint = "Seek where stars are born"
  },
  {
    id = 4,
    name = "Final Truth",
    lore =
    "The ultimate artifact that reveals the purpose of existence itself. It can only be understood when all other truths have been gathered.",
    discovered = false,
    requiresAll = true,
    hint = "Collect all other artifacts first"
  }
}
local mockArtifactSystem = {
  artifacts = mockArtifacts,
  collectedCount = 2
}
-- Set up mock globally at module level
Utils.moduleCache = Utils.moduleCache or {}
Utils.moduleCache["src.systems.artifact_system"] = mockArtifactSystem
package.loaded["src.systems.artifact_system"] = mockArtifactSystem
local LoreViewer = Utils.require("src.ui.lore_viewer")
-- Test suite
local tests = {
  ["test initialization"] = function()
    LoreViewer.init()
    TestFramework.assert.equal(false, LoreViewer.isVisible, "Should start invisible")
    TestFramework.assert.equal(0, LoreViewer.scrollY, "Scroll should start at 0")
    TestFramework.assert.equal(nil, LoreViewer.selectedArtifact, "No artifact should be selected")
    TestFramework.assert.equal(0, LoreViewer.fadeAlpha, "Fade alpha should start at 0")
  end,
  ["test toggle visibility"] = function()
    LoreViewer.init()
    -- Toggle on
    LoreViewer.toggle()
    TestFramework.assert.equal(true, LoreViewer.isVisible, "Should be visible after toggle")
    TestFramework.assert.equal(0, LoreViewer.scrollY, "Scroll should reset")
    TestFramework.assert.equal(nil, LoreViewer.selectedArtifact, "Selection should clear")
    -- Toggle off
    LoreViewer.toggle()
    TestFramework.assert.equal(false, LoreViewer.isVisible, "Should be invisible after second toggle")
  end,
  ["test open to specific artifact"] = function()
    LoreViewer.init()
    -- Set up mock directly in the module cache after LoreViewer is loaded
    Utils.moduleCache = Utils.moduleCache or {}
    Utils.moduleCache["src.systems.artifact_system"] = mockArtifactSystem
    package.loaded["src.systems.artifact_system"] = mockArtifactSystem
    LoreViewer.openToArtifact(2)
    TestFramework.assert.equal(true, LoreViewer.isVisible, "Should be visible")
    TestFramework.assert.equal(0, LoreViewer.scrollY, "Scroll should reset")
    TestFramework.assert.notNil(LoreViewer.selectedArtifact, "Should have artifact selected")
    TestFramework.assert.equal(2, LoreViewer.selectedArtifact.id, "Should select correct artifact")
    TestFramework.assert.equal("Void Compass", LoreViewer.selectedArtifact.name, "Should have correct artifact data")
  end,
  ["test open to non-existent artifact"] = function()
    LoreViewer.init()
    LoreViewer.openToArtifact(999)
    TestFramework.assert.equal(true, LoreViewer.isVisible, "Should still open viewer")
    TestFramework.assert.equal(nil, LoreViewer.selectedArtifact, "Should have no selection for invalid ID")
  end,
  ["test fade alpha update when visible"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.fadeAlpha = 0
    LoreViewer.update(0.1)
    TestFramework.assert.equal(0.5, LoreViewer.fadeAlpha, "Fade alpha should increase by dt * 5")
    -- Test max fade
    LoreViewer.fadeAlpha = 0.9
    LoreViewer.update(0.1)
    TestFramework.assert.equal(1, LoreViewer.fadeAlpha, "Fade alpha should cap at 1")
  end,
  ["test fade alpha update when invisible"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = false
    LoreViewer.fadeAlpha = 1
    LoreViewer.selectedArtifact = mockArtifacts[1]
    LoreViewer.update(0.1)
    TestFramework.assert.equal(0.5, LoreViewer.fadeAlpha, "Fade alpha should decrease by dt * 5")
    -- Test minimum fade
    LoreViewer.fadeAlpha = 0.05
    LoreViewer.update(0.1)
    TestFramework.assert.equal(0, LoreViewer.fadeAlpha, "Fade alpha should cap at 0")
    -- Test artifact clearing
    LoreViewer.selectedArtifact = mockArtifacts[1]
    LoreViewer.fadeAlpha = 0
    LoreViewer.update(0.1)
    TestFramework.assert.equal(nil, LoreViewer.selectedArtifact, "Should clear selection when fully faded")
  end,
  ["test keyboard input - escape closes"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    local handled = LoreViewer.keypressed("escape")
    TestFramework.assert.equal(true, handled, "Should handle escape key")
    TestFramework.assert.equal(false, LoreViewer.isVisible, "Should close on escape")
  end,
  ["test keyboard input - L closes"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    local handled = LoreViewer.keypressed("l")
    TestFramework.assert.equal(true, handled, "Should handle L key")
    TestFramework.assert.equal(false, LoreViewer.isVisible, "Should close on L")
  end,
  ["test keyboard input - up scrolls"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.scrollY = 100
    local handled = LoreViewer.keypressed("up")
    TestFramework.assert.equal(true, handled, "Should handle up key")
    -- Scroll amount is scrollSpeed * 0.016 = 300 * 0.016 = 4.8
    TestFramework.assert.equal(95.2, LoreViewer.scrollY, "Should scroll up by 4.8")
    -- Test minimum boundary
    LoreViewer.scrollY = 2
    LoreViewer.keypressed("up")
    TestFramework.assert.equal(0, LoreViewer.scrollY, "Should not scroll below 0")
  end,
  ["test keyboard input - down scrolls"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.scrollY = 0
    local handled = LoreViewer.keypressed("down")
    TestFramework.assert.equal(true, handled, "Should handle down key")
    -- Scroll amount is scrollSpeed * 0.016 = 300 * 0.016 = 4.8
    TestFramework.assert.equal(4.8, LoreViewer.scrollY, "Should scroll down by 4.8")
  end,
  ["test keyboard input - back button"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.selectedArtifact = mockArtifacts[1]
    local handled = LoreViewer.keypressed("left")
    TestFramework.assert.equal(true, handled, "Should handle left key")
    TestFramework.assert.equal(nil, LoreViewer.selectedArtifact, "Should clear selection")
    -- Test with backspace
    LoreViewer.selectedArtifact = mockArtifacts[1]
    handled = LoreViewer.keypressed("backspace")
    TestFramework.assert.equal(true, handled, "Should handle backspace key")
    TestFramework.assert.equal(nil, LoreViewer.selectedArtifact, "Should clear selection")
  end,
  ["test keyboard input ignored when invisible"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = false
    local handled = LoreViewer.keypressed("escape")
    TestFramework.assert.equal(false, handled, "Should not handle input when invisible")
  end,
  ["test mouse click outside closes viewer"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.fadeAlpha = 1
    -- Mock screen size
    love.graphics.getWidth = function() return 1024 end
    love.graphics.getHeight = function() return 768 end
    -- Click outside viewer area
    local handled = LoreViewer.mousepressed(10, 10, 1)
    TestFramework.assert.equal(true, handled, "Should handle mouse click")
    TestFramework.assert.equal(false, LoreViewer.isVisible, "Should close when clicking outside")
  end,
  ["test mouse click on artifact selects it"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.fadeAlpha = 1
    -- Set up mock directly in the module cache after LoreViewer is loaded
    Utils.moduleCache = Utils.moduleCache or {}
    Utils.moduleCache["src.systems.artifact_system"] = mockArtifactSystem
    package.loaded["src.systems.artifact_system"] = mockArtifactSystem
    -- Mock screen size
    love.graphics.getWidth = function() return 1024 end
    love.graphics.getHeight = function() return 768 end
    -- Calculate click position for first artifact
    local viewerX = (1024 - LoreViewer.width) / 2
    local viewerY = (768 - LoreViewer.height) / 2
    local clickX = viewerX + LoreViewer.width / 2
    local clickY = viewerY + 90 -- First artifact position
    local handled = LoreViewer.mousepressed(clickX, clickY, 1)
    TestFramework.assert.equal(true, handled, "Should handle mouse click")
    TestFramework.assert.notNil(LoreViewer.selectedArtifact, "Should select artifact")
    TestFramework.assert.equal(1, LoreViewer.selectedArtifact.id, "Should select first artifact")
  end,
  ["test mouse click on back button"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.fadeAlpha = 1
    LoreViewer.selectedArtifact = mockArtifacts[1]
    -- Mock screen size
    love.graphics.getWidth = function() return 1024 end
    love.graphics.getHeight = function() return 768 end
    -- Calculate back button position
    local viewerX = (1024 - LoreViewer.width) / 2
    local viewerY = (768 - LoreViewer.height) / 2
    local clickX = viewerX + 60 -- Middle of back button
    local clickY = viewerY + 35 -- Middle of back button
    local handled = LoreViewer.mousepressed(clickX, clickY, 1)
    TestFramework.assert.equal(true, handled, "Should handle mouse click")
    TestFramework.assert.equal(nil, LoreViewer.selectedArtifact, "Should clear selection")
  end,
  ["test mouse input ignored when not visible"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = false
    local handled = LoreViewer.mousepressed(100, 100, 1)
    TestFramework.assert.equal(false, handled, "Should not handle mouse when invisible")
  end,
  ["test mouse input ignored when fading"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.fadeAlpha = 0.3 -- Below threshold
    local handled = LoreViewer.mousepressed(100, 100, 1)
    TestFramework.assert.equal(false, handled, "Should not handle mouse when fade alpha is low")
  end,
  ["test mouse wheel scrolling"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    LoreViewer.scrollY = 100
    -- Scroll up (positive y reduces scrollY)
    local handled = LoreViewer.wheelmoved(0, 1)
    TestFramework.assert.equal(true, handled, "Should handle wheel input")
    TestFramework.assert.equal(50, LoreViewer.scrollY, "Should scroll up by 50 with positive Y")
    -- Scroll down (negative y increases scrollY)
    LoreViewer.scrollY = 100
    handled = LoreViewer.wheelmoved(0, -1)
    TestFramework.assert.equal(true, handled, "Should handle wheel input")
    TestFramework.assert.equal(150, LoreViewer.scrollY, "Should scroll down by 50 with negative Y")
    -- Test minimum scroll
    LoreViewer.scrollY = 30
    LoreViewer.wheelmoved(0, 1)
    TestFramework.assert.equal(0, LoreViewer.scrollY, "Should clamp to 0")
  end,
  ["test wheel input ignored when invisible"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = false
    local handled = LoreViewer.wheelmoved(0, 1)
    TestFramework.assert.equal(false, handled, "Should not handle wheel when invisible")
  end,
  ["test input blocking"] = function()
    LoreViewer.init()
    -- Not blocking when invisible
    LoreViewer.isVisible = false
    TestFramework.assert.equal(false, LoreViewer.isBlockingInput(), "Should not block when invisible")
    -- Not blocking when fade is low
    LoreViewer.isVisible = true
    LoreViewer.fadeAlpha = 0.3
    TestFramework.assert.equal(false, LoreViewer.isBlockingInput(), "Should not block when fade is low")
    -- Blocking when visible and faded in
    LoreViewer.fadeAlpha = 0.7
    TestFramework.assert.equal(true, LoreViewer.isBlockingInput(), "Should block when visible and faded in")
  end,
  ["test draw function executes without error"] = function()
    LoreViewer.init()
    -- Mock screen size
    love.graphics.getWidth = function() return 1024 end
    love.graphics.getHeight = function() return 768 end
    -- Mock font creation
    love.graphics.newFont = function(size)
      return {
        getHeight = function() return size or 16 end,
        getWrap = function(text, width) return text, 5 end
      }
    end
    -- Mock graphics functions
    love.graphics.getFont = function()
      return {
        getHeight = function() return 16 end,
        getWrap = function(text, width) return text, 5 end
      }
    end
    -- Mock additional graphics functions needed for drawing
    love.graphics.polygon = love.graphics.polygon or function() end
    love.graphics.push = love.graphics.push or function() end
    love.graphics.pop = love.graphics.pop or function() end
    love.graphics.translate = love.graphics.translate or function() end
    love.graphics.rotate = love.graphics.rotate or function() end
    -- Mock timer for animation
    love.timer = love.timer or {}
    love.timer.getTime = function() return 1.5 end
    -- Mock mouse position
    love.mouse = love.mouse or {}
    love.mouse.getPosition = function() return 500, 400 end
    -- Test draw with various states
    local success, err
    -- Test invisible (should not draw)
    LoreViewer.fadeAlpha = 0
    success, err = pcall(function() LoreViewer.draw() end)
    TestFramework.assert.equal(true, success, "Should not error when invisible")
    -- Test list view
    LoreViewer.fadeAlpha = 1
    LoreViewer.selectedArtifact = nil
    success, err = pcall(function() LoreViewer.draw() end)
    TestFramework.assert.equal(true, success, "Should draw list view without error: " .. tostring(err))
    -- Test detail view
    LoreViewer.selectedArtifact = mockArtifacts[1]
    success, err = pcall(function() LoreViewer.draw() end)
    TestFramework.assert.equal(true, success, "Should draw detail view without error: " .. tostring(err))
    -- Test with final artifact
    LoreViewer.selectedArtifact = mockArtifacts[4]
    success, err = pcall(function() LoreViewer.draw() end)
    TestFramework.assert.equal(true, success, "Should draw final artifact without error: " .. tostring(err))
  end,
  ["test scroll boundaries"] = function()
    LoreViewer.init()
    LoreViewer.isVisible = true
    -- Test scroll up boundary
    LoreViewer.scrollY = 3
    LoreViewer.keypressed("up")
    TestFramework.assert.equal(0, LoreViewer.scrollY, "Should clamp to 0")
    -- Test scroll down (no upper limit enforced)
    LoreViewer.scrollY = 0
    for i = 1, 10 do
      LoreViewer.keypressed("down")
    end
    -- Each press adds 4.8, so 10 presses = 48
    TestFramework.assert.approx(48.0, LoreViewer.scrollY, 0.01, "Should scroll down by 48")
  end
}
-- Run the test suite
local function run()
  return TestFramework.runTests(tests, "Lore Viewer Tests")
end
return { run = run }
