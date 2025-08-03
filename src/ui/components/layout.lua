-- Layout System for Orbit Jump UI
-- Responsive layout management for different screen sizes and orientations

local Utils = require("src.utils.utils")
local Layout = {}

-- Screen breakpoints
Layout.breakpoints = {
    MOBILE = 768,
    TABLET = 1024,
    DESKTOP = 1200
}

-- Layout types
Layout.types = {
    FLEX = "flex",
    GRID = "grid",
    ABSOLUTE = "absolute",
    RELATIVE = "relative"
}

-- Default layout configuration
Layout.defaults = {
    padding = 10,
    margin = 5,
    spacing = 8,
    minTouchTarget = 44, -- iOS/Android accessibility guideline
    safeArea = {
        top = 20,
        bottom = 20,
        left = 20,
        right = 20
    }
}

-- Create a new layout manager
function Layout.new(config)
    config = config or {}
    
    local layout = {
        screenWidth = love.graphics.getWidth(),
        screenHeight = love.graphics.getHeight(),
        type = config.type or Layout.types.FLEX,
        padding = config.padding or Layout.defaults.padding,
        margin = config.margin or Layout.defaults.margin,
        spacing = config.spacing or Layout.defaults.spacing,
        minTouchTarget = config.minTouchTarget or Layout.defaults.minTouchTarget,
        safeArea = config.safeArea or Layout.defaults.safeArea,
        elements = {},
        isMobile = false,
        orientation = "landscape"
    }
    
    -- Detect device type and orientation
    layout:updateScreenInfo()
    
    return layout
end

-- Update screen information
function Layout:updateScreenInfo()
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    -- Detect mobile
    self.isMobile = self.screenWidth <= Layout.breakpoints.MOBILE or 
                   self.screenHeight <= Layout.breakpoints.MOBILE
    
    -- Detect orientation
    if self.screenWidth > self.screenHeight then
        self.orientation = "landscape"
    else
        self.orientation = "portrait"
    end
end

-- Add an element to the layout
function Layout:addElement(element, constraints)
    constraints = constraints or {}
    
    local layoutElement = {
        element = element,
        constraints = constraints,
        x = constraints.x or 0,
        y = constraints.y or 0,
        width = constraints.width or "auto",
        height = constraints.height or "auto",
        flex = constraints.flex or 1,
        align = constraints.align or "start",
        justify = constraints.justify or "start",
        margin = constraints.margin or self.margin,
        padding = constraints.padding or self.padding
    }
    
    table.insert(self.elements, layoutElement)
    return layoutElement
end

-- Calculate layout positions and sizes
function Layout:calculate()
    self:updateScreenInfo()
    
    if self.type == Layout.types.FLEX then
        self:calculateFlexLayout()
    elseif self.type == Layout.types.GRID then
        self:calculateGridLayout()
    elseif self.type == Layout.types.ABSOLUTE then
        self:calculateAbsoluteLayout()
    elseif self.type == Layout.types.RELATIVE then
        self:calculateRelativeLayout()
    end
end

-- Calculate flex layout
function Layout:calculateFlexLayout()
    local availableWidth = self.screenWidth - self.safeArea.left - self.safeArea.right - (self.padding * 2)
    local availableHeight = self.screenHeight - self.safeArea.top - self.safeArea.bottom - (self.padding * 2)
    local currentX = self.safeArea.left + self.padding
    local currentY = self.safeArea.top + self.padding
    
    -- Calculate total flex value
    local totalFlex = 0
    for _, element in ipairs(self.elements) do
        if element.constraints.width == "auto" then
            totalFlex = totalFlex + element.flex
        end
    end
    
    -- Position elements
    for _, element in ipairs(self.elements) do
        -- Calculate width
        if element.constraints.width == "auto" then
            element.width = (availableWidth / totalFlex) * element.flex
        else
            element.width = element.constraints.width
        end
        
        -- Ensure minimum touch target on mobile
        if self.isMobile and element.width < self.minTouchTarget then
            element.width = self.minTouchTarget
        end
        
        -- Calculate height
        if element.constraints.height == "auto" then
            element.height = element.constraints.height or 30
        else
            element.height = element.constraints.height
        end
        
        -- Ensure minimum touch target on mobile
        if self.isMobile and element.height < self.minTouchTarget then
            element.height = self.minTouchTarget
        end
        
        -- Position element
        element.x = currentX
        element.y = currentY
        
        -- Apply alignment
        if element.align == "center" then
            element.x = element.x + (availableWidth - element.width) / 2
        elseif element.align == "end" then
            element.x = element.x + availableWidth - element.width
        end
        
        -- Move to next position
        currentY = currentY + element.height + self.spacing
        
        -- Check if we need to wrap to next line
        if currentY + element.height > self.screenHeight - self.safeArea.bottom then
            currentY = self.safeArea.top + self.padding
            currentX = currentX + availableWidth + self.spacing
        end
    end
