-- Render Batch System for Orbit Jump
-- Batches similar draw calls for improved performance

local RenderBatch = {}
RenderBatch.__index = RenderBatch

-- Create a new render batch
function RenderBatch:new()
    local self = setmetatable({}, RenderBatch)
    self.batches = {}
    self.drawCalls = 0
    self.itemsDrawn = 0
    return self
end

-- Clear all batches
function RenderBatch:clear()
    self.batches = {}
    self.drawCalls = 0
    self.itemsDrawn = 0
end

-- Add an item to be batched
function RenderBatch:add(category, subcategory, item)
    -- Create category if doesn't exist
    if not self.batches[category] then
        self.batches[category] = {}
    end
    
    -- Create subcategory if doesn't exist
    if not self.batches[category][subcategory] then
        self.batches[category][subcategory] = {}
    end
    
    -- Add item to batch
    table.insert(self.batches[category][subcategory], item)
end

-- Add a circle to batch
function RenderBatch:addCircle(mode, x, y, radius, color, lineWidth)
    self:add("circles", mode, {
        x = x,
        y = y,
        radius = radius,
        color = color,
        lineWidth = lineWidth
    })
end

-- Add a rectangle to batch
function RenderBatch:addRectangle(mode, x, y, width, height, color, lineWidth)
    self:add("rectangles", mode, {
        x = x,
        y = y,
        width = width,
        height = height,
        color = color,
        lineWidth = lineWidth
    })
end

-- Add a line to batch
function RenderBatch:addLine(points, color, lineWidth)
    self:add("lines", "default", {
        points = points,
        color = color,
        lineWidth = lineWidth
    })
end

-- Add text to batch
function RenderBatch:addText(text, x, y, color, font, align, limit)
    local fontKey = font or "default"
    self:add("text", fontKey, {
        text = text,
        x = x,
        y = y,
        color = color,
        font = font,
        align = align,
        limit = limit
    })
end

-- Add a sprite to batch
function RenderBatch:addSprite(image, x, y, rotation, scaleX, scaleY, color)
    local imageKey = tostring(image)
    self:add("sprites", imageKey, {
        image = image,
        x = x,
        y = y,
        rotation = rotation or 0,
        scaleX = scaleX or 1,
        scaleY = scaleY or 1,
        color = color or {1, 1, 1, 1}
    })
end

