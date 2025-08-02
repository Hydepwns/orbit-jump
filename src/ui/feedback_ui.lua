--[[
    Feedback UI System - User Interface for Data Collection
    
    Handles user consent, micro-surveys, and feedback submission
    with a focus on privacy and user experience.
--]]

local Utils = require("src.utils.utils")
local FeedbackUI = {}

-- UI state
FeedbackUI.showConsentDialog = false
FeedbackUI.showSentimentSurvey = false
FeedbackUI.currentSurvey = nil
FeedbackUI.surveyResponse = nil

-- UI configuration
FeedbackUI.config = {
    survey_display_duration = 10.0, -- Auto-dismiss after 10 seconds
    consent_reminder_interval = 86400, -- 24 hours
    survey_animation_speed = 2.0
}

-- Animation state
FeedbackUI.consentAlpha = 0
FeedbackUI.surveyAlpha = 0
FeedbackUI.surveyScale = 0.8

-- Initialize feedback UI
function FeedbackUI.init()
    FeedbackUI.showConsentDialog = not FeedbackUI.hasShownConsentThisSession()
    FeedbackUI.showSentimentSurvey = false
    FeedbackUI.currentSurvey = nil
    
    return true
end

-- Check if consent dialog has been shown this session
function FeedbackUI.hasShownConsentThisSession()
    -- Simple session tracking - in a real implementation, 
    -- you might want more sophisticated tracking
    return FeedbackUI.consentShownThisSession or false
end

-- Update feedback UI
function FeedbackUI.update(dt)
    -- Update consent dialog animation
    if FeedbackUI.showConsentDialog then
        FeedbackUI.consentAlpha = math.min(1.0, FeedbackUI.consentAlpha + dt * FeedbackUI.config.survey_animation_speed)
    else
        FeedbackUI.consentAlpha = math.max(0.0, FeedbackUI.consentAlpha - dt * FeedbackUI.config.survey_animation_speed)
    end
    
    -- Update survey animation
    if FeedbackUI.showSentimentSurvey then
        FeedbackUI.surveyAlpha = math.min(1.0, FeedbackUI.surveyAlpha + dt * FeedbackUI.config.survey_animation_speed)
        FeedbackUI.surveyScale = math.min(1.0, FeedbackUI.surveyScale + dt * FeedbackUI.config.survey_animation_speed)
    else
        FeedbackUI.surveyAlpha = math.max(0.0, FeedbackUI.surveyAlpha - dt * FeedbackUI.config.survey_animation_speed)
        FeedbackUI.surveyScale = math.max(0.8, FeedbackUI.surveyScale - dt * FeedbackUI.config.survey_animation_speed)
    end
    
    -- Check for pending sentiment surveys
    if not FeedbackUI.showSentimentSurvey and not FeedbackUI.currentSurvey then
        local FeedbackSystem = Utils.require("src.systems.feedback_system")
        if FeedbackSystem then
            local pendingSurveys = FeedbackSystem.getPendingSentimentSurveys()
            if #pendingSurveys > 0 then
                FeedbackUI.showSentimentSurvey(pendingSurveys[1])
            end
        end
    end
    
    -- Auto-dismiss survey after timeout
    if FeedbackUI.currentSurvey then
        FeedbackUI.currentSurvey.timeShown = (FeedbackUI.currentSurvey.timeShown or 0) + dt
        if FeedbackUI.currentSurvey.timeShown > FeedbackUI.config.survey_display_duration then
            FeedbackUI.dismissCurrentSurvey()
        end
    end
end

-- Show sentiment survey
function FeedbackUI.showSentimentSurvey(survey)
    FeedbackUI.currentSurvey = survey
    FeedbackUI.currentSurvey.timeShown = 0
    FeedbackUI.showSentimentSurvey = true
    FeedbackUI.surveyResponse = nil
end

-- Dismiss current survey
function FeedbackUI.dismissCurrentSurvey()
    FeedbackUI.showSentimentSurvey = false
    FeedbackUI.currentSurvey = nil
    FeedbackUI.surveyResponse = nil
end

