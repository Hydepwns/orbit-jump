--[[
    Debug Rendering for Orbit Jump
    
    This module handles debug visualization, UI elements, and metrics display.
--]]

local Drawing = require("src.utils.rendering.drawing")
local UIComponents = require("src.utils.rendering.ui_components")
local DebugConfig = require("src.ui.debug.debug_config")
local DebugLogging = require("src.ui.debug.debug_logging")
local DebugValidation = require("src.ui.debug.debug_validation")
local DebugPerformance = require("src.ui.debug.debug_performance")

local DebugRendering = {}

-- Rendering state
DebugRendering.currentTheme = "default"
DebugRendering.colors = DebugConfig.getTheme("default")

-- Draw main debug interface
function DebugRendering.draw()
    if not DebugRendering.isEnabled() then
        return
    end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw element boundaries
    DebugRendering.drawElementBoundaries()
    
    -- Draw metrics panel
    DebugRendering.drawEnhancedMetricsPanel(screenWidth, screenHeight)
    
    -- Draw validation issues
    DebugRendering.drawValidationIssues()
    
    -- Draw performance overlay
    DebugRendering.drawPerformanceOverlay(screenWidth, screenHeight)
end

-- Check if debug rendering is enabled
function DebugRendering.isEnabled()
    -- This will be set by the main debug system
    return true -- Placeholder
end

-- Draw element boundaries
function DebugRendering.drawElementBoundaries()
    local trackedElements = DebugValidation.getTrackedElements()
    
    for name, trackedElement in pairs(trackedElements) do
        local element = trackedElement.element
        if element then
            DebugRendering.drawElementBoundary(name, element, trackedElement)
        end
    end
end

-- Draw individual element boundary
function DebugRendering.drawElementBoundary(name, element, trackedElement)
    local x, y = element.x or 0, element.y or 0
    local width, height = element.width or 0, element.height or 0
    
    -- Choose color based on validation status
    local color
    if trackedElement.valid then
        color = DebugRendering.colors.element
    else
        color = DebugRendering.colors.error
    end
    
    -- Draw boundary rectangle
    Drawing.setColor(color[1], color[2], color[3], color[4])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height)
    love.graphics.setLineWidth(1)
    
    -- Draw element label
    if DebugRendering.shouldShowLabels() then
        DebugRendering.drawElementLabel(name, x, y, width, height)
    end
end

-- Draw element label
function DebugRendering.drawElementLabel(name, x, y, width, height)
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], DebugRendering.colors.text[4])
    love.graphics.setFont(love.graphics.newFont(12))
    
    local labelX = x + 5
    local labelY = y + 5
    
    -- Draw background for label
    local textWidth = love.graphics.getFont():getWidth(name)
    Drawing.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", labelX - 2, labelY - 2, textWidth + 4, 16)
    
    -- Draw text
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], DebugRendering.colors.text[4])
    love.graphics.print(name, labelX, labelY)
end