-- Execute all batched draws
function RenderBatch:flush()
    local lg = love.graphics
    self.drawCalls = 0
    self.itemsDrawn = 0
    
    -- Draw circles
    if self.batches.circles then
        for mode, circles in pairs(self.batches.circles) do
            if #circles > 0 then
                lg.push()
                
                -- Group by similar properties
                local groups = self:groupByProperties(circles, {"color", "lineWidth"})
                
                for _, group in ipairs(groups) do
                    -- Set common properties once
                    lg.setColor(group.color)
                    if mode == "line" and group.lineWidth then
                        lg.setLineWidth(group.lineWidth)
                    end
                    
                    -- Draw all circles in group
                    for _, circle in ipairs(group.items) do
                        lg.circle(mode, circle.x, circle.y, circle.radius)
                        self.itemsDrawn = self.itemsDrawn + 1
                    end
                    
                    self.drawCalls = self.drawCalls + 1
                end
                
                lg.pop()
            end
        end
    end
    
    -- Draw rectangles
    if self.batches.rectangles then
        for mode, rectangles in pairs(self.batches.rectangles) do
            if #rectangles > 0 then
                lg.push()
                
                local groups = self:groupByProperties(rectangles, {"color", "lineWidth"})
                
                for _, group in ipairs(groups) do
                    lg.setColor(group.color)
                    if mode == "line" and group.lineWidth then
                        lg.setLineWidth(group.lineWidth)
                    end
                    
                    for _, rect in ipairs(group.items) do
                        lg.rectangle(mode, rect.x, rect.y, rect.width, rect.height)
                        self.itemsDrawn = self.itemsDrawn + 1
                    end
                    
                    self.drawCalls = self.drawCalls + 1
                end
                
                lg.pop()
            end
        end
    end
    
    -- Draw lines
    if self.batches.lines and self.batches.lines.default then
        lg.push()
        
        local groups = self:groupByProperties(self.batches.lines.default, {"color", "lineWidth"})
        
        for _, group in ipairs(groups) do
            lg.setColor(group.color)
            if group.lineWidth then
                lg.setLineWidth(group.lineWidth)
            end
            
            for _, line in ipairs(group.items) do
                if #line.points >= 4 then
                    lg.line(line.points)
                    self.itemsDrawn = self.itemsDrawn + 1
                end
            end
            
            self.drawCalls = self.drawCalls + 1
        end
        
        lg.pop()
    end
    
    -- Draw sprites
    if self.batches.sprites then
        for imageKey, sprites in pairs(self.batches.sprites) do
            if #sprites > 0 and sprites[1].image then
                lg.push()
                
                -- Use SpriteBatch for multiple sprites of same image
                if #sprites > 5 then
                    local spriteBatch = lg.newSpriteBatch(sprites[1].image, #sprites)
                    
                    for _, sprite in ipairs(sprites) do
                        spriteBatch:add(
                            sprite.x, sprite.y,
                            sprite.rotation,
                            sprite.scaleX, sprite.scaleY
                        )
                        self.itemsDrawn = self.itemsDrawn + 1
                    end
                    
                    lg.setColor(1, 1, 1, 1)
                    lg.draw(spriteBatch)
                    self.drawCalls = self.drawCalls + 1
                else
                    -- Draw individually for small batches
                    for _, sprite in ipairs(sprites) do
                        lg.setColor(sprite.color)
                        lg.draw(
                            sprite.image,
                            sprite.x, sprite.y,
                            sprite.rotation,
                            sprite.scaleX, sprite.scaleY
                        )
                        self.itemsDrawn = self.itemsDrawn + 1
                        self.drawCalls = self.drawCalls + 1
                    end
                end
                
                lg.pop()
            end
        end
    end
    
    -- Draw text
    if self.batches.text then
        lg.push()
        
        for fontKey, texts in pairs(self.batches.text) do
            if #texts > 0 then
                -- Set font once for all text with same font
                if texts[1].font then
                    lg.setFont(texts[1].font)
                end
                
                for _, text in ipairs(texts) do
                    lg.setColor(text.color or {1, 1, 1, 1})
                    
                    if text.limit then
                        lg.printf(text.text, text.x, text.y, text.limit, text.align or "left")
                    else
                        lg.print(text.text, text.x, text.y)
                    end
                    
                    self.itemsDrawn = self.itemsDrawn + 1
                end
                
                self.drawCalls = self.drawCalls + 1
            end
        end
        
        lg.pop()
    end
    
    -- Reset color
    lg.setColor(1, 1, 1, 1)
end

-- Group items by similar properties
function RenderBatch:groupByProperties(items, properties)
    local groups = {}
    local groupMap = {}
    
    for _, item in ipairs(items) do
        -- Create key from properties
        local key = ""
        local groupData = {}
        
        for _, prop in ipairs(properties) do
            local value = item[prop]
            if type(value) == "table" then
                key = key .. table.concat(value, ",") .. "|"
            else
                key = key .. tostring(value) .. "|"
            end
            groupData[prop] = value
        end
        
        -- Add to existing group or create new
        if not groupMap[key] then
            groupMap[key] = {
                items = {},
                color = groupData.color or {1, 1, 1, 1},
                lineWidth = groupData.lineWidth
            }
            table.insert(groups, groupMap[key])
        end
        
        table.insert(groupMap[key].items, item)
    end
    
    return groups
end

-- Get batch statistics
function RenderBatch:getStats()
    return {
        drawCalls = self.drawCalls,
        itemsDrawn = self.itemsDrawn,
        efficiency = self.itemsDrawn > 0 and self.drawCalls / self.itemsDrawn or 0
    }
end

return RenderBatch