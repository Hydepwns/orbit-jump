-- Mobile Accessibility System for Orbit Jump
-- Handles WCAG 2.1 AA compliance, touch target sizes, and mobile accessibility features

local Utils = require("src.utils.utils")
local Config = require("src.utils.config")
local MobileAccessibility = {}

-- Accessibility standards
MobileAccessibility.standards = {
    WCAG_AA = {
        minTouchTarget = 44, -- Minimum touch target size in pixels
        minSpacing = 8, -- Minimum spacing between interactive elements
        minContrastRatio = 4.5, -- Minimum contrast ratio for normal text
        minContrastRatioLarge = 3.0, -- Minimum contrast ratio for large text
        minFontSize = 16, -- Minimum font size for readability
        minFontSizeLarge = 18 -- Minimum font size for large text
    },
    iOS = {
        minTouchTarget = 44, -- iOS Human Interface Guidelines
        minSpacing = 8,
        safeAreaMargin = 20 -- Safe area margin for notches
    },
    Android = {
        minTouchTarget = 48, -- Android Material Design
        minSpacing = 8,
        elevation = 2 -- Material elevation for touch feedback
    }
}

-- Current device type detection
MobileAccessibility.deviceType = "desktop" -- desktop, tablet, mobile
MobileAccessibility.screenSize = { width = 800, height = 600 }
MobileAccessibility.dpi = 96 -- Default DPI

-- Accessibility features state
MobileAccessibility.features = {
    highContrast = false,
    largeText = false,
    reducedMotion = false,
    screenReader = false,
    hapticFeedback = true,
    soundFeedback = true
}

-- Initialize mobile accessibility system
function MobileAccessibility.init()
    MobileAccessibility.detectDevice()
    MobileAccessibility.loadSettings()
    MobileAccessibility.validateCompliance()
    
    Utils.Logger.info("Mobile accessibility system initialized for %s device", MobileAccessibility.deviceType)
end

-- Detect device type and capabilities
function MobileAccessibility.detectDevice()
    if not love.window then return end
    
    local width, height = love.graphics.getDimensions()
    MobileAccessibility.screenSize = { width = width, height = height }
    
    -- Detect device type based on screen size
    if width <= 768 or height <= 768 then
        MobileAccessibility.deviceType = "mobile"
    elseif width <= 1024 or height <= 1024 then
        MobileAccessibility.deviceType = "tablet"
    else
        MobileAccessibility.deviceType = "desktop"
    end
    
    -- Detect OS for specific guidelines
    local os = love.system.getOS()
    if os == "iOS" then
        MobileAccessibility.os = "iOS"
    elseif os == "Android" then
        MobileAccessibility.os = "Android"
    else
        MobileAccessibility.os = "desktop"
    end
    
    Utils.Logger.info("Device detected: %s (%s) - %dx%d", 
        MobileAccessibility.deviceType, MobileAccessibility.os, width, height)
end

-- Get minimum touch target size for current device
function MobileAccessibility.getMinTouchTarget()
    if MobileAccessibility.os == "iOS" then
        return MobileAccessibility.standards.iOS.minTouchTarget
    elseif MobileAccessibility.os == "Android" then
        return MobileAccessibility.standards.Android.minTouchTarget
    else
        return MobileAccessibility.standards.WCAG_AA.minTouchTarget
    end
end

-- Validate touch target size
function MobileAccessibility.validateTouchTarget(width, height, elementName)
    local minSize = MobileAccessibility.getMinTouchTarget()
    local issues = {}
    
    if width < minSize then
        table.insert(issues, string.format("Width too small: %dpx (min: %dpx)", width, minSize))
    end
    
    if height < minSize then
        table.insert(issues, string.format("Height too small: %dpx (min: %dpx)", height, minSize))
    end
    
    if #issues > 0 then
        Utils.Logger.warn("Accessibility issue - %s: %s", elementName, table.concat(issues, ", "))
        return false, issues
    end
    
    return true
