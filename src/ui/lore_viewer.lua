-- Lore Viewer UI for Orbit Jump
-- Displays collected artifacts and their lore entries

local Utils = Utils.Utils.require("src.utils.utils")
local LoreViewer = {}

-- UI state
LoreViewer.isVisible = false
LoreViewer.scrollY = 0
LoreViewer.selectedArtifact = nil
LoreViewer.fadeAlpha = 0

-- UI dimensions
LoreViewer.width = 800
LoreViewer.height = 600
LoreViewer.padding = 20
LoreViewer.itemHeight = 80
LoreViewer.scrollSpeed = 300

-- Initialize
function LoreViewer.init()
    LoreViewer.isVisible = false
    LoreViewer.scrollY = 0
    LoreViewer.selectedArtifact = nil
    LoreViewer.fadeAlpha = 0
end

-- Toggle lore viewer
function LoreViewer.toggle()
    LoreViewer.isVisible = not LoreViewer.isVisible
    if LoreViewer.isVisible then
        LoreViewer.scrollY = 0
        LoreViewer.selectedArtifact = nil
    end
    Utils.Logger.info("Lore viewer: %s", LoreViewer.isVisible and "opened" or "closed")
end

-- Open to specific artifact
function LoreViewer.openToArtifact(artifactId)
    LoreViewer.isVisible = true
    LoreViewer.scrollY = 0
    
    -- Find and select the artifact
    local ArtifactSystem = Utils.Utils.require("src.systems.artifact_system")
    for _, artifact in ipairs(ArtifactSystem.artifacts) do
        if artifact.id == artifactId then
            LoreViewer.selectedArtifact = artifact
            break
        end
    end
end

-- Update
function LoreViewer.update(dt)
    -- Update fade effect
    if LoreViewer.isVisible then
        LoreViewer.fadeAlpha = math.min(LoreViewer.fadeAlpha + dt * 5, 1)
    else
        LoreViewer.fadeAlpha = math.max(LoreViewer.fadeAlpha - dt * 5, 0)
        if LoreViewer.fadeAlpha <= 0 then
            LoreViewer.selectedArtifact = nil
        end
    end
end

-- Handle input
function LoreViewer.keypressed(key)
    if not LoreViewer.isVisible then return false end
    
    if key == "escape" or key == "l" then
        LoreViewer.toggle()
        return true
    elseif key == "up" then
        LoreViewer.scrollY = math.max(0, LoreViewer.scrollY - LoreViewer.scrollSpeed * 0.016)
        return true
    elseif key == "down" then
        LoreViewer.scrollY = LoreViewer.scrollY + LoreViewer.scrollSpeed * 0.016
        return true
    elseif key == "left" or key == "backspace" then
        -- Go back to list view
        LoreViewer.selectedArtifact = nil
        return true
    end
    
    return false
end

-- Handle mouse input
function LoreViewer.mousepressed(x, y, button)
    if not LoreViewer.isVisible or LoreViewer.fadeAlpha < 0.5 then return false end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local viewerX = (screenWidth - LoreViewer.width) / 2
    local viewerY = (screenHeight - LoreViewer.height) / 2
    
    -- Check if click is inside viewer
    if x < viewerX or x > viewerX + LoreViewer.width or
       y < viewerY or y > viewerY + LoreViewer.height then
        -- Click outside, close viewer
        LoreViewer.toggle()
        return true
    end
    
    if button == 1 then
        if LoreViewer.selectedArtifact then
            -- In detail view, check for back button
            if x >= viewerX + 20 and x <= viewerX + 100 and
               y >= viewerY + 20 and y <= viewerY + 50 then
                LoreViewer.selectedArtifact = nil
                return true
            end
        else
            -- In list view, check for artifact clicks
            local ArtifactSystem = Utils.Utils.require("src.systems.artifact_system")
            local listY = viewerY + 80 - LoreViewer.scrollY
            
            for _, artifact in ipairs(ArtifactSystem.artifacts) do
                if artifact.discovered then
                    if y >= listY and y <= listY + LoreViewer.itemHeight then
                        LoreViewer.selectedArtifact = artifact
                        return true
                    end
                    listY = listY + LoreViewer.itemHeight + 10
                end
            end
        end
    end
    
    return true -- Consume input when visible
end