-- Handle user input
function FeedbackUI.handleInput(key)
    -- Handle consent dialog
    if FeedbackUI.showConsentDialog and FeedbackUI.consentAlpha > 0.5 then
        if key == "y" or key == "space" or key == "return" then
            FeedbackUI.acceptConsent()
            return true
        elseif key == "n" or key == "escape" then
            FeedbackUI.declineConsent()
            return true
        end
    end
    
    -- Handle sentiment survey
    if FeedbackUI.showSentimentSurvey and FeedbackUI.surveyAlpha > 0.5 and FeedbackUI.currentSurvey then
        local options = FeedbackUI.currentSurvey.options
        if key >= "1" and key <= tostring(#options) then
            local optionIndex = tonumber(key)
            FeedbackUI.submitSurveyResponse(options[optionIndex])
            return true
        elseif key == "escape" then
            FeedbackUI.dismissCurrentSurvey()
            return true
        end
    end
    
    return false
end

-- Accept data collection consent
function FeedbackUI.acceptConsent()
    local FeedbackSystem = Utils.require("src.systems.feedback_system")
    if FeedbackSystem then
        FeedbackSystem.saveConsentStatus(true)
    end
    
    FeedbackUI.showConsentDialog = false
    FeedbackUI.consentShownThisSession = true
    
    Utils.Logger.info("User accepted feedback consent")
end

-- Decline data collection consent
function FeedbackUI.declineConsent()
    local FeedbackSystem = Utils.require("src.systems.feedback_system")
    if FeedbackSystem then
        FeedbackSystem.saveConsentStatus(false)
    end
    
    FeedbackUI.showConsentDialog = false
    FeedbackUI.consentShownThisSession = true
    
    Utils.Logger.info("User declined feedback consent")
end

-- Submit survey response
function FeedbackUI.submitSurveyResponse(response)
    if not FeedbackUI.currentSurvey then
        return
    end
    
    local FeedbackSystem = Utils.require("src.systems.feedback_system")
    if FeedbackSystem then
        FeedbackSystem.submitSentimentResponse(FeedbackUI.currentSurvey.id, response)
    end
    
    FeedbackUI.surveyResponse = response
    
    -- Show brief confirmation then dismiss
    Utils.Logger.info("Survey response submitted: %s", response)
    
    -- Delay dismissal to show confirmation
    love.timer.sleep = love.timer.sleep or function() end
    FeedbackUI.dismissCurrentSurvey()
end

-- Draw feedback UI
function FeedbackUI.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw consent dialog
    if FeedbackUI.consentAlpha > 0 then
        FeedbackUI.drawConsentDialog(screenWidth, screenHeight)
    end
    
    -- Draw sentiment survey
    if FeedbackUI.surveyAlpha > 0 then
        FeedbackUI.drawSentimentSurvey(screenWidth, screenHeight)
    end
end

-- Draw consent dialog
function FeedbackUI.drawConsentDialog(screenWidth, screenHeight)
    local alpha = FeedbackUI.consentAlpha
    
    -- Background overlay
    Utils.setColor({0, 0, 0}, alpha * 0.6)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Dialog box
    local dialogWidth = 500
    local dialogHeight = 300
    local dialogX = (screenWidth - dialogWidth) / 2
    local dialogY = (screenHeight - dialogHeight) / 2
    
    -- Dialog background
    Utils.setColor({0.1, 0.1, 0.2}, alpha * 0.95)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight, 10)
    
    -- Dialog border
    Utils.setColor({0.3, 0.5, 0.8}, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX, dialogY, dialogWidth, dialogHeight, 10)
    love.graphics.setLineWidth(1)
    
    -- Title
    Utils.setColor({1, 1, 1}, alpha)
    love.graphics.setFont(love.graphics.newFont(18))
    local title = "Help Improve Orbit Jump!"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, dialogX + (dialogWidth - titleWidth) / 2, dialogY + 20)
    
    -- Description
    Utils.setColor({0.9, 0.9, 0.9}, alpha)
    love.graphics.setFont(love.graphics.newFont(14))
    local description = {
        "We'd like to collect anonymous gameplay data to improve",
        "your experience. This includes:",
        "",
        "• Performance metrics (FPS, load times)",
        "• Gameplay balance data (streaks, progression)",
        "• Optional micro-surveys for feedback",
        "",
        "All data is anonymous and stored locally.",
        "You can change this setting anytime in options."
    }
    
    for i, line in ipairs(description) do
        local lineY = dialogY + 60 + (i - 1) * 20
        love.graphics.print(line, dialogX + 20, lineY)
    end
    
    -- Buttons
    local buttonY = dialogY + dialogHeight - 60
    local buttonWidth = 100
    local buttonHeight = 35
    
    -- Accept button
    local acceptX = dialogX + dialogWidth / 2 - buttonWidth - 10
    Utils.setColor({0.2, 0.7, 0.2}, alpha * 0.8)
    love.graphics.rectangle("fill", acceptX, buttonY, buttonWidth, buttonHeight, 5)
    Utils.setColor({1, 1, 1}, alpha)
    love.graphics.setFont(love.graphics.newFont(14))
    local acceptText = "Accept (Y)"
    local acceptWidth = love.graphics.getFont():getWidth(acceptText)
    love.graphics.print(acceptText, acceptX + (buttonWidth - acceptWidth) / 2, buttonY + 10)
    
    -- Decline button
    local declineX = dialogX + dialogWidth / 2 + 10
    Utils.setColor({0.7, 0.2, 0.2}, alpha * 0.8)
    love.graphics.rectangle("fill", declineX, buttonY, buttonWidth, buttonHeight, 5)
    Utils.setColor({1, 1, 1}, alpha)
    local declineText = "Decline (N)"
    local declineWidth = love.graphics.getFont():getWidth(declineText)
    love.graphics.print(declineText, declineX + (buttonWidth - declineWidth) / 2, buttonY + 10)
