--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotional Feedback System: The Art of Making Players Feel Amazing
    ═══════════════════════════════════════════════════════════════════════════
    This system transforms mechanical game interactions into emotionally
    resonant experiences. Every successful action becomes a small celebration,
    every failure becomes an opportunity for dramatic comeback, and every
    moment of gameplay contributes to a larger emotional journey.
    Emotional Design Philosophy:
    • Layered Feedback: Multiple sensory channels reinforce the same emotion
    • Progressive Intensity: Better actions feel progressively more satisfying
    • Emotional Memory: The system remembers and builds on player achievements
    • Surprise and Delight: Unexpected positive feedback creates memorable moments
    • Flow State Protection: Never interrupt the player's focus, only enhance it
    This is where technical excellence meets human psychology to create joy.
    REFACTORED: This module now acts as a facade, coordinating between:
    - EmotionCore: State management and transitions
    - FeedbackRenderer: Visual, audio, and haptic feedback
    - EmotionAnalytics: Pattern tracking and analysis
--]]
local Utils = require("src.utils.utils")
local EmotionCore = require("src.systems.emotion.emotion_core")
local FeedbackRenderer = require("src.systems.emotion.feedback_renderer")
-- Use optimized version instead of deprecated one
local EmotionAnalytics = require("src.systems.emotion.emotion_analytics_optimized")
local EmotionalFeedback = {}
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Facade Pattern: Coordinating Emotional Systems
    ═══════════════════════════════════════════════════════════════════════════
