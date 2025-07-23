-- Renderer module for Orbit Jump
-- Centralizes all drawing operations for consistency

local Utils = require("src.utils.utils")
local Camera = Utils.require("src.core.camera")
local Renderer = {}

-- Font cache
Renderer.fonts = {}

function Renderer.init(fonts)
    Renderer.fonts = fonts
end

function Renderer.drawBackground()
    -- Draw parallax stars background
    local camX, camY = 0, 0
    if Renderer.camera then
        camX, camY = Renderer.camera.x, Renderer.camera.y
    end
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Layer 1: Distant stars (slow parallax)
    Utils.setColor(Utils.colors.white, 0.2)
    for i = 1, 100 do
        local baseX = (i * 173) % 2000 - 1000
        local baseY = (i * 237) % 2000 - 1000
        local x = baseX - (camX * 0.1) % 2000
        local y = baseY - (camY * 0.1) % 2000
        
        -- Wrap around screen
        x = ((x + 1000) % 2000) - 1000 + screenWidth/2
        y = ((y + 1000) % 2000) - 1000 + screenHeight/2
        
        if x > -10 and x < screenWidth + 10 and y > -10 and y < screenHeight + 10 then
            love.graphics.circle("fill", x, y, 0.5)
        end
    end
    
    -- Layer 2: Medium stars (medium parallax)
    Utils.setColor(Utils.colors.white, 0.3)
    for i = 1, 50 do
        local baseX = (i * 73) % 1500 - 750
        local baseY = (i * 137) % 1500 - 750
        local x = baseX - (camX * 0.3) % 1500
        local y = baseY - (camY * 0.3) % 1500
        
        -- Wrap around screen
        x = ((x + 750) % 1500) - 750 + screenWidth/2
        y = ((y + 750) % 1500) - 750 + screenHeight/2
        
        if x > -10 and x < screenWidth + 10 and y > -10 and y < screenHeight + 10 then
            love.graphics.circle("fill", x, y, 1)
        end
    end
    
    -- Layer 3: Close stars (fast parallax)
    Utils.setColor(Utils.colors.white, 0.4)
    for i = 1, 25 do
        local baseX = (i * 97) % 1000 - 500
        local baseY = (i * 193) % 1000 - 500
        local x = baseX - (camX * 0.5) % 1000
        local y = baseY - (camY * 0.5) % 1000
        
        -- Wrap around screen
        x = ((x + 500) % 1000) - 500 + screenWidth/2
        y = ((y + 500) % 1000) - 500 + screenHeight/2
        
        if x > -10 and x < screenWidth + 10 and y > -10 and y < screenHeight + 10 then
            love.graphics.circle("fill", x, y, 1.5)
        end
    end
end

