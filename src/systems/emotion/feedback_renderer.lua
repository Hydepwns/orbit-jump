--[[
    ═══════════════════════════════════════════════════════════════════════════
    Feedback Renderer: Visual, audio, and haptic feedback generation
    ═══════════════════════════════════════════════════════════════════════════
    This module handles all rendering aspects of emotional feedback including
    particles, visual effects, audio cues, and haptic feedback.
--]]
local Utils = require("src.utils.utils")
local FeedbackRenderer = {}
-- Pre-allocated celebration configurations
local celebrationConfigs = {
    first_success = {
        particleCount = 20,
        colors = {{1, 1, 0.5, 1}, {1, 0.8, 0.3, 1}},  -- Golden celebration
        duration = 1.5,
        intensity = 1.0
    },
    mastery = {
        particleCount = 15,
        colors = {{0.5, 1, 1, 1}, {0.3, 0.8, 1, 1}},  -- Crystal blue perfection
        duration = 1.0,
        intensity = 0.8
    },
    discovery = {
        particleCount = 25,
        colors = {{1, 0.5, 1, 1}, {0.8, 0.3, 1, 1}},  -- Purple discovery
        duration = 1.8,
        intensity = 0.9
    }
}
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Multi-Sensory Feedback Orchestration
    ═══════════════════════════════════════════════════════════════════════════
--]]
function FeedbackRenderer.triggerMultiSensory(actionType, intensity, params)
    -- Visual feedback (particles, screen effects, color shifts)
    FeedbackRenderer.triggerVisual(actionType, intensity, params)
    -- Audio feedback (layered sounds, dynamic mixing)
    FeedbackRenderer.triggerAudio(actionType, intensity, params)
    -- Haptic feedback (controller vibration, if available)
    FeedbackRenderer.triggerHaptic(actionType, intensity, params)
    -- Camera feedback (subtle movement, zoom, shake)
    FeedbackRenderer.triggerCamera(actionType, intensity, params)
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Visual Feedback Rendering
    ═══════════════════════════════════════════════════════════════════════════
--]]
function FeedbackRenderer.triggerVisual(actionType, intensity, params)
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    if actionType == "jump" then
        FeedbackRenderer._renderJumpVisuals(intensity, params)
    elseif actionType == "landing" then
        FeedbackRenderer._renderLandingVisuals(intensity, params)
    elseif actionType == "dash" then
        FeedbackRenderer._renderDashVisuals(intensity, params)
    elseif actionType == "failure" then
        FeedbackRenderer._renderFailureVisuals(intensity, params)
    end
end
function FeedbackRenderer._renderJumpVisuals(intensity, params)
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    -- Get player position from game state for particle placement
    local GameState = Utils.require("src.core.game_state")
    local player = GameState and GameState.player
    local playerX = player and player.x or 0
    local playerY = player and player.y or 0
    -- Choose emotion based on context and intensity
    local emotionType = "joy"  -- Default to joy
    local customMessage = nil
    -- Check for special jump contexts
    if params.isFirstJump then
        emotionType = "discovery"
        customMessage = "Your first leap into the cosmos!"
    elseif intensity > 0.8 then
        emotionType = "power"
        customMessage = "Explosive launch!"
    elseif params.streak and params.streak > 5 then
        emotionType = "achievement"
        customMessage = "Masterful momentum!"
    end
    -- Create emotional particle burst
    if ParticleSystem.createEmotionalBurst then
        ParticleSystem.createEmotionalBurst(playerX, playerY, emotionType, intensity, customMessage)
    else
        -- Fallback to legacy particle system
        ParticleSystem.burst(playerX, playerY, 10 + intensity * 20,
                           {0.3 + intensity * 0.7, 0.7 + intensity * 0.3, 1.0, 0.8},
                           100 + intensity * 200, 0.5 + intensity * 0.5)
    end
end
function FeedbackRenderer._renderLandingVisuals(intensity, params)
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    local particleCount = math.floor(4 + intensity * 12)
    local landingX = params.x or 0
    local landingY = params.y or 0
    for i = 1, particleCount do
        -- Particles spray upward and outward from landing point
        local angle = math.pi + (math.random() - 0.5) * math.pi * 0.7
        local speed = 40 + intensity * 90
        local lifetime = 0.3 + intensity * 0.5
        local vx = math.cos(angle) * speed * (0.7 + math.random() * 0.6)
        local vy = math.sin(angle) * speed * (0.7 + math.random() * 0.6)
        -- Landing colors: warm earth tones that intensify with impact
        local color = {
            0.7 + intensity * 0.3,  -- Warm orange-red
            0.5 + intensity * 0.4,  -- Golden highlights
            0.2 + intensity * 0.3,  -- Subtle blue for contrast
            0.5 + intensity * 0.5   -- Opacity scales with impact
        }
        ParticleSystem.create(
            landingX, landingY,
            vx, vy, color, lifetime, 1.5 + intensity * 2
        )
    end
