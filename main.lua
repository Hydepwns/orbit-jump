-- Orbit Jump - Entry Point
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

function love.quit()
  Game.quit()
end
