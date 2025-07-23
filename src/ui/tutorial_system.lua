-- Tutorial System for Orbit Jump
-- Guides new players through game mechanics

local Utils = Utils.Utils.require("src.utils.utils")
local TutorialSystem = {}

-- Tutorial state
TutorialSystem.isActive = false
TutorialSystem.currentStep = 1
TutorialSystem.stepTimer = 0
TutorialSystem.hasCompletedTutorial = false
TutorialSystem.fadeAlpha = 0
TutorialSystem.pulsePhase = 0

-- Tutorial steps
TutorialSystem.steps = {
    {
        id = "welcome",
        title = "Welcome to Orbit Jump!",
        text = "You're a space explorer jumping between planets.\nLet's learn the basics!",
        duration = 4,
        condition = function() return true end,
        highlight = nil
    },
    {
        id = "jump",
        title = "How to Jump",
        text = "Click and drag AWAY from where you want to go,\nthen release to jump!\nThe further you pull, the stronger your jump!",
        duration = 0, -- Wait for player action
        condition = function(player) 
            return player.onPlanet 
        end,
        action = "jump",
        highlight = "player",
        showPullIndicator = true
    },
    {
        id = "jump_success",
        title = "Great Jump!",
        text = "The further you pull, the stronger your jump.\nTry landing on another planet!",
        duration = 3,
        condition = function(player) 
            return not player.onPlanet 
        end,
        highlight = nil
    },
    {
        id = "dash",
        title = "Dashing in Space",
        text = "While in space, click to dash towards your mouse!\nYou can dash once per jump.",
        duration = 0,
        condition = function(player) 
            return not player.onPlanet 
        end,
        action = "dash",
        highlight = "player"
    },
    {
        id = "rings",
        title = "Collect Rings!",
        text = "Fly through rings to earn points.\nChain them together for combos!",
        duration = 5,
        condition = function() return true end,
        highlight = "rings"
    },
    {
        id = "exploration",
        title = "Explore the Galaxy",
        text = "New planets appear as you explore.\nEach planet type has unique properties!",
        duration = 4,
        condition = function() return true end,
        highlight = nil
    },
    {
        id = "map",
        title = "Use Your Map",
        text = "Press TAB to see your map.\nIt shows discovered and undiscovered planets!",
        duration = 0,
        condition = function() return true end,
        action = "map",
        highlight = nil
    },
    {
        id = "upgrades",
        title = "Upgrade Your Abilities",
        text = "Press U to open the upgrade shop.\nSpend points to improve your abilities!",
        duration = 4,
        condition = function() return true end,
        highlight = nil
    },
    {
        id = "complete",
        title = "You're Ready!",
        text = "Explore the infinite galaxy!\nDiscover secrets, collect artifacts, and have fun!",
        duration = 4,
        condition = function() return true end,
        highlight = nil
    }
}

-- Initialize tutorial
function TutorialSystem.init()
    -- Check if player has completed tutorial before
    local saveData = TutorialSystem.loadTutorialState()
    TutorialSystem.hasCompletedTutorial = saveData and saveData.completed or false
    
    if not TutorialSystem.hasCompletedTutorial then
        TutorialSystem.start()
    end
end

-- Start tutorial
function TutorialSystem.start()
    TutorialSystem.isActive = true
    TutorialSystem.currentStep = 1
    TutorialSystem.stepTimer = 0
    TutorialSystem.fadeAlpha = 0
    
    -- Give player some starting currency for tutorial
    local UpgradeSystem = Utils.Utils.require("src.systems.upgrade_system")
    if UpgradeSystem.currency < 100 then
        UpgradeSystem.currency = 100
    end
    
    Utils.Logger.info("Tutorial started")
end

-- Skip tutorial
function TutorialSystem.skip()
    TutorialSystem.isActive = false
    TutorialSystem.hasCompletedTutorial = true
    TutorialSystem.saveTutorialState()
    Utils.Logger.info("Tutorial skipped")
end

-- Complete tutorial
function TutorialSystem.complete()
    TutorialSystem.isActive = false
    TutorialSystem.hasCompletedTutorial = true
    TutorialSystem.saveTutorialState()
    
    -- Give completion bonus
    local GameState = Utils.Utils.require("src.core.game_state")
    local UpgradeSystem = Utils.Utils.require("src.systems.upgrade_system")
    GameState.addScore(100)
    UpgradeSystem.addCurrency(50)
    
    Utils.Logger.info("Tutorial completed!")
