--[[
    Debug Validation for Orbit Jump
    
    This module handles element validation, layout analysis, and issue detection.
--]]

local DebugConfig = require("src.ui.debug.debug_config")
local DebugLogging = require("src.ui.debug.debug_logging")

local DebugValidation = {}

-- Validation state
DebugValidation.layoutIssues = {}
DebugValidation.trackedElements = {}

-- Validate element structure
function DebugValidation.validateElementStructure(element)
    local issues = {}
    local valid = true
    
    if not element then
        table.insert(issues, "element_is_nil")
        valid = false
    else
        -- Check required properties
        local requiredProps = {"x", "y", "width", "height"}
        for _, prop in ipairs(requiredProps) do
            if element[prop] == nil then
                table.insert(issues, "missing_" .. prop)
                valid = false
            elseif type(element[prop]) ~= "number" then
                table.insert(issues, "invalid_type_" .. prop)
                valid = false
            end
        end
        
        -- Check for negative dimensions
        if element.width and element.width <= 0 then
            table.insert(issues, "invalid_width")
            valid = false
        end
        if element.height and element.height <= 0 then
            table.insert(issues, "invalid_height")
            valid = false
        end
    end
    
    return {
        valid = valid,
        issues = issues
    }
end

-- Register element for tracking
function DebugValidation.registerElement(name, element, parentFrame, metadata)
    local currentTime = love and love.timer and love.timer.getTime() or os.time()
    
    -- Validate element structure
    local validationResult = DebugValidation.validateElementStructure(element)
    
    DebugValidation.trackedElements[name] = {
        element = element,
        parentFrame = parentFrame,
        metadata = metadata or {},
        timestamp = currentTime,
        lastValidation = currentTime,
        type = metadata and metadata.type or "unknown",
        valid = validationResult.valid,
        issues = validationResult.issues,
        changeHistory = {},
        performanceMetrics = {
            renderTime = 0,
            updateTime = 0,
            memoryUsage = 0
        }
    }
    
    -- Log registration
    DebugLogging.logElementRegistration(name, element, validationResult.valid)
    DebugLogging.logValidationIssues(name, validationResult.issues)
    
    return validationResult
end

-- Validate current layout
function DebugValidation.validateCurrentLayout(customRules)
    local startTime = love and love.timer and love.timer.getTime() or os.time()
    local screenWidth = love and love.graphics and love.graphics.getWidth() or 800
    local screenHeight = love and love.graphics and love.graphics.getHeight() or 600
    
    DebugValidation.layoutIssues = {}
    local totalIssues = 0
    local totalElements = 0
    
    -- Get validation rules
    local rules = customRules or DebugConfig.getAllValidationRules()
    
    -- Validate each tracked element
    for name, trackedElement in pairs(DebugValidation.trackedElements) do
        totalElements = totalElements + 1
        local element = trackedElement.element
        local elementIssues = {}
        
        -- Apply validation rules
        for _, rule in ipairs(rules) do
            local ruleIssues = rule.validate(element, screenWidth, screenHeight)
            for _, issue in ipairs(ruleIssues) do
                table.insert(elementIssues, {
                    rule = rule.name,
                    issue = issue,
                    severity = rule.severity,
                    description = rule.description
                })
                totalIssues = totalIssues + 1
            end
        end
        
        -- Store issues for this element
        if #elementIssues > 0 then
            DebugValidation.layoutIssues[name] = elementIssues
        end
        
        -- Update tracked element
        trackedElement.lastValidation = startTime
        trackedElement.issues = elementIssues
        trackedElement.valid = #elementIssues == 0
    end
    
    -- Check for overlapping elements
    DebugValidation.detectOverlaps()
    
    -- Calculate validation time
    local endTime = love and love.timer and love.timer.getTime() or os.time()
    local validationTime = endTime - startTime
    
    -- Log validation results
    DebugLogging.logLayoutValidation(totalIssues, totalElements)
    
    return {
        totalIssues = totalIssues,
        totalElements = totalElements,
        validationTime = validationTime,
        issues = DebugValidation.layoutIssues
    }
end

