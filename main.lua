-- Orbit Jump - Entry Point
-- Check if we're running in test mode
local testMode = false
for _, arg in ipairs(love.arg or arg or {}) do
    if arg == "test" then
        testMode = true
        break
    end
end
if testMode then
    -- Run tests instead of game
    local TestRunner = require("tests.love2d_test_runner")
    function love.load()
        TestRunner.init()
    end
    -- TestRunner handles all callbacks
else
    -- Normal game mode
    local Game = require("src.core.game")
    function love.load()
        Game.init()
    end
    function love.update(dt)
        Game.update(dt)
    end
    function love.draw()
        Game.draw()
    end
    function love.keypressed(key)
        Game.handleKeyPress(key)
    end
    function love.mousepressed(x, y, button)
        Game.handleMousePress(x, y, button)
    end
    function love.mousemoved(x, y)
        Game.handleMouseMove(x, y)
    end
    function love.mousereleased(x, y, button)
        Game.handleMouseRelease(x, y, button)
    end
    function love.wheelmoved(x, y)
        Game.handleWheelMoved(x, y)
    end
    -- Touch event handlers for mobile devices
    function love.touchpressed(id, x, y, pressure)
        Game.handleTouchPressed(id, x, y, pressure)
    end
    function love.touchmoved(id, x, y, pressure)
        Game.handleTouchMoved(id, x, y, pressure)
    end
    function love.touchreleased(id, x, y, pressure)
        Game.handleTouchReleased(id, x, y, pressure)
    end
    function love.resize(w, h)
        -- Handle window resize
        if Game.resolutionManager then
            Game.resolutionManager.handleResize(w, h)
        end
    end
    function love.quit()
        Game.quit()
    end
end
