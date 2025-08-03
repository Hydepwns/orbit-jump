-- Font test for Monaspace Argon fonts
local Utils = require("src.utils.utils")
local fonts = {
    regular = nil,
    bold = nil,
    light = nil,
    extraBold = nil
}
function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    -- Load Monaspace Argon fonts
    fonts.regular = love.graphics.newFont("assets/fonts/MonaspaceArgon-Regular.otf", 16)
    fonts.bold = love.graphics.newFont("assets/fonts/MonaspaceArgon-Bold.otf", 16)
    fonts.light = love.graphics.newFont("assets/fonts/MonaspaceArgon-Light.otf", 16)
    fonts.extraBold = love.graphics.newFont("assets/fonts/MonaspaceArgon-ExtraBold.otf", 24)
    Utils.Logger.info("Fonts loaded successfully!")
    Utils.Logger.info("Regular font: %s", tostring(fonts.regular))
    Utils.Logger.info("Bold font: %s", tostring(fonts.bold))
    Utils.Logger.info("Light font: %s", tostring(fonts.light))
    Utils.Logger.info("ExtraBold font: %s", tostring(fonts.extraBold))
end
function love.draw()
    local y = 50
    -- Test Regular font
    love.graphics.setFont(fonts.regular)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Monaspace Argon Regular - Orbit Jump Game", 50, y)
    y = y + 40
    -- Test Bold font
    love.graphics.setFont(fonts.bold)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("Monaspace Argon Bold - Score Display", 50, y)
    y = y + 40
    -- Test Light font
    love.graphics.setFont(fonts.light)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Monaspace Argon Light - UI Hints", 50, y)
    y = y + 40
    -- Test ExtraBold font
    love.graphics.setFont(fonts.extraBold)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print("Monaspace Argon ExtraBold - Game Over", 50, y)
    y = y + 60
    -- Test different sizes
    love.graphics.setFont(fonts.regular)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Font test completed successfully!", 50, y)
    love.graphics.print("Press ESC to exit", 50, y + 30)
end
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end