end

-- Calculate accessible element size
function MobileAccessibility.calculateAccessibleSize(desiredWidth, desiredHeight, elementName)
    local minSize = MobileAccessibility.getMinTouchTarget()
    local width = math.max(desiredWidth, minSize)
    local height = math.max(desiredHeight, minSize)
    
    -- Log if size was increased for accessibility
    if width > desiredWidth or height > desiredHeight then
        Utils.Logger.info("Increased %s size for accessibility: %dx%d -> %dx%d", 
            elementName, desiredWidth, desiredHeight, width, height)
    end
    
    return width, height
end

-- Calculate safe spacing between elements
function MobileAccessibility.calculateSafeSpacing()
    local minSpacing = MobileAccessibility.standards.WCAG_AA.minSpacing
    
    -- Increase spacing for mobile devices
    if MobileAccessibility.deviceType == "mobile" then
        minSpacing = minSpacing * 1.5
    end
    
    return minSpacing
end

-- Validate element spacing
function MobileAccessibility.validateSpacing(element1, element2, minDistance)
    minDistance = minDistance or MobileAccessibility.calculateSafeSpacing()
    
    local center1 = { x = element1.x + element1.width / 2, y = element1.y + element1.height / 2 }
    local center2 = { x = element2.x + element2.width / 2, y = element2.y + element2.height / 2 }
    
    local distance = math.sqrt((center2.x - center1.x)^2 + (center2.y - center1.y)^2)
    
    if distance < minDistance then
        Utils.Logger.warn("Elements too close: %.1fpx (min: %.1fpx)", distance, minDistance)
        return false
    end
    
    return true
end

-- Calculate accessible font size
function MobileAccessibility.calculateFontSize(baseSize)
    local minSize = MobileAccessibility.standards.WCAG_AA.minFontSize
    
    if MobileAccessibility.features.largeText then
        minSize = MobileAccessibility.standards.WCAG_AA.minFontSizeLarge
        baseSize = baseSize * 1.2
    end
    
    return math.max(baseSize, minSize)
end

-- Validate color contrast (simplified)
function MobileAccessibility.validateContrast(foreground, background)
    -- Simplified contrast calculation
    local fgLuminance = MobileAccessibility.calculateLuminance(foreground)
    local bgLuminance = MobileAccessibility.calculateLuminance(background)
    
    local ratio = (math.max(fgLuminance, bgLuminance) + 0.05) / (math.min(fgLuminance, bgLuminance) + 0.05)
    
    local minRatio = MobileAccessibility.standards.WCAG_AA.minContrastRatio
    if MobileAccessibility.features.largeText then
        minRatio = MobileAccessibility.standards.WCAG_AA.minContrastRatioLarge
    end
    
    return ratio >= minRatio, ratio
end

-- Calculate relative luminance
function MobileAccessibility.calculateLuminance(color)
    local r, g, b = color[1], color[2], color[3]
    
    -- Convert to sRGB
    r = r <= 0.03928 and r / 12.92 or ((r + 0.055) / 1.055) ^ 2.4
    g = g <= 0.03928 and g / 12.92 or ((g + 0.055) / 1.055) ^ 2.4
    b = b <= 0.03928 and b / 12.92 or ((b + 0.055) / 1.055) ^ 2.4
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Generate accessible colors
function MobileAccessibility.generateAccessibleColors(baseColor, background)
    local colors = {}
    
    -- High contrast mode
    if MobileAccessibility.features.highContrast then
        colors.text = {1, 1, 1, 1} -- White text
        colors.background = {0, 0, 0, 1} -- Black background
        colors.accent = {1, 1, 0, 1} -- Yellow accent
    else
        colors.text = baseColor
        colors.background = background
        colors.accent = {1, 0.8, 0.2, 1} -- Gold accent
    end
    
    return colors
end

