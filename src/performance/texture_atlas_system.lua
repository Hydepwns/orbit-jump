--[[
    ═══════════════════════════════════════════════════════════════════════════
    Texture Atlas System: Optimized Sprite Rendering
    ═══════════════════════════════════════════════════════════════════════════
    
    This system combines multiple small textures into a single atlas to reduce
    draw calls and improve rendering performance. It automatically packs sprites
    and provides efficient lookup for texture coordinates.
    
    Performance Benefits:
    • Reduces draw calls by batching sprites
    • Minimizes texture switching
    • Improves GPU memory efficiency
    • Enables sprite batching for better performance
--]]

local Utils = require("src.utils.utils")
local TextureAtlasSystem = {}

-- Atlas configuration
TextureAtlasSystem.config = {
    maxAtlasSize = 2048, -- Maximum atlas texture size
    padding = 2, -- Padding between sprites in atlas
    enableMipmaps = true, -- Enable mipmaps for better quality
    compression = "none", -- Texture compression (none, dxt, etc.)
    filterMode = "linear" -- Texture filtering mode
}

-- Atlas data
TextureAtlasSystem.atlases = {}
TextureAtlasSystem.spriteData = {}
TextureAtlasSystem.nextAtlasId = 1

-- Sprite definitions (programmatically generated)
TextureAtlasSystem.spriteDefinitions = {
    -- Player sprites
    player = { width = 32, height = 32, color = {1, 1, 1, 1} },
    player_dash = { width = 32, height = 32, color = {1, 0.8, 0.2, 1} },
    player_trail = { width = 16, height = 16, color = {0.8, 0.8, 1, 0.6} },
    
    -- Planet sprites
    planet_small = { width = 64, height = 64, color = {0.8, 0.6, 0.4, 1} },
    planet_medium = { width = 96, height = 96, color = {0.7, 0.5, 0.3, 1} },
    planet_large = { width = 128, height = 128, color = {0.6, 0.4, 0.2, 1} },
    planet_gas = { width = 112, height = 112, color = {0.9, 0.7, 0.3, 1} },
    
    -- Ring sprites
    ring_gold = { width = 24, height = 24, color = {1, 0.8, 0.2, 1} },
    ring_silver = { width = 24, height = 24, color = {0.8, 0.8, 0.8, 1} },
    ring_bronze = { width = 24, height = 24, color = {0.8, 0.5, 0.2, 1} },
    ring_platinum = { width = 24, height = 24, color = {0.9, 0.9, 1, 1} },
    
    -- Particle sprites
    particle_small = { width = 8, height = 8, color = {1, 1, 1, 0.8} },
    particle_medium = { width = 12, height = 12, color = {1, 1, 1, 0.9} },
    particle_large = { width = 16, height = 16, color = {1, 1, 1, 1} },
    particle_spark = { width = 6, height = 6, color = {1, 0.8, 0.2, 1} },
    
    -- UI sprites
    ui_button = { width = 128, height = 48, color = {0.2, 0.2, 0.3, 1} },
    ui_button_hover = { width = 128, height = 48, color = {0.3, 0.3, 0.4, 1} },
    ui_button_pressed = { width = 128, height = 48, color = {0.1, 0.1, 0.2, 1} },
    ui_panel = { width = 256, height = 128, color = {0.1, 0.1, 0.15, 0.9} },
    
    -- Effect sprites
    effect_explosion = { width = 64, height = 64, color = {1, 0.5, 0.2, 1} },
    effect_warp = { width = 48, height = 48, color = {0.5, 0.2, 1, 1} },
    effect_boost = { width = 32, height = 32, color = {0.2, 1, 0.5, 1} }
}