-- Detect overlapping elements
function DebugValidation.detectOverlaps()
    local elements = {}
    
    -- Collect all valid elements
    for name, trackedElement in pairs(DebugValidation.trackedElements) do
        if trackedElement.valid then
            table.insert(elements, {
                name = name,
                element = trackedElement.element
            })
        end
    end
    
    -- Check for overlaps
    for i = 1, #elements do
        for j = i + 1, #elements do
            local elem1 = elements[i]
            local elem2 = elements[j]
            
            if DebugValidation.elementsOverlap(elem1.element, elem2.element) then
                -- Add overlap issue to both elements
                local overlapIssue = {
                    rule = "overlap_detection",
                    issue = "overlaps_with_" .. elem2.name,
                    severity = "warning",
                    description = "Element overlaps with another element"
                }
                
                if not DebugValidation.layoutIssues[elem1.name] then
                    DebugValidation.layoutIssues[elem1.name] = {}
                end
                table.insert(DebugValidation.layoutIssues[elem1.name], overlapIssue)
                
                if not DebugValidation.layoutIssues[elem2.name] then
                    DebugValidation.layoutIssues[elem2.name] = {}
                end
                table.insert(DebugValidation.layoutIssues[elem2.name], {
                    rule = "overlap_detection",
                    issue = "overlaps_with_" .. elem1.name,
                    severity = "warning",
                    description = "Element overlaps with another element"
                })
            end
        end
    end
end

-- Check if two elements overlap
function DebugValidation.elementsOverlap(elem1, elem2)
    if not elem1 or not elem2 then
        return false
    end
    
    return elem1.x < elem2.x + elem2.width and
           elem1.x + elem1.width > elem2.x and
           elem1.y < elem2.y + elem2.height and
           elem1.y + elem1.height > elem2.y
end

-- Get layout issues
function DebugValidation.getLayoutIssues()
    return DebugValidation.layoutIssues
end

-- Get issues for specific element
function DebugValidation.getElementIssues(elementName)
    return DebugValidation.layoutIssues[elementName] or {}
end

-- Get all tracked elements
function DebugValidation.getTrackedElements()
    return DebugValidation.trackedElements
end

-- Get element by name
function DebugValidation.getElement(name)
    return DebugValidation.trackedElements[name]
end

-- Count tracked elements
function DebugValidation.countTrackedElements()
    local count = 0
    for _ in pairs(DebugValidation.trackedElements) do
        count = count + 1
    end
    return count
end

-- Count layout issues
function DebugValidation.countLayoutIssues()
    local count = 0
    for _, issues in pairs(DebugValidation.layoutIssues) do
        count = count + #issues
    end
    return count
end

-- Get issues by severity
function DebugValidation.getIssuesBySeverity(severity)
    local filteredIssues = {}
    
    for elementName, issues in pairs(DebugValidation.layoutIssues) do
        for _, issue in ipairs(issues) do
            if issue.severity == severity then
                if not filteredIssues[elementName] then
                    filteredIssues[elementName] = {}
                end
                table.insert(filteredIssues[elementName], issue)
            end
        end
    end
    
    return filteredIssues
end

-- Get error issues
function DebugValidation.getErrorIssues()
    return DebugValidation.getIssuesBySeverity("error")
end

-- Get warning issues
function DebugValidation.getWarningIssues()
    return DebugValidation.getIssuesBySeverity("warning")
end

-- Clear all issues
function DebugValidation.clearIssues()
    DebugValidation.layoutIssues = {}
end

-- Reset tracking
function DebugValidation.resetTracking()
    DebugValidation.trackedElements = {}
    DebugValidation.layoutIssues = {}
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Debug validation tracking reset")
end

-- Export validation data
function DebugValidation.exportValidationData()
    return {
        trackedElements = DebugValidation.trackedElements,
        layoutIssues = DebugValidation.layoutIssues,
        summary = {
            totalElements = DebugValidation.countTrackedElements(),
            totalIssues = DebugValidation.countLayoutIssues(),
            errorCount = #DebugValidation.getErrorIssues(),
            warningCount = #DebugValidation.getWarningIssues()
        },
        exportTime = os.date("%Y-%m-%d %H:%M:%S")
    }
end

return DebugValidation 