--]]
-- Backwards compatibility: expose internal state for legacy code
EmotionalFeedback.emotions = nil      -- Will be set during init
EmotionalFeedback.currentMood = nil   -- Will be set during init
--[[
    ═══════════════════════════════════════════════════════════════════════════
    System Initialization and Coordination
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionalFeedback.init()
    -- Initialize all subsystems
    EmotionCore.init()
    EmotionAnalytics.init()
    -- Set up backwards compatibility references
    EmotionalFeedback.emotions = EmotionCore.getEmotionalState()
    EmotionalFeedback.currentMood = EmotionCore.getCurrentMood()
    Utils.Logger.info("💝 Emotional feedback system initialized - Ready to create joy")
    return true
end
function EmotionalFeedback.processEvent(eventType, params)
    --[[
        Central event processing router for the emotional feedback system
        Delegates to specific handlers and coordinates feedback
    --]]
    local previousMood = EmotionCore.getCurrentMood()
    local intensity = 0.5
    if eventType == "landing" then
        local player = params.player or {x = 0, y = 0, vx = 0, vy = 0}
        local planet = params.planet or {type = "normal"}
        local speed = params.speed or 100
        local isGentle = speed < 100
        intensity = EmotionalFeedback.onLanding(player, planet, speed, isGentle)
        -- Update mood based on landing quality
        if speed < 50 then
            EmotionCore.transitionToMood("perfect", 1.0)
        elseif speed < 100 then
            EmotionCore.transitionToMood("smooth", 0.8)
        elseif speed < 200 then
            EmotionCore.transitionToMood("excited", 0.7)
        else
            EmotionCore.transitionToMood("intense", 0.6)
        end
    elseif eventType == "jump" then
        local pullPower = params.pullPower or 0.5
        local jumpSuccess = params.success ~= false
        local isFirstJump = params.isFirstJump or false
        intensity = EmotionalFeedback.onJump(pullPower, jumpSuccess, isFirstJump)
        EmotionCore.transitionToMood("energetic", 0.7 + pullPower * 0.3)
    elseif eventType == "dash" then
        local isEmergency = params.emergency or false
        local dashSuccess = params.success ~= false
        intensity = EmotionalFeedback.onDash(isEmergency, dashSuccess)
        EmotionCore.transitionToMood("powerful", isEmergency and 0.9 or 0.7)
    elseif eventType == "achievement" then
        EmotionalFeedback.triggerSpecialCelebration(params.type or "generic")
        EmotionCore.transitionToMood("triumphant", 1.0)
        intensity = 1.0
    elseif eventType == "failure" then
        intensity = EmotionalFeedback.onFailure(params.type or "generic")
        EmotionCore.transitionToMood("determined", 0.4)
    elseif eventType == "combo" then
        local count = params.count or 0
        for i = 1, count do
            EmotionCore.incrementStreak()
        end
        EmotionCore.updateConfidence(count * 0.05)
        EmotionCore.transitionToMood(count > 5 and "triumphant" or "excited", math.min(1.0, 0.5 + count * 0.1))
        intensity = math.min(1.0, 0.5 + count * 0.1)
    elseif eventType == "near_miss" then
        EmotionCore.updateMomentum(0.3)
        EmotionCore.transitionToMood("intense", 0.8)
        EmotionCore.recordDramaticSave()
        intensity = 0.8
    elseif eventType == "discovery" then
        EmotionalFeedback.triggerSpecialCelebration("discovery")
        EmotionCore.transitionToMood("excited", 0.9)
        EmotionCore.updateConfidence(0.2)
        intensity = 0.9
    end
    -- Record mood change for analytics
    local currentMood = EmotionCore.getCurrentMood()
    EmotionAnalytics.recordMoodChange(
        previousMood.type,
        currentMood.type,
        eventType,
        intensity
    )
    -- Update backwards compatibility references
    EmotionalFeedback.emotions = EmotionCore.getEmotionalState()
    EmotionalFeedback.currentMood = currentMood
end
function EmotionalFeedback.update(dt)
    --[[
        System Update: Coordinates updates across all subsystems
    --]]
    -- Update all subsystems
    EmotionCore.update(dt)
    EmotionAnalytics.update(dt)
    -- Update backwards compatibility references
    EmotionalFeedback.emotions = EmotionCore.getEmotionalState()
    EmotionalFeedback.currentMood = EmotionCore.getCurrentMood()
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Specific Emotional Events: The Moments That Matter
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionalFeedback.onJump(pullPower, jumpSuccess, isFirstJump)
    if not jumpSuccess then
        return EmotionalFeedback.onFailure("jump_blocked")
    end
    -- Calculate emotional intensity based on pull power and context
    local config = EmotionCore.getConfig("jump")
    local baseIntensity = config.baseIntensity
    local powerBonus = pullPower * config.powerMultiplier
    local intensity = math.min(baseIntensity + powerBonus, config.maxIntensity)
    -- First jump ever is a special moment
    if isFirstJump and not EmotionCore.hasFirstJump() then
        EmotionCore.recordFirstJump()
        intensity = intensity + 0.4  -- Extra celebration for first success
        EmotionalFeedback.triggerSpecialCelebration("first_jump")
    end
    -- Build momentum and confidence
    EmotionCore.updateMomentum(intensity * 0.5)
    EmotionCore.updateConfidence(intensity * 0.3)
    EmotionCore.incrementStreak()
    -- Generate layered feedback
    local params = {
        pullPower = pullPower,
        isFirstJump = isFirstJump,
        streak = EmotionCore.getEmotionalState().streak
    }
    FeedbackRenderer.triggerMultiSensory("jump", intensity, params)
    return intensity
end
function EmotionalFeedback.onLanding(player, planet, landingSpeed, isGentle)
    local config = EmotionCore.getConfig("landing")
    local baseIntensity = config.baseIntensity
    -- Speed creates excitement (but too much speed might be scary)
    local speedBonus = math.min(landingSpeed / 1000, 1.0) * config.speedMultiplier
    -- Gentle landings have their own appeal
    local gentleBonus = isGentle and config.gentleBonus or 0
    -- Check for perfect landing (within perfect timing window)
    local isPerfect = EmotionalFeedback.checkPerfectLanding(player, planet)
    local perfectBonus = isPerfect and config.perfectBonus or 0
    if isPerfect then
        EmotionCore.recordPerfectLanding()
    end
    local intensity = baseIntensity + speedBonus + gentleBonus + perfectBonus
    -- Update emotional state
    EmotionCore.updateConfidence(intensity * 0.2)
    EmotionCore.updateMomentum(intensity * 0.3)
    -- Special feedback for perfect landings
    if isPerfect then
        EmotionalFeedback.triggerSpecialCelebration("perfect_landing")
    end
    FeedbackRenderer.triggerMultiSensory("landing", intensity, {speed = landingSpeed, x = player.x, y = player.y})
    return intensity
end
function EmotionalFeedback.onDash(isEmergencyDash, dashSuccess)
    if not dashSuccess then
        return EmotionalFeedback.onFailure("dash_failed")
    end
    local config = EmotionCore.getConfig("dash")
    local intensity = config.baseIntensity
    -- Emergency dashes feel more heroic
    if isEmergencyDash then
        intensity = intensity + config.emergencyBonus
        EmotionCore.recordDramaticSave()
    end
    -- Update emotional state (dashing builds confidence quickly)
    EmotionCore.updateConfidence(intensity * 0.4)
    EmotionCore.updateMomentum(intensity * 0.6)
    FeedbackRenderer.triggerMultiSensory("dash", intensity, {emergency = isEmergencyDash})
    return intensity
end
function EmotionalFeedback.onFailure(failureType)
    -- Reduce momentum and confidence slightly
    EmotionCore.updateMomentum(-0.2)
    EmotionCore.updateConfidence(-0.1)
    -- Reset achievement streak (but gently)
    EmotionCore.resetStreak()
    -- Different failure types might have different feedback
    local intensity = 0.2  -- Gentle disappointment, not punishment
    FeedbackRenderer.triggerMultiSensory("failure", intensity, {type = failureType})
    return intensity
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Backwards Compatibility: Legacy Function Wrappers
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionalFeedback.triggerMultiSensoryFeedback(actionType, intensity, params)
    -- Delegate to FeedbackRenderer for backwards compatibility
    FeedbackRenderer.triggerMultiSensory(actionType, intensity, params)
end
function EmotionalFeedback.triggerVisualFeedback(actionType, intensity, params)
    -- Delegate to FeedbackRenderer for backwards compatibility
    FeedbackRenderer.triggerVisual(actionType, intensity, params)
end
function EmotionalFeedback.triggerAudioFeedback(actionType, intensity, params)
    -- Delegate to FeedbackRenderer for backwards compatibility
    FeedbackRenderer.triggerAudio(actionType, intensity, params)
end
function EmotionalFeedback.triggerHapticFeedback(actionType, intensity, params)
    -- Delegate to FeedbackRenderer for backwards compatibility
    FeedbackRenderer.triggerHaptic(actionType, intensity, params)
end
function EmotionalFeedback.triggerCameraFeedback(actionType, intensity, params)
    -- Delegate to FeedbackRenderer for backwards compatibility
    FeedbackRenderer.triggerCamera(actionType, intensity, params)
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Special Celebrations and Milestone Recognition
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionalFeedback.triggerSpecialCelebration(achievementType)
    if not EmotionCore.canTriggerSurprise() then
        return  -- Prevent celebration fatigue
    end
    EmotionCore.startSurpriseCooldown(3.0)
    local GameState = Utils.require("src.core.game_state")
    local player = GameState and GameState.player
    local params = {
        x = player and player.x or 0,
        y = player and player.y or 0
    }
    if achievementType == "first_jump" then
        FeedbackRenderer.createCelebration("first_success", params)
    elseif achievementType == "perfect_landing" then
        FeedbackRenderer.createCelebration("mastery", params)
    elseif achievementType == "discovery" then
        FeedbackRenderer.createCelebration("discovery", params)
    end
end
function EmotionalFeedback.createCelebrationBurst(celebrationType, config)
    -- Delegate to FeedbackRenderer for backwards compatibility
    local params = { x = 0, y = 0 }
    FeedbackRenderer.createCelebration(celebrationType, params)
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionalFeedback.checkPerfectLanding(player, planet)
    --[[
        Detect frame-perfect landings for special recognition
        Perfect landings occur when the player lands within a very tight
        timing window, demonstrating mastery of the game mechanics.
    --]]
    -- Calculate approach angle and speed for perfect landing detection
    local approachSpeed = Utils.fastDistance(0, 0, player.vx, player.vy)
    local planetDistance = Utils.fastDistance(player.x, player.y, planet.x, planet.y)
    -- Perfect landing criteria (these would be tuned through playtesting)
    local PERFECT_SPEED_RANGE = {50, 150}    -- Ideal landing speed
    local PERFECT_ANGLE_TOLERANCE = 0.1      -- Radians from optimal approach
    local isPerfectSpeed = approachSpeed >= PERFECT_SPEED_RANGE[1] and
                          approachSpeed <= PERFECT_SPEED_RANGE[2]
    -- Add more sophisticated perfect landing detection here
    -- (angle analysis, timing windows, etc.)
    return isPerfectSpeed  -- Simplified for now
end
function EmotionalFeedback.getEmotionalState()
    -- Delegate to EmotionCore for backwards compatibility
    return EmotionCore.getEmotionalState()
end
function EmotionalFeedback.getEmotionalMemory()
    -- Delegate to EmotionCore for backwards compatibility
    return EmotionCore.getEmotionalMemory()
end
function EmotionalFeedback.getFeedbackMessage()
    -- Delegate to FeedbackRenderer for backwards compatibility
    local currentMood = EmotionCore.getCurrentMood()
    return FeedbackRenderer.getFeedbackMessage(currentMood.type)
end
function EmotionalFeedback.getVisualEffects()
    -- Delegate to FeedbackRenderer for backwards compatibility
    local emotionalState = EmotionCore.getEmotionalState()
    local currentMood = EmotionCore.getCurrentMood()
    return FeedbackRenderer.getVisualEffects(emotionalState, currentMood)
end
function EmotionalFeedback.getAudioCue()
    -- Delegate to FeedbackRenderer for backwards compatibility
    local currentMood = EmotionCore.getCurrentMood()
    return FeedbackRenderer.getAudioCue(currentMood.type, currentMood.intensity)
end
function EmotionalFeedback.debugEmotionalState()
    local debugInfo = EmotionCore.getDebugInfo()
    local emotionalState = debugInfo.state
    local emotionalMemory = debugInfo.memory
    local currentMood = debugInfo.mood
    Utils.Logger.info("🎭 Emotional State Debug:")
    Utils.Logger.info("  Confidence: %.2f (%.0f%%)", emotionalState.confidence, emotionalState.confidence * 100)
    Utils.Logger.info("  Momentum: %.2f", emotionalState.momentum)
    Utils.Logger.info("  Achievement Streak: %d", emotionalState.achievement_streak)
    Utils.Logger.info("  Flow Duration: %.1fs", emotionalState.flow_state_duration)
    Utils.Logger.info("  Perfect Landings: %d", emotionalMemory.perfect_landings)
    Utils.Logger.info("  Dramatic Saves: %d", emotionalMemory.dramatic_saves)
    -- Emotional interpretation
    local mood = "Neutral"
    if emotionalState.confidence > 0.8 then
        mood = "Confident"
    elseif emotionalState.confidence > 0.6 then
        mood = "Positive"
    elseif emotionalState.confidence < 0.3 then
        mood = "Uncertain"
    end
    local energy = "Calm"
    if math.abs(emotionalState.momentum) > 0.6 then
        energy = emotionalState.momentum > 0 and "Excited" or "Frustrated"
    elseif math.abs(emotionalState.momentum) > 0.3 then
        energy = emotionalState.momentum > 0 and "Engaged" or "Disappointed"
    end
    Utils.Logger.info("  Current Mood: %s | Energy: %s", mood, energy)
    Utils.Logger.info("  Active Mood: %s (%.1f)", currentMood.type, currentMood.intensity)
    -- Analytics debug info
    local analyticsInfo = EmotionAnalytics.getDebugInfo()
    Utils.Logger.info("  Analytics: %d moods, %d patterns, %d transitions",
                     analyticsInfo.sessionMoods, analyticsInfo.patterns, analyticsInfo.transitions)
end
return EmotionalFeedback