end

-- Calculate grid layout
function Layout:calculateGridLayout()
    local columns = self.constraints.columns or 2
    local availableWidth = self.screenWidth - self.safeArea.left - self.safeArea.right - (self.padding * 2)
    local availableHeight = self.screenHeight - self.safeArea.top - self.safeArea.bottom - (self.padding * 2)
    local cellWidth = (availableWidth - (self.spacing * (columns - 1))) / columns
    local cellHeight = 60
    
    for i, element in ipairs(self.elements) do
        local row = math.floor((i - 1) / columns)
        local col = (i - 1) % columns
        
        element.x = self.safeArea.left + self.padding + (col * (cellWidth + self.spacing))
        element.y = self.safeArea.top + self.padding + (row * (cellHeight + self.spacing))
        element.width = cellWidth
        element.height = cellHeight
    end
end

-- Calculate absolute layout
function Layout:calculateAbsoluteLayout()
    for _, element in ipairs(self.elements) do
        -- Use absolute positioning from constraints
        element.x = element.constraints.x or 0
        element.y = element.constraints.y or 0
        element.width = element.constraints.width or 100
        element.height = element.constraints.height or 30
    end
end

-- Calculate relative layout
function Layout:calculateRelativeLayout()
    local parent = self.constraints.parent or {x = 0, y = 0, width = self.screenWidth, height = self.screenHeight}
    
    for _, element in ipairs(self.elements) do
        -- Calculate relative positioning
        if element.constraints.relativeX then
            element.x = parent.x + (parent.width * element.constraints.relativeX)
        else
            element.x = element.constraints.x or 0
        end
        
        if element.constraints.relativeY then
            element.y = parent.y + (parent.height * element.constraints.relativeY)
        else
            element.y = element.constraints.y or 0
        end
        
        if element.constraints.relativeWidth then
            element.width = parent.width * element.constraints.relativeWidth
        else
            element.width = element.constraints.width or 100
        end
        
        if element.constraints.relativeHeight then
            element.height = parent.height * element.constraints.relativeHeight
        else
            element.height = element.constraints.height or 30
        end
    end
end

-- Apply layout to elements
function Layout:apply()
    for _, layoutElement in ipairs(self.elements) do
        local element = layoutElement.element
        
        -- Apply position and size to the element
        if element.setPosition then
            element:setPosition(layoutElement.x, layoutElement.y)
        else
            element.x = layoutElement.x
            element.y = layoutElement.y
        end
        
        if element.setSize then
            element:setSize(layoutElement.width, layoutElement.height)
        else
            element.width = layoutElement.width
            element.height = layoutElement.height
        end
    end
end

-- Get layout bounds
function Layout:getBounds()
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    
    for _, layoutElement in ipairs(self.elements) do
        minX = math.min(minX, layoutElement.x)
        minY = math.min(minY, layoutElement.y)
        maxX = math.max(maxX, layoutElement.x + layoutElement.width)
        maxY = math.max(maxY, layoutElement.y + layoutElement.height)
    end
    
    return {
        x = minX,
        y = minY,
        width = maxX - minX,
        height = maxY - minY
    }
end

-- Create a mobile-optimized layout
function Layout.createMobileLayout()
    return Layout.new({
        type = Layout.types.FLEX,
        padding = 15,
        margin = 8,
        spacing = 12,
        minTouchTarget = 44,
        safeArea = {
            top = 30,
            bottom = 30,
            left = 20,
            right = 20
        }
    })
end

-- Create a desktop layout
function Layout.createDesktopLayout()
    return Layout.new({
        type = Layout.types.GRID,
        padding = 10,
        margin = 5,
        spacing = 8,
        minTouchTarget = 20,
        safeArea = {
            top = 10,
            bottom = 10,
            left = 10,
            right = 10
        }
    })
end

-- Create a responsive layout that adapts to screen size
function Layout.createResponsiveLayout()
    local layout = Layout.new()
    
    -- Add responsive behavior
    function layout:update()
        self:updateScreenInfo()
        self:calculate()
        self:apply()
    end
    
    return layout
end

-- Utility functions for common layout patterns
function Layout.createTopBarLayout()
    return Layout.new({
        type = Layout.types.FLEX,
        constraints = {
            parent = {x = 0, y = 0, width = "100%", height = 60}
        }
    })
end

function Layout.createSidebarLayout()
    return Layout.new({
        type = Layout.types.FLEX,
        constraints = {
            parent = {x = 0, y = 0, width = 250, height = "100%"}
        }
    })
end

function Layout.createCenterLayout()
    return Layout.new({
        type = Layout.types.RELATIVE,
        constraints = {
            parent = {x = 0, y = 0, width = "100%", height = "100%"}
        }
    })
end

return Layout 