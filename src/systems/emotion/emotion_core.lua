--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotion Core: Central emotional state management and transitions
    ═══════════════════════════════════════════════════════════════════════════
    This module manages the core emotional state, transitions, and base emotion
    types. It provides the foundation for the emotional feedback system.
--]]
local Utils = require("src.utils.utils")
local EmotionCore = {}
-- Player's current emotional trajectory
local emotionalState = {
    confidence = 0.5,        -- 0-1: How confident the player feels
    momentum = 0.0,          -- -1 to 1: Current emotional momentum
    achievement_streak = 0,   -- Recent successes in a row
    last_celebration = 0,     -- Time since last major celebration
    flow_state_duration = 0, -- Time spent in uninterrupted flow
    surprise_cooldown = 0     -- Prevents feedback fatigue
}
-- Emotional event history for building narrative arcs
local emotionalMemory = {
    first_successful_jump = false,
    longest_chain = 0,
    highest_speed_achieved = 0,
    most_planets_visited = 0,
    dramatic_saves = 0,        -- Near-miss recoveries
    perfect_landings = 0       -- Frame-perfect arrivals
}
-- Current mood state
local currentMood = { type = "neutral", intensity = 0.5 }
-- Pre-allocated feedback configuration (zero allocation during gameplay)
local feedbackConfigs = {
    jump = {
        baseIntensity = 0.3,
        powerMultiplier = 0.7,
        maxIntensity = 1.0,
        celebrationThreshold = 0.8
    },
    landing = {
        baseIntensity = 0.4,
        speedMultiplier = 0.6,
        perfectBonus = 0.3,
        gentleBonus = 0.2
    },
    dash = {
        baseIntensity = 0.6,
        cooldownPenalty = 0.3,
        emergencyBonus = 0.4
    },
    achievement = {
        baseIntensity = 0.8,
        streakMultiplier = 0.1,
        surpriseBonus = 0.2
    }
}
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Core Emotional State Management
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionCore.init()
    emotionalState.confidence = 0.5
    emotionalState.momentum = 0.0
    emotionalState.achievement_streak = 0
    emotionalState.last_celebration = 0
    emotionalState.flow_state_duration = 0
    emotionalState.surprise_cooldown = 0
    currentMood = { type = "neutral", intensity = 0.5 }
    Utils.Logger.info("💝 Emotion Core initialized")
    return true
end
function EmotionCore.update(dt)
    -- Confidence naturally drifts toward neutral (0.5) over time
    local CONFIDENCE_DECAY = 0.1 * dt
    if emotionalState.confidence > 0.5 then
        emotionalState.confidence = math.max(0.5, emotionalState.confidence - CONFIDENCE_DECAY)
    elseif emotionalState.confidence < 0.5 then
        emotionalState.confidence = math.min(0.5, emotionalState.confidence + CONFIDENCE_DECAY)
    end
    -- Momentum decays toward zero (natural emotional settling)
    local MOMENTUM_DECAY = 0.8 * dt
    emotionalState.momentum = emotionalState.momentum * (1 - MOMENTUM_DECAY)
    -- Update timers
    emotionalState.last_celebration = emotionalState.last_celebration + dt
    emotionalState.flow_state_duration = emotionalState.flow_state_duration + dt
    emotionalState.surprise_cooldown = math.max(0, emotionalState.surprise_cooldown - dt)
    -- Achievement streak decays if no recent successes
    if emotionalState.last_celebration > 5.0 then  -- 5 seconds of no achievements
        emotionalState.achievement_streak = math.max(0, emotionalState.achievement_streak - 1)
    end
    -- Decay mood intensity over time
    if currentMood and type(currentMood) == "table" and currentMood.intensity then
        local MOOD_DECAY = 0.2 * dt
        local newIntensity = math.max(0, currentMood.intensity - MOOD_DECAY)
        -- Update the intensity in place
        currentMood.intensity = newIntensity
        -- Reset to neutral if intensity is too low
        if newIntensity < 0.1 then
            currentMood = { type = "neutral", intensity = 0.5 }
        end
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotional State Transitions
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionCore.transitionToMood(moodType, intensity)
    currentMood = { type = moodType, intensity = intensity or 0.5 }
end
function EmotionCore.updateConfidence(delta)
    emotionalState.confidence = math.max(0, math.min(1, emotionalState.confidence + delta))
end
function EmotionCore.updateMomentum(delta)
    emotionalState.momentum = math.max(-1, math.min(1, emotionalState.momentum + delta))
end
function EmotionCore.incrementStreak()
    emotionalState.achievement_streak = emotionalState.achievement_streak + 1
    emotionalState.last_celebration = 0
end
function EmotionCore.resetStreak()
    emotionalState.achievement_streak = math.max(0, emotionalState.achievement_streak - 1)
end
function EmotionCore.startSurpriseCooldown(duration)
    emotionalState.surprise_cooldown = duration or 3.0
end
function EmotionCore.canTriggerSurprise()
    return emotionalState.surprise_cooldown <= 0
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotional Memory Management
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionCore.recordFirstJump()
    emotionalMemory.first_successful_jump = true
end
function EmotionCore.hasFirstJump()
    return emotionalMemory.first_successful_jump
end
function EmotionCore.recordPerfectLanding()
    emotionalMemory.perfect_landings = emotionalMemory.perfect_landings + 1
end
function EmotionCore.recordDramaticSave()
    emotionalMemory.dramatic_saves = emotionalMemory.dramatic_saves + 1
end
function EmotionCore.updateLongestChain(chain)
    emotionalMemory.longest_chain = math.max(emotionalMemory.longest_chain, chain)
end
function EmotionCore.updateHighestSpeed(speed)
    emotionalMemory.highest_speed_achieved = math.max(emotionalMemory.highest_speed_achieved, speed)
end
function EmotionCore.updatePlanetsVisited(count)
    emotionalMemory.most_planets_visited = math.max(emotionalMemory.most_planets_visited, count)
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Configuration and State Accessors
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionCore.getConfig(actionType)
    return feedbackConfigs[actionType]
end
function EmotionCore.getEmotionalState()
    return {
        confidence = emotionalState.confidence,
        momentum = emotionalState.momentum,
        streak = emotionalState.achievement_streak,
        flow_duration = emotionalState.flow_state_duration
    }
end
function EmotionCore.getEmotionalMemory()
    return Utils.deepCopy(emotionalMemory)
end
function EmotionCore.getCurrentMood()
    return currentMood
end
function EmotionCore.getDebugInfo()
    return {
        state = emotionalState,
        memory = emotionalMemory,
        mood = currentMood
    }
end
return EmotionCore