-- Initialize texture atlas system
function TextureAtlasSystem.init()
    TextureAtlasSystem.generateAtlases()
    Utils.Logger.info("Texture atlas system initialized with %d atlases", #TextureAtlasSystem.atlases)
end

-- Generate texture atlases from sprite definitions
function TextureAtlasSystem.generateAtlases()
    local sprites = {}
    
    -- Convert sprite definitions to sprite objects
    for name, def in pairs(TextureAtlasSystem.spriteDefinitions) do
        table.insert(sprites, {
            name = name,
            width = def.width,
            height = def.height,
            color = def.color,
            area = def.width * def.height
        })
    end
    
    -- Sort sprites by area (largest first for better packing)
    table.sort(sprites, function(a, b) return a.area > b.area end)
    
    -- Pack sprites into atlases
    local currentAtlas = TextureAtlasSystem.createAtlas()
    local currentX = TextureAtlasSystem.config.padding
    local currentY = TextureAtlasSystem.config.padding
    local rowHeight = 0
    
    for _, sprite in ipairs(sprites) do
        -- Check if sprite fits in current row
        if currentX + sprite.width + TextureAtlasSystem.config.padding > TextureAtlasSystem.config.maxAtlasSize then
            -- Move to next row
            currentX = TextureAtlasSystem.config.padding
            currentY = currentY + rowHeight + TextureAtlasSystem.config.padding
            rowHeight = 0
        end
        
        -- Check if we need a new atlas
        if currentY + sprite.height + TextureAtlasSystem.config.padding > TextureAtlasSystem.config.maxAtlasSize then
            -- Finalize current atlas and create new one
            TextureAtlasSystem.finalizeAtlas(currentAtlas)
            currentAtlas = TextureAtlasSystem.createAtlas()
            currentX = TextureAtlasSystem.config.padding
            currentY = TextureAtlasSystem.config.padding
            rowHeight = 0
        end
        
        -- Add sprite to current atlas
        TextureAtlasSystem.addSpriteToAtlas(currentAtlas, sprite, currentX, currentY)
        
        -- Update position for next sprite
        currentX = currentX + sprite.width + TextureAtlasSystem.config.padding
        rowHeight = math.max(rowHeight, sprite.height)
    end
    
    -- Finalize the last atlas
    if #currentAtlas.sprites > 0 then
        TextureAtlasSystem.finalizeAtlas(currentAtlas)
    end
end

-- Create a new atlas
function TextureAtlasSystem.createAtlas()
    return {
        id = TextureAtlasSystem.nextAtlasId,
        sprites = {},
        texture = nil,
        width = 0,
        height = 0
    }
end

-- Add sprite to atlas
function TextureAtlasSystem.addSpriteToAtlas(atlas, sprite, x, y)
    local spriteData = {
        name = sprite.name,
        x = x,
        y = y,
        width = sprite.width,
        height = sprite.height,
        u1 = x / TextureAtlasSystem.config.maxAtlasSize,
        v1 = y / TextureAtlasSystem.config.maxAtlasSize,
        u2 = (x + sprite.width) / TextureAtlasSystem.config.maxAtlasSize,
        v2 = (y + sprite.height) / TextureAtlasSystem.config.maxAtlasSize,
        color = sprite.color,
        atlasId = atlas.id
    }
    
    table.insert(atlas.sprites, spriteData)
    TextureAtlasSystem.spriteData[sprite.name] = spriteData
    
    -- Update atlas dimensions
    atlas.width = math.max(atlas.width, x + sprite.width + TextureAtlasSystem.config.padding)
    atlas.height = math.max(atlas.height, y + sprite.height + TextureAtlasSystem.config.padding)
end

-- Finalize atlas and create texture
function TextureAtlasSystem.finalizeAtlas(atlas)
    if #atlas.sprites == 0 then return end
    
    -- Check if love.graphics is available
    if not love or not love.graphics then
        Utils.Logger.warn("love.graphics not available, creating mock atlas")
        -- Create mock atlas for testing
        atlas.texture = { mock = true }
        table.insert(TextureAtlasSystem.atlases, atlas)
        TextureAtlasSystem.nextAtlasId = TextureAtlasSystem.nextAtlasId + 1
        return
    end
    
    -- Create canvas for atlas texture
    local success, canvas = pcall(love.graphics.newCanvas, atlas.width, atlas.height)
    if not success then
        Utils.Logger.warn("Failed to create canvas for atlas %d", atlas.id)
        return
    end
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0) -- Clear with transparent background
    
    -- Draw all sprites to canvas
    for _, sprite in ipairs(atlas.sprites) do
        -- Create a simple colored rectangle for the sprite
        love.graphics.setColor(sprite.color)
        love.graphics.rectangle("fill", sprite.x, sprite.y, sprite.width, sprite.height)
        
        -- Add a subtle border for debugging
        if TextureAtlasSystem.config.debug then
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("line", sprite.x, sprite.y, sprite.width, sprite.height)
        end
    end
    
    love.graphics.setCanvas()
    
    -- Create texture from canvas
    atlas.texture = canvas
    atlas.texture:setFilter(TextureAtlasSystem.config.filterMode)
    
    if TextureAtlasSystem.config.enableMipmaps then
        atlas.texture:setMipmapFilter(TextureAtlasSystem.config.filterMode)
    end
    
    table.insert(TextureAtlasSystem.atlases, atlas)
    TextureAtlasSystem.nextAtlasId = TextureAtlasSystem.nextAtlasId + 1
    
    Utils.Logger.debug("Created atlas %d with %d sprites (%dx%d)", 
        atlas.id, #atlas.sprites, atlas.width, atlas.height)
end

-- Get sprite data by name
function TextureAtlasSystem.getSprite(name)
    return TextureAtlasSystem.spriteData[name]
end

-- Draw sprite by name
function TextureAtlasSystem.drawSprite(name, x, y, rotation, scaleX, scaleY, color)
    local sprite = TextureAtlasSystem.getSprite(name)
    if not sprite then
        Utils.Logger.warn("Sprite not found: %s", name)
        return false
    end
    
    local atlas = TextureAtlasSystem.getAtlas(sprite.atlasId)
    if not atlas or not atlas.texture then
        Utils.Logger.warn("Atlas not found: %d", sprite.atlasId)
        return false
    end
    
    -- Check if this is a mock texture (for testing)
    if atlas.texture.mock then
        return true -- Pretend we drew it successfully
    end
    
    -- Check if love.graphics is available
    if not love or not love.graphics then
        return false
    end
    
    -- Set color
    if color then
        love.graphics.setColor(color)
    else
        love.graphics.setColor(sprite.color)
    end
    
    -- Draw sprite
    love.graphics.draw(atlas.texture, 
        love.graphics.newQuad(sprite.x, sprite.y, sprite.width, sprite.height, atlas.width, atlas.height),
        x, y, rotation or 0, scaleX or 1, scaleY or 1)
    
    return true
end

-- Get atlas by ID
function TextureAtlasSystem.getAtlas(atlasId)
    for _, atlas in ipairs(TextureAtlasSystem.atlases) do
        if atlas.id == atlasId then
            return atlas
        end
    end
    return nil
end

-- Batch draw multiple sprites
function TextureAtlasSystem.drawBatch(sprites)
    local currentAtlasId = nil
    local currentTexture = nil
    
    for _, spriteData in ipairs(sprites) do
        local sprite = TextureAtlasSystem.getSprite(spriteData.name)
        if sprite then
            -- Switch texture if needed
            if sprite.atlasId ~= currentAtlasId then
                local atlas = TextureAtlasSystem.getAtlas(sprite.atlasId)
                if atlas and atlas.texture then
                    currentTexture = atlas.texture
                    currentAtlasId = sprite.atlasId
                else
                    goto continue
                end
            end
            
            -- Set color
            love.graphics.setColor(spriteData.color or sprite.color)
            
            -- Draw sprite
            love.graphics.draw(currentTexture,
                love.graphics.newQuad(sprite.x, sprite.y, sprite.width, sprite.height, 
                    TextureAtlasSystem.config.maxAtlasSize, TextureAtlasSystem.config.maxAtlasSize),
                spriteData.x, spriteData.y, spriteData.rotation or 0, 
                spriteData.scaleX or 1, spriteData.scaleY or 1)
        end
        
        ::continue::
    end
end

-- Get atlas statistics
function TextureAtlasSystem.getStats()
    local stats = {
        atlasCount = #TextureAtlasSystem.atlases,
        spriteCount = 0,
        totalMemory = 0,
        atlases = {}
    }
    
    for _, atlas in ipairs(TextureAtlasSystem.atlases) do
        local atlasStats = {
            id = atlas.id,
            spriteCount = #atlas.sprites,
            width = atlas.width,
            height = atlas.height,
            memoryUsage = atlas.width * atlas.height * 4 -- 4 bytes per pixel (RGBA)
        }
        
        stats.spriteCount = stats.spriteCount + atlasStats.spriteCount
        stats.totalMemory = stats.totalMemory + atlasStats.memoryUsage
        table.insert(stats.atlases, atlasStats)
    end
    
    return stats
end

-- Enable/disable debug mode
function TextureAtlasSystem.setDebugMode(enabled)
    TextureAtlasSystem.config.debug = enabled
end

-- Clean up resources
function TextureAtlasSystem.cleanup()
    for _, atlas in ipairs(TextureAtlasSystem.atlases) do
        if atlas.texture then
            atlas.texture:release()
        end
    end
    
    TextureAtlasSystem.atlases = {}
    TextureAtlasSystem.spriteData = {}
    TextureAtlasSystem.nextAtlasId = 1
    
    Utils.Logger.info("Texture atlas system cleaned up")
end

return TextureAtlasSystem 