function Renderer.drawPlayer(player, isDashing)
    -- Draw shield effect if active
    if player.hasShield then
        local shieldPulse = math.sin(love.timer.getTime() * 3) * 0.1 + 1
        Utils.setColor({0.2, 1, 0.2}, 0.3)
        love.graphics.circle("fill", player.x, player.y, player.radius * 2 * shieldPulse)
        Utils.setColor({0.2, 1, 0.2}, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", player.x, player.y, player.radius * 2 * shieldPulse)
    end
    
    -- Draw player
    if isDashing then
        Utils.drawCircle(player.x, player.y, player.radius * 1.2, Utils.colors.playerDashing)
    else
        Utils.drawCircle(player.x, player.y, player.radius, Utils.colors.player)
    end
end

function Renderer.drawPlayerTrail(trail)
    for i, point in ipairs(trail) do
        if point.isDashing then
            Utils.setColor(Utils.colors.playerDashing, point.life * 0.6)
            love.graphics.circle("fill", point.x, point.y, 8 * point.life * 0.8)
        else
            Utils.setColor(Utils.colors.white, point.life * 0.3)
            love.graphics.circle("fill", point.x, point.y, 5 * point.life * 0.5)
        end
    end
end

function Renderer.drawDashCooldown(player, cooldown, maxCooldown)
    if cooldown > 0 and not player.onPlanet then
        Utils.setColor(Utils.colors.gray, 0.5)
        love.graphics.arc("line", "open", player.x, player.y, player.radius + 5, 
            0, math.pi * 2 * (1 - cooldown / maxCooldown))
    end
end

function Renderer.drawPlanets(planets)
    for i, planet in ipairs(planets) do
        -- Use planet's own color or default
        local planetColor = planet.color or Utils.colors["planet" .. i] or Utils.colors.planet1
        
        -- Different appearance for discovered vs undiscovered planets
        if planet.discovered then
            Utils.drawCircle(planet.x, planet.y, planet.radius, planetColor)
        else
            -- Undiscovered planets are dimmer
            local dimColor = {planetColor[1] * 0.5, planetColor[2] * 0.5, planetColor[3] * 0.5}
            Utils.drawCircle(planet.x, planet.y, planet.radius, dimColor)
            
            -- Add mysterious glow
            Utils.setColor(Utils.colors.white, 0.1)
            love.graphics.circle("line", planet.x, planet.y, planet.radius + 10)
        end
        
        -- Draw rotation indicator
        Utils.setColor(Utils.colors.white, 0.3)
        love.graphics.setLineWidth(2)
        local indicatorAngle = love.timer.getTime() * planet.rotationSpeed
        local ix = planet.x + math.cos(indicatorAngle) * planet.radius * 0.8
        local iy = planet.y + math.sin(indicatorAngle) * planet.radius * 0.8
        love.graphics.line(planet.x, planet.y, ix, iy)
        
        -- Planet type indicator
        if planet.type and planet.discovered then
            love.graphics.setFont(Renderer.fonts.light or love.graphics.getFont())
            if planet.type == "ice" then
                Utils.setColor({0.6, 0.8, 1}, 0.8)
                love.graphics.print("ICE", planet.x - 10, planet.y - 10)
            elseif planet.type == "lava" then
                Utils.setColor({1, 0.4, 0.2}, 0.8)
                love.graphics.print("LAVA", planet.x - 15, planet.y - 10)
            elseif planet.type == "tech" then
                Utils.setColor({0.2, 1, 0.8}, 0.8)
                love.graphics.print("TECH", planet.x - 15, planet.y - 10)
            elseif planet.type == "void" then
                Utils.setColor({0.7, 0.3, 1}, 0.8)
                love.graphics.print("VOID", planet.x - 15, planet.y - 10)
            elseif planet.type == "quantum" then
                -- Quantum planets have shifting colors
                local time = love.timer.getTime()
                local r = 0.5 + math.sin(time * 2) * 0.5
                local g = 0.5 + math.sin(time * 2 + 2) * 0.5
                local b = 0.5 + math.sin(time * 2 + 4) * 0.5
                Utils.setColor({r, g, b}, 0.9)
                love.graphics.print("QUANTUM", planet.x - 25, planet.y - 10)
                
                -- Draw quantum distortion effect
                love.graphics.setLineWidth(2)
                for i = 1, 3 do
                    local phase = time * 3 + i * 2
                    local radius = planet.radius + math.sin(phase) * 10
                    Utils.setColor({r, g, b}, 0.3 - i * 0.1)
                    love.graphics.circle("line", planet.x, planet.y, radius)
                end
            end
        end
    end
end

function Renderer.drawRings(rings)
    local RingSystem = Utils.require("src.systems.ring_system")
    
    for _, ring in ipairs(rings) do
        if not ring.collected and (ring.visible == nil or ring.visible) then
            local pulse = math.sin(ring.pulsePhase) * 0.1 + 1
            local alpha = ring.color[4] or 0.8
            
            -- Special visual effects for different ring types
            if ring.type == "power_shield" then
                -- Shield rings have a protective aura
                Utils.setColor({ring.color[1], ring.color[2], ring.color[3]}, alpha * 0.3)
                love.graphics.circle("fill", ring.x, ring.y, ring.radius * 1.5 * pulse)
            elseif ring.type == "power_magnet" then
                -- Magnet rings have a pulsing field
                local magnetPulse = math.sin(love.timer.getTime() * 4) * 0.2 + 1
                Utils.setColor({ring.color[1], ring.color[2], ring.color[3]}, alpha * 0.2)
                love.graphics.circle("line", ring.x, ring.y, ring.radius * 2 * magnetPulse)
            elseif ring.type == "power_slowmo" then
                -- Slowmo rings have time distortion effect
                for j = 1, 3 do
                    local timePulse = math.sin(ring.pulsePhase + j * 0.5) * 0.1 + 1
                    Utils.setColor({ring.color[1], ring.color[2], ring.color[3]}, alpha * (0.3 / j))
                    love.graphics.circle("line", ring.x, ring.y, ring.radius * (1 + j * 0.3) * timePulse)
                end
            elseif ring.type == "power_multijump" then
                -- Multi-jump rings have bouncing particles
                local bounceY = math.abs(math.sin(love.timer.getTime() * 3)) * 10
                Utils.setColor({ring.color[1], ring.color[2], ring.color[3]}, alpha * 0.5)
                love.graphics.circle("fill", ring.x, ring.y - bounceY, 5)
                love.graphics.circle("fill", ring.x - 15, ring.y - bounceY * 0.7, 4)
                love.graphics.circle("fill", ring.x + 15, ring.y - bounceY * 0.7, 4)
            elseif ring.type == "warp" then
                -- Warp rings have swirling portal effect
                local warpRotation = love.timer.getTime() * 5
                Utils.setColor({ring.color[1], ring.color[2], ring.color[3]}, alpha * 0.4)
                love.graphics.push()
                love.graphics.translate(ring.x, ring.y)
                love.graphics.rotate(warpRotation)
                for j = 1, 6 do
                    local angle = (j / 6) * math.pi * 2
                    local spiralRadius = ring.radius * 0.7
                    local px = math.cos(angle) * spiralRadius
                    local py = math.sin(angle) * spiralRadius
                    love.graphics.circle("fill", px, py, 8)
                end
                love.graphics.pop()
            elseif ring.type == "chain" then
                -- Chain rings show their sequence number
                if ring.chainNumber then
                    love.graphics.setFont(Renderer.fonts.bold or love.graphics.getFont())
                    Utils.setColor(Utils.colors.white, 0.9)
                    love.graphics.printf(tostring(ring.chainNumber), ring.x - 10, ring.y - 8, 20, "center")
                end
            end
            
            -- Draw the main ring
            Utils.setColor(ring.color, alpha)
            love.graphics.setLineWidth(3)
            
            -- Draw rotating ring segments
            local segments = 8
            for i = 1, segments do
                local angle1 = (i-1) / segments * math.pi * 2 + ring.rotation
                local angle2 = i / segments * math.pi * 2 + ring.rotation
                local gap = 0.1
                
                love.graphics.arc("line", "open", ring.x, ring.y, ring.radius * pulse, 
                    angle1 + gap, angle2 - gap)
                love.graphics.arc("line", "open", ring.x, ring.y, ring.innerRadius * pulse, 
                    angle1 + gap, angle2 - gap)
            end
            
            -- Special inner glow for warp rings
            if ring.type == "warp" then
                Utils.setColor({ring.color[1], ring.color[2], ring.color[3]}, alpha * 0.6)
                love.graphics.circle("fill", ring.x, ring.y, ring.innerRadius * 0.8 * pulse)
            end
        end
    end
    
    -- Draw active power indicators
    local screenHeight = love.graphics.getHeight()
    local indicatorY = screenHeight - 100
    local indicatorX = 10
    
    if RingSystem.isActive("shield") then
        Utils.setColor({0.2, 1, 0.2}, 0.8)
        love.graphics.print("SHIELD ACTIVE", indicatorX, indicatorY)
        indicatorY = indicatorY - 25
    end
    
    if RingSystem.isActive("magnet") then
        Utils.setColor({1, 0.2, 1}, 0.8)
        love.graphics.print("MAGNET ACTIVE", indicatorX, indicatorY)
        indicatorY = indicatorY - 25
    end
    
    if RingSystem.isActive("slowmo") then
        Utils.setColor({0.2, 0.8, 1}, 0.8)
        love.graphics.print("SLOWMO ACTIVE", indicatorX, indicatorY)
        indicatorY = indicatorY - 25
    end
    
    if RingSystem.isActive("multijump") then
        local GameState = Utils.require("src.core.game_state")
        local player = GameState.player
        if player and player.extraJumps and player.extraJumps > 0 then
            Utils.setColor({1, 1, 0.2}, 0.8)
            love.graphics.print("JUMPS: " .. player.extraJumps, indicatorX, indicatorY)
            indicatorY = indicatorY - 25
        end
    end
end

function Renderer.drawParticles(particles)
    if #particles == 0 then return end
    
    -- Group particles by color for batching
    local particleGroups = {}
    for _, p in ipairs(particles) do
        local colorKey = string.format("%.2f,%.2f,%.2f", 
            p.color[1] or 1, 
            p.color[2] or 1, 
            p.color[3] or 1
        )
        if not particleGroups[colorKey] then
            particleGroups[colorKey] = {}
        end
        table.insert(particleGroups[colorKey], p)
    end
    
    -- Draw each group with its color (reduces state changes)
    for colorKey, group in pairs(particleGroups) do
        -- Parse color from key
        local r, g, b = colorKey:match("([^,]+),([^,]+),([^,]+)")
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        
        -- Draw all particles of this color together
        for _, p in ipairs(group) do
            local alpha = p.lifetime / p.maxLifetime
            Utils.setColor({r, g, b}, alpha)
            love.graphics.circle("fill", p.x, p.y, p.size * alpha)
        end
    end
end

function Renderer.drawPullIndicator(player, mouseX, mouseY, mouseStartX, mouseStartY, pullPower, maxPullDistance)
    if not player.onPlanet then return end
    
    -- Draw pull line (from player to mouse)
    Utils.setColor(Utils.colors.white, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.line(player.x, player.y, mouseX, mouseY)
    
    -- Power indicator at mouse position
    local powerPercent = pullPower / maxPullDistance
    Utils.setColor(Utils.colors.red, powerPercent)
    love.graphics.circle("fill", mouseX, mouseY, 5 + powerPercent * 10)
    
    -- Draw jump direction indicator (opposite of pull)
    if pullPower > 0 then
        local swipeX = mouseX - mouseStartX
        local swipeY = mouseY - mouseStartY
        local swipeDistance = Utils.vectorLength(swipeX, swipeY)
        
        if swipeDistance > 0 then
            local jumpDirectionX = -swipeX / swipeDistance
            local jumpDirectionY = -swipeY / swipeDistance
            
            -- Draw jump direction arrow
            Utils.setColor(Utils.colors.green, 0.8)
            love.graphics.setLineWidth(4)
            local arrowLength = 30 + powerPercent * 20
            local arrowEndX = player.x + jumpDirectionX * arrowLength
            local arrowEndY = player.y + jumpDirectionY * arrowLength
            love.graphics.line(player.x, player.y, arrowEndX, arrowEndY)
            
            -- Draw arrowhead
            local arrowheadSize = 8
            local perpX = -jumpDirectionY
            local perpY = jumpDirectionX
            love.graphics.line(arrowEndX, arrowEndY, 
                arrowEndX - jumpDirectionX * arrowheadSize + perpX * arrowheadSize * 0.5,
                arrowEndY - jumpDirectionY * arrowheadSize + perpY * arrowheadSize * 0.5)
            love.graphics.line(arrowEndX, arrowEndY, 
                arrowEndX - jumpDirectionX * arrowheadSize - perpX * arrowheadSize * 0.5,
                arrowEndY - jumpDirectionY * arrowheadSize - perpY * arrowheadSize * 0.5)
        end
    end
end

-- Mobile on-screen controls
function Renderer.drawMobileControls(player, fonts)
    -- Utils is already available from the top of the file
    local isMobile = Utils.MobileInput.isMobile()
    
    if not isMobile then return end
    
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Draw dash button (bottom right)
    local dashBtnSize = 80
    local dashBtnX = screenWidth - dashBtnSize - 20
    local dashBtnY = screenHeight - dashBtnSize - 20
    
    -- Check if dash is available
    local canDash = player.onPlanet == nil and player.dashCooldown <= 0 and not player.isDashing
    local dashAlpha = canDash and 0.8 or 0.3
    
    Utils.setColor(Utils.colors.dash, dashAlpha)
    love.graphics.circle("fill", dashBtnX + dashBtnSize/2, dashBtnY + dashBtnSize/2, dashBtnSize/2)
    
    -- Draw dash icon
    Utils.setColor(Utils.colors.white, dashAlpha)
    love.graphics.setFont(fonts.bold)
    love.graphics.printf("DASH", dashBtnX, dashBtnY + dashBtnSize/2 - 10, dashBtnSize, "center")
    
    -- Draw cooldown indicator
    if player.dashCooldown > 0 then
        local cooldownPercent = player.dashCooldown / 1.0
        Utils.setColor(Utils.colors.red, 0.5)
        love.graphics.arc("fill", dashBtnX + dashBtnSize/2, dashBtnY + dashBtnSize/2, 
                         dashBtnSize/2, -math.pi/2, -math.pi/2 + cooldownPercent * 2 * math.pi)
    end
    
    -- Draw pause button (top right)
    local pauseBtnSize = 50
    local pauseBtnX = screenWidth - pauseBtnSize - 20
    local pauseBtnY = 20
    
    Utils.setColor(Utils.colors.white, 0.6)
    love.graphics.rectangle("fill", pauseBtnX, pauseBtnY, pauseBtnSize, pauseBtnSize, 5)
    
    -- Draw pause icon
    Utils.setColor(Utils.colors.text, 0.8)
    love.graphics.setFont(fonts.bold)
    love.graphics.printf("II", pauseBtnX, pauseBtnY + pauseBtnSize/2 - 10, pauseBtnSize, "center")
    
    -- Draw touch area indicator when on planet
    if player.onPlanet then
        Utils.setColor(Utils.colors.white, 0.1)
        love.graphics.circle("fill", player.x, player.y, 100)
        Utils.setColor(Utils.colors.white, 0.3)
        love.graphics.circle("line", player.x, player.y, 100)
        
        -- Draw swipe hint
        Utils.setColor(Utils.colors.white, 0.5)
        love.graphics.setFont(fonts.light)
        love.graphics.printf("Swipe to jump", player.x - 50, player.y + 120, 100, "center")
    end
end

-- Enhanced pull indicator for mobile
function Renderer.drawMobilePullIndicator(player, mouseX, mouseY, mouseStartX, mouseStartY, pullPower, maxPullDistance)
    if not player.onPlanet then return end
    
    -- Utils is already available from the top of the file
    local isMobile = Utils.MobileInput.isMobile()
    
    if not isMobile then
        -- Use original pull indicator for desktop
        Renderer.drawPullIndicator(player, mouseX, mouseY, mouseStartX, mouseStartY, pullPower, maxPullDistance)
        return
    end
    
    -- Enhanced mobile pull indicator
    local powerPercent = pullPower / maxPullDistance
    
    -- Draw power ring around player
    Utils.setColor(Utils.colors.white, 0.3)
    love.graphics.circle("line", player.x, player.y, 50 + powerPercent * 50)
    
    -- Draw power meter
    local meterWidth = 200
    local meterHeight = 20
    local meterX = (love.graphics.getWidth() - meterWidth) / 2
    local meterY = love.graphics.getHeight() - 100
    
    -- Background
    Utils.setColor(Utils.colors.white, 0.2)
    love.graphics.rectangle("fill", meterX, meterY, meterWidth, meterHeight, 10)
    
    -- Power fill
    Utils.setColor(Utils.colors.green, 0.8)
    love.graphics.rectangle("fill", meterX, meterY, meterWidth * powerPercent, meterHeight, 10)
    
    -- Border
    Utils.setColor(Utils.colors.white, 0.5)
    love.graphics.rectangle("line", meterX, meterY, meterWidth, meterHeight, 10)
    
    -- Power text
    love.graphics.setFont(Renderer.fonts.bold or love.graphics.getFont())
    Utils.setColor(Utils.colors.white, 0.8)
    love.graphics.printf("POWER: " .. math.floor(powerPercent * 100) .. "%", 
                        meterX, meterY - 25, meterWidth, "center")
    
    -- Draw direction arrow
    if pullPower > 0 then
        local swipeX = mouseX - mouseStartX
        local swipeY = mouseY - mouseStartY
        local swipeDistance = Utils.vectorLength(swipeX, swipeY)
        
        if swipeDistance > 0 then
            local jumpDirectionX = -swipeX / swipeDistance
            local jumpDirectionY = -swipeY / swipeDistance
            
            -- Draw arrow from player
            Utils.setColor(Utils.colors.green, 0.8)
            love.graphics.setLineWidth(6)
            local arrowLength = 40 + powerPercent * 30
            local arrowEndX = player.x + jumpDirectionX * arrowLength
            local arrowEndY = player.y + jumpDirectionY * arrowLength
            love.graphics.line(player.x, player.y, arrowEndX, arrowEndY)
            
            -- Draw arrowhead
            local arrowheadSize = 12
            local perpX = -jumpDirectionY
            local perpY = jumpDirectionX
            love.graphics.line(arrowEndX, arrowEndY, 
                arrowEndX - jumpDirectionX * arrowheadSize + perpX * arrowheadSize * 0.5,
                arrowEndY - jumpDirectionY * arrowheadSize + perpY * arrowheadSize * 0.5)
            love.graphics.line(arrowEndX, arrowEndY, 
                arrowEndX - jumpDirectionX * arrowheadSize - perpX * arrowheadSize * 0.5,
                arrowEndY - jumpDirectionY * arrowheadSize - perpY * arrowheadSize * 0.5)
        end
    end
end

function Renderer.drawUI(score, combo, comboTimer, speedBoost, fonts)
    -- Draw score
    Utils.setColor(Utils.colors.text)
    love.graphics.setFont(fonts.bold)
    love.graphics.print("Score: " .. Utils.formatNumber(score), 10, 160)
    
    -- Draw combo
    if combo > 0 then
        local comboAlpha = math.min(comboTimer / 3.0, 1)
        Utils.setColor(Utils.colors.combo, comboAlpha)
        love.graphics.setFont(fonts.bold)
        love.graphics.print("Combo x" .. combo, 10, 185)
        love.graphics.setFont(fonts.regular)
        love.graphics.print("Speed x" .. string.format("%.1f", speedBoost), 10, 210)
    end
end

function Renderer.drawControlsHint(player, fonts)
    love.graphics.setFont(fonts.light)
    Utils.setColor(Utils.colors.white, 0.5)
    
    local hints = {}
    if player.onPlanet then
        table.insert(hints, "Pull back and release to jump")
    else
        table.insert(hints, "Shift/Z/X: Dash")
    end
    
    -- Add other controls
    table.insert(hints, "TAB: Map")
    table.insert(hints, "U: Upgrades")
    table.insert(hints, "L: Lore")
    
    -- Check if warp drive is unlocked
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    if UpgradeSystem.upgrades.warp_drive.currentLevel > 0 then
        table.insert(hints, "W: Warp")
    end
    
    table.insert(hints, "F5: Save")
    
    local hintText = table.concat(hints, " | ")
    love.graphics.printf(hintText, 0, love.graphics.getHeight() - 30, love.graphics.getWidth(), "center")
end

function Renderer.drawGameOver(score, fonts)
    love.graphics.setFont(fonts.extraBold)
    Utils.setColor(Utils.colors.gameOver)
    love.graphics.printf("GAME OVER", 0, love.graphics.getHeight()/2 - 50, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(fonts.bold)
    Utils.setColor(Utils.colors.text)
    love.graphics.printf("Score: " .. Utils.formatNumber(score), 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(fonts.regular)
    love.graphics.printf("Click or Press Space to Restart", 0, love.graphics.getHeight()/2 + 50, love.graphics.getWidth(), "center")
end

function Renderer.drawSoundStatus(enabled, fonts)
    if not enabled then
        love.graphics.setFont(fonts.light)
        Utils.setColor(Utils.colors.white, 0.5)
        love.graphics.print("Sound: OFF (Press M to toggle)", 10, love.graphics.getHeight() - 20)
    end
end

function Renderer.drawExplorationIndicator(player, Camera)
    -- Draw distance from origin
    local distFromOrigin = math.sqrt(player.x^2 + player.y^2)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Distance indicator
    Utils.setColor(Utils.colors.white, 0.7)
    love.graphics.setFont(Renderer.fonts.bold or love.graphics.getFont())
    love.graphics.print(string.format("Distance: %.0f", distFromOrigin), screenWidth - 150, 10)
    
    -- Zoom indicator
    love.graphics.setFont(Renderer.fonts.light or love.graphics.getFont())
    if Renderer.camera then
        love.graphics.print(string.format("Zoom: %.1fx", Renderer.camera.scale), screenWidth - 150, 35)
    end
    
    -- Danger warning if too far
    if distFromOrigin > 2000 then
        local pulse = math.sin(love.timer.getTime() * 4) * 0.5 + 0.5
        Utils.setColor({1, 0.3, 0.3}, pulse)
        love.graphics.setFont(Renderer.fonts.bold or love.graphics.getFont())
        love.graphics.printf("WARNING: ENTERING THE VOID", 0, 100, screenWidth, "center")
    end
end

function Renderer.drawButton(text, x, y, width, height, isHovered)
    Utils.drawButton(text, x, y, width, height, nil, nil, isHovered)
end

function Renderer.drawProgressBar(x, y, width, height, progress)
    Utils.drawProgressBar(x, y, width, height, progress)
end

function Renderer.drawText(text, x, y, font, color, align)
    if font then
        love.graphics.setFont(font)
    end
    if color then
        Utils.setColor(color)
    end
    if align then
        love.graphics.printf(text, x, y, love.graphics.getWidth(), align)
    else
        love.graphics.print(text, x, y)
    end
end

function Renderer.drawCenteredText(text, y, font, color)
    Renderer.drawText(text, 0, y, font, color, "center")
end

function Renderer.drawPanel(x, y, width, height, color)
    Utils.setColor(color or Utils.colors.background)
    love.graphics.rectangle("fill", x, y, width, height)
end

return Renderer 