end
function FeedbackRenderer._renderDashVisuals(intensity, params)
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    if params.emergency then
        -- Emergency dashes get extra dramatic sparkle trail
        local GameState = Utils.require("src.core.game_state")
        local player = GameState and GameState.player
        if player then
            local particleCount = math.floor(8 + intensity * 12)
            for i = 1, particleCount do
                local angle = math.random() * Utils.MATH.TWO_PI
                local speed = 20 + math.random() * 60
                local lifetime = 0.6 + math.random() * 0.4
                local vx = math.cos(angle) * speed
                local vy = math.sin(angle) * speed
                -- Emergency colors: bright white with energy blue
                local color = {1, 1, 1, 0.8 + intensity * 0.2}
                ParticleSystem.create(
                    player.x, player.y,
                    vx, vy, color, lifetime, 1 + intensity * 2
                )
            end
        end
    end
end
function FeedbackRenderer._renderFailureVisuals(intensity, params)
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    local particleCount = math.floor(2 + intensity * 4)
    local GameState = Utils.require("src.core.game_state")
    local player = GameState and GameState.player
    if player then
        for i = 1, particleCount do
            local angle = math.random() * Utils.MATH.TWO_PI
            local speed = 15 + math.random() * 25
            local lifetime = 0.5 + math.random() * 0.3
            local vx = math.cos(angle) * speed
            local vy = math.sin(angle) * speed
            -- Muted colors: soft grays that acknowledge without punishing
            local color = {0.6, 0.6, 0.7, 0.3 + intensity * 0.2}
            ParticleSystem.create(
                player.x, player.y,
                vx, vy, color, lifetime, 1
            )
        end
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Audio Feedback Rendering
    ═══════════════════════════════════════════════════════════════════════════
--]]
function FeedbackRenderer.triggerAudio(actionType, intensity, params)
    local SoundManager = Utils.require("src.audio.sound_manager")
    if not SoundManager then return end
    -- Intensity affects volume, pitch, and effect layers
    local volume = 0.5 + intensity * 0.5
    local pitch = 0.9 + intensity * 0.2  -- Higher intensity = higher pitch
    -- Future enhancement: Dynamic audio mixing based on emotional state
    -- SoundManager:playEmotional(actionType, volume, pitch, intensity)
end
function FeedbackRenderer.getAudioCue(moodType, intensity)
    -- Map moods to audio cues
    local audioCues = {
        neutral = { sound = "ambient", volume = 0.5 },
        perfect = { sound = "achievement", volume = 0.8 },
        smooth = { sound = "success", volume = 0.6 },
        excited = { sound = "energy", volume = 0.7 },
        intense = { sound = "tension", volume = 0.7 },
        energetic = { sound = "boost", volume = 0.6 },
        powerful = { sound = "power", volume = 0.8 },
        triumphant = { sound = "victory", volume = 0.9 },
        determined = { sound = "resolve", volume = 0.5 }
    }
    local cue = audioCues[moodType] or audioCues.neutral
    cue.intensity = intensity or 0.5
    return cue
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Haptic and Camera Feedback
    ═══════════════════════════════════════════════════════════════════════════
--]]
function FeedbackRenderer.triggerHaptic(actionType, intensity, params)
    -- Mobile devices or controllers with haptic feedback
    if Utils.MobileInput and Utils.MobileInput.vibrate then
        local hapticIntensity = intensity * 0.5  -- Scale for comfort
        Utils.MobileInput.vibrate(hapticIntensity)
    end
end
function FeedbackRenderer.triggerCamera(actionType, intensity, params)
    -- Framework for future camera enhancement
    local Camera = Utils.require("src.core.camera")
    if not Camera then return end
    -- Camera effects would be applied here
    -- Camera:addEmotionalEffect(actionType, intensity)
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Special Celebrations
    ═══════════════════════════════════════════════════════════════════════════
--]]
function FeedbackRenderer.createCelebration(celebrationType, params)
    local config = celebrationConfigs[celebrationType] or celebrationConfigs.first_success
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    local x = params and params.x or 0
    local y = params and params.y or 0
    -- Create burst pattern
    for i = 1, config.particleCount do
        local angle = (i / config.particleCount) * Utils.MATH.TWO_PI
        local speed = 80 + math.random() * 60
        local lifetime = config.duration * (0.8 + math.random() * 0.4)
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        -- Randomly select from celebration colors
        local colorIndex = math.random(1, #config.colors)
        local color = config.colors[colorIndex]
        ParticleSystem.create(
            x, y,
            vx, vy, color, lifetime, 3 + math.random() * 2
        )
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    UI Feedback Messages
    ═══════════════════════════════════════════════════════════════════════════
--]]
function FeedbackRenderer.getFeedbackMessage(moodType)
    local messages = {
        neutral = "Keep exploring!",
        perfect = "Perfect landing!",
        smooth = "Smooth approach!",
        excited = "What a rush!",
        intense = "Intense landing!",
        energetic = "Great jump!",
        powerful = "Powerful dash!",
        triumphant = "Achievement unlocked!",
        determined = "Keep trying!"
    }
    return messages[moodType] or messages.neutral
end
function FeedbackRenderer.getVisualEffects(emotionalState, currentMood)
    -- Placeholder for future visual effects system
    -- Would return configurations for screen effects, color filters, etc.
    return nil
end
return FeedbackRenderer