-- Validate UI layout for accessibility
function MobileAccessibility.validateLayout(elements)
    local issues = {}
    local warnings = {}
    
    for name, element in pairs(elements) do
        if element.width and element.height then
            -- Check touch target size
            local isValid, targetIssues = MobileAccessibility.validateTouchTarget(
                element.width, element.height, name)
            
            if not isValid then
                for _, issue in ipairs(targetIssues) do
                    table.insert(issues, string.format("%s: %s", name, issue))
                end
            end
        end
    end
    
    -- Check spacing between elements
    local elementList = {}
    for name, element in pairs(elements) do
        table.insert(elementList, {name = name, element = element})
    end
    
    for i = 1, #elementList do
        for j = i + 1, #elementList do
            local isValid = MobileAccessibility.validateSpacing(
                elementList[i].element, elementList[j].element)
            
            if not isValid then
                table.insert(warnings, string.format("Spacing: %s and %s too close", 
                    elementList[i].name, elementList[j].name))
            end
        end
    end
    
    return issues, warnings
end

-- Apply accessibility fixes to UI elements
function MobileAccessibility.applyAccessibilityFixes(elements)
    local fixes = {}
    
    for name, element in pairs(elements) do
        if element.width and element.height then
            local newWidth, newHeight = MobileAccessibility.calculateAccessibleSize(
                element.width, element.height, name)
            
            if newWidth ~= element.width or newHeight ~= element.height then
                element.width = newWidth
                element.height = newHeight
                table.insert(fixes, string.format("Fixed %s: %dx%d", name, newWidth, newHeight))
            end
        end
    end
    
    return fixes
end

-- Load accessibility settings
function MobileAccessibility.loadSettings()
    local saveSystem = Utils.require("src.systems.save_system")
    if saveSystem and saveSystem.loadAccessibility then
        local saved = saveSystem.loadAccessibility()
        if saved then
            MobileAccessibility.features = saved
        end
    end
end

-- Save accessibility settings
function MobileAccessibility.saveSettings()
    local saveSystem = Utils.require("src.systems.save_system")
    if saveSystem and saveSystem.saveAccessibility then
        saveSystem.saveAccessibility(MobileAccessibility.features)
    end
end

-- Toggle accessibility feature
function MobileAccessibility.toggleFeature(feature)
    if MobileAccessibility.features[feature] ~= nil then
        MobileAccessibility.features[feature] = not MobileAccessibility.features[feature]
        MobileAccessibility.saveSettings()
        
        Utils.Logger.info("Accessibility feature '%s' %s", 
            feature, MobileAccessibility.features[feature] and "enabled" or "disabled")
        
        return MobileAccessibility.features[feature]
    end
    
    return false
end

-- Get accessibility report
function MobileAccessibility.getReport()
    return {
        deviceType = MobileAccessibility.deviceType,
        os = MobileAccessibility.os,
        screenSize = MobileAccessibility.screenSize,
        features = MobileAccessibility.features,
        standards = MobileAccessibility.standards,
        minTouchTarget = MobileAccessibility.getMinTouchTarget()
    }
end

-- Validate overall compliance
function MobileAccessibility.validateCompliance()
    local report = MobileAccessibility.getReport()
    local compliance = {
        deviceType = report.deviceType,
        os = report.os,
        minTouchTarget = report.minTouchTarget,
        features = report.features,
        issues = {},
        warnings = {}
    }
    
    Utils.Logger.info("Accessibility compliance report generated")
    return compliance
end

-- Draw accessibility debug info
function MobileAccessibility.drawDebug()
    if not Config.dev.debugMode then return end
    
    local report = MobileAccessibility.getReport()
    local info = string.format(
        "Device: %s (%s)\nTouch Target: %dpx\nHigh Contrast: %s\nLarge Text: %s",
        report.deviceType,
        report.os,
        report.minTouchTarget,
        report.features.highContrast and "Yes" or "No",
        report.features.largeText and "Yes" or "No"
    )
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(info, 10, 50)
end

return MobileAccessibility 