end

-- Draw sentiment survey
function FeedbackUI.drawSentimentSurvey(screenWidth, screenHeight)
    if not FeedbackUI.currentSurvey then
        return
    end
    
    local alpha = FeedbackUI.surveyAlpha
    local scale = FeedbackUI.surveyScale
    
    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 2)
    love.graphics.scale(scale, scale)
    
    -- Survey box dimensions
    local surveyWidth = 400
    local surveyHeight = 200
    local surveyX = -surveyWidth / 2
    local surveyY = -surveyHeight / 2
    
    -- Background
    Utils.setColor({0.05, 0.05, 0.15}, alpha * 0.95)
    love.graphics.rectangle("fill", surveyX, surveyY, surveyWidth, surveyHeight, 8)
    
    -- Border
    Utils.setColor({0.3, 0.6, 1.0}, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", surveyX, surveyY, surveyWidth, surveyHeight, 8)
    love.graphics.setLineWidth(1)
    
    -- Question
    Utils.setColor({1, 1, 1}, alpha)
    love.graphics.setFont(love.graphics.newFont(16))
    local question = FeedbackUI.currentSurvey.question
    local questionWidth = love.graphics.getFont():getWidth(question)
    love.graphics.print(question, -questionWidth / 2, surveyY + 20)
    
    -- Options
    Utils.setColor({0.9, 0.9, 0.9}, alpha)
    love.graphics.setFont(love.graphics.newFont(14))
    local options = FeedbackUI.currentSurvey.options
    local optionStartY = surveyY + 60
    
    for i, option in ipairs(options) do
        local optionY = optionStartY + (i - 1) * 25
        local optionText = string.format("%d. %s", i, option)
        local optionWidth = love.graphics.getFont():getWidth(optionText)
        love.graphics.print(optionText, -optionWidth / 2, optionY)
    end
    
    -- Instructions
    Utils.setColor({0.7, 0.7, 0.7}, alpha * 0.8)
    love.graphics.setFont(love.graphics.newFont(12))
    local instructions = "Press number key to respond, ESC to skip"
    local instrWidth = love.graphics.getFont():getWidth(instructions)
    love.graphics.print(instructions, -instrWidth / 2, surveyY + surveyHeight - 25)
    
    love.graphics.pop()
end

-- Toggle consent dialog
function FeedbackUI.toggleConsentDialog()
    FeedbackUI.showConsentDialog = not FeedbackUI.showConsentDialog
end

-- Check if any UI is active
function FeedbackUI.isUIActive()
    return FeedbackUI.showConsentDialog or FeedbackUI.showSentimentSurvey
end

return FeedbackUI