end

-- Update tutorial
function TutorialSystem.update(dt, player)
    if not TutorialSystem.isActive then return end
    
    -- Update visual effects
    TutorialSystem.pulsePhase = TutorialSystem.pulsePhase + dt * 3
    TutorialSystem.fadeAlpha = math.min(TutorialSystem.fadeAlpha + dt * 2, 1)
    
    local step = TutorialSystem.steps[TutorialSystem.currentStep]
    if not step then
        TutorialSystem.complete()
        return
    end
    
    -- Check if step condition is met
    if step.condition and not step.condition(player) then
        return
    end
    
    -- Update step timer
    if step.duration > 0 then
        TutorialSystem.stepTimer = TutorialSystem.stepTimer + dt
        
        if TutorialSystem.stepTimer >= step.duration then
            TutorialSystem.nextStep()
        end
    end
end

-- Check for player actions
function TutorialSystem.onPlayerAction(action)
    if not TutorialSystem.isActive then return end
    
    local step = TutorialSystem.steps[TutorialSystem.currentStep]
    if step and step.action == action then
        TutorialSystem.nextStep()
    end
end

-- Move to next step
function TutorialSystem.nextStep()
    TutorialSystem.currentStep = TutorialSystem.currentStep + 1
    TutorialSystem.stepTimer = 0
    TutorialSystem.fadeAlpha = 0
    
    if TutorialSystem.currentStep > #TutorialSystem.steps then
        TutorialSystem.complete()
    end
end