-- Draw enhanced metrics panel
function DebugRendering.drawEnhancedMetricsPanel(screenWidth, screenHeight)
    local panelWidth = 350
    local panelHeight = 400
    local panelX = screenWidth - panelWidth - 20
    local panelY = 20
    
    -- Panel background
    Drawing.setColor(DebugRendering.colors.background[1], DebugRendering.colors.background[2], 
                     DebugRendering.colors.background[3], DebugRendering.colors.background[4])
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 8)
    
    -- Panel border
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 8)
    love.graphics.setLineWidth(1)
    
    -- Title
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], DebugRendering.colors.text[4])
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("🔧 Debug Panel", panelX + 15, panelY + 15)
    
    -- Metrics
    local y = panelY + 50
    love.graphics.setFont(love.graphics.newFont(12))
    
    -- Element count
    local elementCount = DebugValidation.countTrackedElements()
    love.graphics.print(string.format("Elements: %d", elementCount), panelX + 15, y)
    y = y + 25
    
    -- Issue count
    local issueCount = DebugValidation.countLayoutIssues()
    local color = issueCount > 0 and DebugRendering.colors.warning or DebugRendering.colors.success
    Drawing.setColor(color[1], color[2], color[3], color[4])
    love.graphics.print(string.format("Issues: %d", issueCount), panelX + 15, y)
    y = y + 25
    
    -- Performance metrics
    local performance = DebugPerformance.getPerformanceMetrics()
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], DebugRendering.colors.text[4])
    
    love.graphics.print(string.format("Frame Time: %.2fms", performance.frameTime * 1000), panelX + 15, y)
    y = y + 20
    love.graphics.print(string.format("Draw Calls: %d", performance.drawCalls), panelX + 15, y)
    y = y + 20
    love.graphics.print(string.format("Memory: %.1fKB", performance.memoryUsage / 1024), panelX + 15, y)
    y = y + 20
    love.graphics.print(string.format("Validation: %.2fms", performance.validationTime * 1000), panelX + 15, y)
    y = y + 30
    
    -- Performance issues
    local issues = DebugPerformance.checkPerformanceIssues()
    if #issues > 0 then
        love.graphics.print("Performance Issues:", panelX + 15, y)
        y = y + 20
        
        for i, issue in ipairs(issues) do
            if i <= 3 then -- Show only first 3 issues
                local color = issue.severity == "error" and DebugRendering.colors.error or DebugRendering.colors.warning
                Drawing.setColor(color[1], color[2], color[3], color[4])
                love.graphics.print("• " .. issue.message, panelX + 25, y)
                y = y + 18
            end
        end
    end
    
    -- Theme info
    y = panelY + panelHeight - 40
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], 0.7)
    love.graphics.print(string.format("Theme: %s", DebugRendering.currentTheme), panelX + 15, y)
    y = y + 20
    love.graphics.print("Press F12 to toggle, T to cycle theme", panelX + 15, y)
end

-- Draw validation issues
function DebugRendering.drawValidationIssues()
    local layoutIssues = DebugValidation.getLayoutIssues()
    
    for elementName, issues in pairs(layoutIssues) do
        local trackedElement = DebugValidation.getElement(elementName)
        if trackedElement then
            local element = trackedElement.element
            DebugRendering.drawElementIssues(elementName, element, issues)
        end
    end
end

-- Draw issues for specific element
function DebugRendering.drawElementIssues(elementName, element, issues)
    local x, y = element.x or 0, element.y or 0
    local width, height = element.width or 0, element.height or 0
    
    -- Draw issue indicators
    for _, issue in ipairs(issues) do
        local color
        if issue.severity == "error" then
            color = DebugRendering.colors.error
        else
            color = DebugRendering.colors.warning
        end
        
        -- Draw issue border
        Drawing.setColor(color[1], color[2], color[3], color[4])
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4)
        love.graphics.setLineWidth(1)
        
        -- Draw issue label
        DebugRendering.drawIssueLabel(elementName, issue, x, y)
    end
end

-- Draw issue label
function DebugRendering.drawIssueLabel(elementName, issue, x, y)
    local label = string.format("%s: %s", elementName, issue.issue)
    
    Drawing.setColor(0, 0, 0, 0.8)
    love.graphics.setFont(love.graphics.newFont(10))
    
    local textWidth = love.graphics.getFont():getWidth(label)
    love.graphics.rectangle("fill", x, y - 20, textWidth + 8, 16)
    
    local color = issue.severity == "error" and DebugRendering.colors.error or DebugRendering.colors.warning
    Drawing.setColor(color[1], color[2], color[3], color[4])
    love.graphics.print(label, x + 4, y - 18)
end

-- Draw performance overlay
function DebugRendering.drawPerformanceOverlay(screenWidth, screenHeight)
    local overlayX = 20
    local overlayY = screenHeight - 120
    
    -- Overlay background
    Drawing.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", overlayX, overlayY, 300, 100, 5)
    
    -- Performance stats
    local stats = DebugPerformance.getPerformanceStats()
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], DebugRendering.colors.text[4])
    love.graphics.setFont(love.graphics.newFont(12))
    
    love.graphics.print(string.format("Avg Frame: %.2fms", stats.avgFrameTime * 1000), overlayX + 10, overlayY + 10)
    love.graphics.print(string.format("Min/Max: %.2f/%.2fms", stats.minFrameTime * 1000, stats.maxFrameTime * 1000), overlayX + 10, overlayY + 30)
    love.graphics.print(string.format("Draw Calls: %.0f", stats.avgDrawCalls), overlayX + 10, overlayY + 50)
    love.graphics.print(string.format("Memory: %.1fMB", stats.avgMemoryUsage / (1024 * 1024)), overlayX + 10, overlayY + 70)