-- Handle mouse wheel
function LoreViewer.wheelmoved(x, y)
    if not LoreViewer.isVisible then return false end
    
    LoreViewer.scrollY = LoreViewer.scrollY - y * 50
    LoreViewer.scrollY = math.max(0, LoreViewer.scrollY)
    
    return true
end

-- Draw lore viewer
function LoreViewer.draw()
    if LoreViewer.fadeAlpha <= 0 then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw darkened background
    Utils.setColor({0, 0, 0}, 0.8 * LoreViewer.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw viewer panel
    local viewerX = (screenWidth - LoreViewer.width) / 2
    local viewerY = (screenHeight - LoreViewer.height) / 2
    
    -- Panel background
    Utils.setColor({0.1, 0.1, 0.2}, 0.95 * LoreViewer.fadeAlpha)
    love.graphics.rectangle("fill", viewerX, viewerY, LoreViewer.width, LoreViewer.height, 10)
    
    -- Panel border
    Utils.setColor({0.5, 0.8, 1}, LoreViewer.fadeAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", viewerX, viewerY, LoreViewer.width, LoreViewer.height, 10)
    
    -- Set scissor for content scrolling
    love.graphics.setScissor(viewerX, viewerY, LoreViewer.width, LoreViewer.height)
    
    if LoreViewer.selectedArtifact then
        -- Draw artifact detail view
        LoreViewer.drawArtifactDetail(viewerX, viewerY)
    else
        -- Draw artifact list
        LoreViewer.drawArtifactList(viewerX, viewerY)
    end
    
    -- Clear scissor
    love.graphics.setScissor()
    
    -- Draw close hint
    Utils.setColor({0.5, 0.5, 0.5}, LoreViewer.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("Press ESC or L to close", viewerX, viewerY + LoreViewer.height - 30, 
                        LoreViewer.width, "center")
end

-- Draw artifact list
function LoreViewer.drawArtifactList(x, y)
    -- Title
    Utils.setColor({1, 1, 1}, LoreViewer.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf("Ancient Artifacts", x, y + 20, LoreViewer.width, "center")
    
    -- Collection progress
    local ArtifactSystem = Utils.Utils.require("src.systems.artifact_system")
    local collected = ArtifactSystem.collectedCount or 0
    local total = #ArtifactSystem.artifacts
    
    Utils.setColor({0.7, 0.7, 0.7}, LoreViewer.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(string.format("Collected: %d / %d", collected, total), 
                        x, y + 55, LoreViewer.width, "center")
    
    -- Draw artifacts
    local listY = y + 80 - LoreViewer.scrollY
    love.graphics.setFont(love.graphics.newFont(18))
    
    for i, artifact in ipairs(ArtifactSystem.artifacts) do
        if artifact.discovered then
            -- Artifact background
            Utils.setColor({0.2, 0.3, 0.4}, 0.5 * LoreViewer.fadeAlpha)
            love.graphics.rectangle("fill", x + 20, listY, LoreViewer.width - 40, 
                                  LoreViewer.itemHeight, 5)
            
            -- Hover effect
            local mx, my = love.mouse.getPosition()
            if mx >= x + 20 and mx <= x + LoreViewer.width - 20 and
               my >= listY and my <= listY + LoreViewer.itemHeight then
                Utils.setColor({0.3, 0.4, 0.5}, 0.3 * LoreViewer.fadeAlpha)
                love.graphics.rectangle("fill", x + 20, listY, LoreViewer.width - 40, 
                                      LoreViewer.itemHeight, 5)
            end
            
            -- Artifact icon/number
            Utils.setColor({0.8, 0.6, 1}, LoreViewer.fadeAlpha)
            love.graphics.print(string.format("#%d", i), x + 40, listY + 25)
            
            -- Artifact name
            Utils.setColor({1, 1, 1}, LoreViewer.fadeAlpha)
            love.graphics.print(artifact.name, x + 100, listY + 15)
            
            -- Preview text
            Utils.setColor({0.7, 0.7, 0.7}, LoreViewer.fadeAlpha)
            love.graphics.setFont(love.graphics.newFont(14))
            local preview = string.sub(artifact.lore, 1, 80) .. "..."
            love.graphics.print(preview, x + 100, listY + 40)
            love.graphics.setFont(love.graphics.newFont(18))
            
            -- Click hint
            Utils.setColor({0.5, 0.8, 1}, LoreViewer.fadeAlpha * 0.7)
            love.graphics.setFont(love.graphics.newFont(12))
            love.graphics.print("Click to read →", x + LoreViewer.width - 140, listY + 30)
            love.graphics.setFont(love.graphics.newFont(18))
        else
            -- Undiscovered artifact
            Utils.setColor({0.15, 0.15, 0.15}, 0.5 * LoreViewer.fadeAlpha)
            love.graphics.rectangle("fill", x + 20, listY, LoreViewer.width - 40, 
                                  LoreViewer.itemHeight, 5)
            
            -- Question mark
            Utils.setColor({0.3, 0.3, 0.3}, LoreViewer.fadeAlpha)
            love.graphics.print("?", x + 40, listY + 25)
            
            -- Mystery text
            Utils.setColor({0.4, 0.4, 0.4}, LoreViewer.fadeAlpha)
            love.graphics.print("Undiscovered Artifact", x + 100, listY + 15)
            
            -- Hint
            Utils.setColor({0.3, 0.3, 0.3}, LoreViewer.fadeAlpha)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.print("Explore the galaxy to find this artifact", x + 100, listY + 40)
            love.graphics.setFont(love.graphics.newFont(18))
        end
        
        listY = listY + LoreViewer.itemHeight + 10
    end
end

-- Draw artifact detail
function LoreViewer.drawArtifactDetail(x, y)
    local artifact = LoreViewer.selectedArtifact
    
    -- Back button
    Utils.setColor({0.5, 0.8, 1}, LoreViewer.fadeAlpha)
    love.graphics.rectangle("fill", x + 20, y + 20, 80, 30, 5)
    Utils.setColor({1, 1, 1}, LoreViewer.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("← Back", x + 20, y + 28, 80, "center")
    
    -- Artifact name
    Utils.setColor({1, 1, 1}, LoreViewer.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf(artifact.name, x, y + 70, LoreViewer.width, "center")
    
    -- Artifact visual
    local visualY = y + 120
    local visualSize = 60
    
    -- Glow effect
    local glow = math.sin(love.timer.getTime() * 2) * 0.2 + 0.8
    Utils.setColor({0.8, 0.6, 1}, glow * LoreViewer.fadeAlpha * 0.3)
    love.graphics.circle("fill", x + LoreViewer.width / 2, visualY, visualSize * 1.5)
    
    -- Crystal shape
    Utils.setColor({0.8, 0.6, 1}, LoreViewer.fadeAlpha)
    love.graphics.push()
    love.graphics.translate(x + LoreViewer.width / 2, visualY)
    love.graphics.rotate(love.timer.getTime() * 0.5)
    
    -- Draw hexagonal crystal
    local vertices = {}
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2
        table.insert(vertices, math.cos(angle) * visualSize)
        table.insert(vertices, math.sin(angle) * visualSize)
    end
    love.graphics.polygon("fill", vertices)
    
    -- Inner detail
    Utils.setColor({1, 0.9, 1}, LoreViewer.fadeAlpha * 0.7)
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2
        love.graphics.line(0, 0, math.cos(angle) * visualSize * 0.8, 
                          math.sin(angle) * visualSize * 0.8)
    end
    
    love.graphics.pop()
    
    -- Lore text
    local textY = visualY + visualSize + 40 - LoreViewer.scrollY
    Utils.setColor({0.9, 0.9, 0.9}, LoreViewer.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(16))
    
    -- Word wrap the lore
    local font = love.graphics.getFont()
    local wrapWidth = LoreViewer.width - 80
    local wrappedText, lines = font:getWrap(artifact.lore, wrapWidth)
    
    love.graphics.printf(artifact.lore, x + 40, textY, wrapWidth, "left")
    
    -- Special note for final artifact
    if artifact.requiresAll then
        textY = textY + lines * font:getHeight() + 40
        Utils.setColor({1, 0.8, 0}, LoreViewer.fadeAlpha)
        love.graphics.printf("This artifact requires all others to be collected first.", 
                           x + 40, textY, wrapWidth, "center")
    end
    
    -- Location hint
    if artifact.hint and not artifact.discovered then
        textY = textY + 60
        Utils.setColor({0.5, 0.8, 1}, LoreViewer.fadeAlpha)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf("Hint: " .. artifact.hint, x + 40, textY, wrapWidth, "center")
    end
end

-- Check if blocking input
function LoreViewer.isBlockingInput()
    return LoreViewer.isVisible and LoreViewer.fadeAlpha > 0.5
end

return LoreViewer