-- Draw tutorial UI
function TutorialSystem.draw(player, camera)
    if not TutorialSystem.isActive then return end
    
    local step = TutorialSystem.steps[TutorialSystem.currentStep]
    if not step then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw darkened overlay
    Utils.setColor({0, 0, 0}, 0.5 * TutorialSystem.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw highlights
    if step.highlight then
        local pulse = math.sin(TutorialSystem.pulsePhase) * 0.1 + 1
        
        if step.highlight == "player" and player then
            -- Highlight player
            local screenX, screenY = camera:worldToScreen(player.x, player.y)
            Utils.setColor({1, 1, 0}, 0.5 * TutorialSystem.fadeAlpha)
            love.graphics.circle("line", screenX, screenY, 50 * pulse)
            love.graphics.circle("line", screenX, screenY, 55 * pulse)
            
            -- Show pull direction hint for jump tutorial
            if step.showPullIndicator and player.onPlanet then
                Utils.setColor({1, 1, 0}, 0.3 * TutorialSystem.fadeAlpha)
                love.graphics.setLineWidth(4)
                -- Draw arrow pointing away from player
                local arrowDist = 100
                local arrowAngle = math.sin(TutorialSystem.pulsePhase) * 0.5
                local endX = screenX + math.cos(arrowAngle) * arrowDist
                local endY = screenY - math.sin(arrowAngle) * arrowDist - 50
                love.graphics.line(screenX, screenY, endX, endY)
                
                -- Arrow head
                local headSize = 15
                local headAngle1 = arrowAngle + 2.5
                local headAngle2 = arrowAngle - 2.5
                love.graphics.line(endX, endY, 
                    endX - math.cos(headAngle1) * headSize, 
                    endY + math.sin(headAngle1) * headSize)
                love.graphics.line(endX, endY, 
                    endX - math.cos(headAngle2) * headSize, 
                    endY + math.sin(headAngle2) * headSize)
                love.graphics.setLineWidth(1)
            end
            
        elseif step.highlight == "rings" then
            -- Highlight nearest ring
            local GameState = Utils.Utils.require("src.core.game_state")
            local rings = GameState.getRings()
            local nearestRing = nil
            local nearestDist = math.huge
            
            for _, ring in ipairs(rings) do
                if not ring.collected then
                    local dist = Utils.distance(player.x, player.y, ring.x, ring.y)
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestRing = ring
                    end
                end
            end
            
            if nearestRing then
                local ringX, ringY = camera:worldToScreen(nearestRing.x, nearestRing.y)
                Utils.setColor({1, 0.8, 0}, 0.6 * TutorialSystem.fadeAlpha)
                love.graphics.circle("line", ringX, ringY, nearestRing.radius + 10 * pulse)
                love.graphics.circle("line", ringX, ringY, nearestRing.radius + 15 * pulse)
            end
        end
    end
    
    -- Draw tutorial box
    local boxWidth = 600
    local boxHeight = 150
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = 100
    
    -- Box background
    Utils.setColor({0, 0, 0}, 0.8 * TutorialSystem.fadeAlpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10)
    
    -- Box border
    Utils.setColor({0.5, 0.8, 1}, TutorialSystem.fadeAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10)
    
    -- Title
    Utils.setColor({1, 1, 1}, TutorialSystem.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf(step.title, boxX, boxY + 20, boxWidth, "center")
    
    -- Text
    Utils.setColor({0.8, 0.8, 0.8}, TutorialSystem.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(step.text, boxX + 20, boxY + 60, boxWidth - 40, "center")
    
    -- Action hint
    if step.action then
        Utils.setColor({1, 1, 0}, TutorialSystem.fadeAlpha * (0.5 + math.sin(TutorialSystem.pulsePhase) * 0.5))
        love.graphics.setFont(love.graphics.newFont(14))
        
        local actionText = ""
        if step.action == "jump" then
            actionText = "Click and drag to jump!"
        elseif step.action == "dash" then
            actionText = "Press SHIFT/Z/X to dash!"
        elseif step.action == "map" then
            actionText = "Press TAB to open map!"
        end
        
        love.graphics.printf(actionText, boxX, boxY + boxHeight - 30, boxWidth, "center")
    end
    
    -- Skip hint
    Utils.setColor({0.5, 0.5, 0.5}, TutorialSystem.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("Press ENTER to skip tutorial", 10, screenHeight - 30, screenWidth - 20, "right")
    
    -- Progress dots
    local dotSize = 6
    local dotSpacing = 15
    local totalWidth = #TutorialSystem.steps * dotSpacing
    local startX = (screenWidth - totalWidth) / 2
    
    for i = 1, #TutorialSystem.steps do
        local x = startX + i * dotSpacing
        local y = boxY + boxHeight + 20
        
        if i < TutorialSystem.currentStep then
            Utils.setColor({0.5, 0.8, 1}, TutorialSystem.fadeAlpha)
            love.graphics.circle("fill", x, y, dotSize)
        elseif i == TutorialSystem.currentStep then
            Utils.setColor({1, 1, 1}, TutorialSystem.fadeAlpha)
            love.graphics.circle("fill", x, y, dotSize * 1.2)
        else
            Utils.setColor({0.3, 0.3, 0.3}, TutorialSystem.fadeAlpha)
            love.graphics.circle("line", x, y, dotSize)
        end
    end
end

-- Input handlers (return false to allow input to pass through)
function TutorialSystem.handleKeyPress(key)
    if not TutorialSystem.isActive then return false end
    
    -- Allow skipping tutorial with Enter
    if key == "return" then
        TutorialSystem.skip()
        return true
    end
    
    -- Check for map action
    if key == "tab" and TutorialSystem.steps[TutorialSystem.currentStep].action == "map" then
        TutorialSystem.onPlayerAction("map")
    end
    
    -- Let input pass through to game
    return false
end

function TutorialSystem.mousepressed(x, y, button)
    -- Always let mouse input pass through during tutorial
    return false
end

function TutorialSystem.mousemoved(x, y)
    -- Always let mouse input pass through during tutorial
    return false
end

function TutorialSystem.mousereleased(x, y, button)
    -- Always let mouse input pass through during tutorial
    return false
end

-- Save/Load tutorial state
function TutorialSystem.saveTutorialState()
    local saveData = {
        completed = TutorialSystem.hasCompletedTutorial
    }
    
    love.filesystem.write("tutorial_state.dat", tostring(TutorialSystem.hasCompletedTutorial))
end

function TutorialSystem.loadTutorialState()
    if love.filesystem.getInfo("tutorial_state.dat") then
        local data = love.filesystem.read("tutorial_state.dat")
        return { completed = data == "true" }
    end
    return nil
end

return TutorialSystem