end

-- Set theme
function DebugRendering.setTheme(themeName)
    DebugRendering.currentTheme = themeName
    DebugRendering.colors = DebugConfig.getTheme(themeName)
    DebugLogging.logThemeChange(themeName)
end

-- Get current theme
function DebugRendering.getCurrentTheme()
    return DebugRendering.currentTheme
end

-- Check if labels should be shown
function DebugRendering.shouldShowLabels()
    -- This will be controlled by the main debug system
    return true -- Placeholder
end

-- Draw screenshot mode overlay
function DebugRendering.drawScreenshotMode()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Full screen overlay
    Drawing.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Screenshot indicator
    Drawing.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("📸 Screenshot Mode", 0, screenHeight / 2 - 50, screenWidth, "center")
    
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Press SPACE to capture", 0, screenHeight / 2, screenWidth, "center")
    love.graphics.printf("Press ESC to exit", 0, screenHeight / 2 + 30, screenWidth, "center")
end

-- Draw element inspector
function DebugRendering.drawElementInspector(elementName, x, y)
    local trackedElement = DebugValidation.getElement(elementName)
    if not trackedElement then
        return
    end
    
    local element = trackedElement.element
    local panelWidth = 300
    local panelHeight = 200
    local panelX = x + 20
    local panelY = y - panelHeight - 20
    
    -- Adjust position if panel would go off screen
    if panelX + panelWidth > love.graphics.getWidth() then
        panelX = x - panelWidth - 20
    end
    if panelY < 0 then
        panelY = y + 20
    end
    
    -- Inspector background
    Drawing.setColor(DebugRendering.colors.background[1], DebugRendering.colors.background[2], 
                     DebugRendering.colors.background[3], DebugRendering.colors.background[4])
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 8)
    
    -- Inspector border
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 8)
    love.graphics.setLineWidth(1)
    
    -- Element info
    Drawing.setColor(DebugRendering.colors.text[1], DebugRendering.colors.text[2], 
                     DebugRendering.colors.text[3], DebugRendering.colors.text[4])
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Element Inspector", panelX + 10, panelY + 10)
    
    love.graphics.setFont(love.graphics.newFont(12))
    local infoY = panelY + 40
    
    love.graphics.print(string.format("Name: %s", elementName), panelX + 10, infoY)
    infoY = infoY + 20
    love.graphics.print(string.format("Type: %s", trackedElement.type), panelX + 10, infoY)
    infoY = infoY + 20
    love.graphics.print(string.format("Position: (%.1f, %.1f)", element.x or 0, element.y or 0), panelX + 10, infoY)
    infoY = infoY + 20
    love.graphics.print(string.format("Size: %.1f x %.1f", element.width or 0, element.height or 0), panelX + 10, infoY)
    infoY = infoY + 20
    love.graphics.print(string.format("Valid: %s", trackedElement.valid and "Yes" or "No"), panelX + 10, infoY)
    infoY = infoY + 20
    
    -- Issues
    if #trackedElement.issues > 0 then
        love.graphics.print("Issues:", panelX + 10, infoY)
        infoY = infoY + 20
        
        for i, issue in ipairs(trackedElement.issues) do
            if i <= 3 then -- Show only first 3 issues
                local color = issue.severity == "error" and DebugRendering.colors.error or DebugRendering.colors.warning
                Drawing.setColor(color[1], color[2], color[3], color[4])
                love.graphics.print("• " .. issue.issue, panelX + 20, infoY)
                infoY = infoY + 16
            end
        end
    end
end

return DebugRendering 