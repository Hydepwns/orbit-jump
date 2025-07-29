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
--]]

local Utils = require("src.utils.utils")
local EmotionalFeedback = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotional State Tracking: The Game's Memory of Player Joy
    ═══════════════════════════════════════════════════════════════════════════
--]]

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
    Emotional Feedback Orchestration
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionalFeedback.init()
    --[[Initialize the emotional feedback system--]]
    emotionalState.confidence = 0.5
    emotionalState.momentum = 0.0
    emotionalState.achievement_streak = 0
    emotionalState.last_celebration = 0
    emotionalState.flow_state_duration = 0
    emotionalState.surprise_cooldown = 0
    
    -- Initialize exposed properties for testing
    EmotionalFeedback.emotions = emotionalState
    EmotionalFeedback.currentMood = { type = "neutral", intensity = 0.5 }
    
    Utils.Logger.info("💝 Emotional feedback system initialized - Ready to create joy")
    return true
end

function EmotionalFeedback.processEvent(eventType, params)
    --[[
        Central event processing router for the emotional feedback system
        Routes different events to their specific handlers
    --]]
    
    if eventType == "landing" then
        -- Landing event parameters
        local player = params.player or {x = 0, y = 0, vx = 0, vy = 0}
        local planet = params.planet or {type = "normal"}
        local speed = params.speed or 100
        local isGentle = speed < 100
        
        EmotionalFeedback.onLanding(player, planet, speed, isGentle)
        
        -- Update mood based on landing quality
        if speed < 50 then
            EmotionalFeedback.currentMood = { type = "perfect", intensity = 1.0 }
        elseif speed < 100 then
            EmotionalFeedback.currentMood = { type = "smooth", intensity = 0.8 }
        elseif speed < 200 then
            EmotionalFeedback.currentMood = { type = "excited", intensity = 0.7 }
        else
            EmotionalFeedback.currentMood = { type = "intense", intensity = 0.6 }
        end
        
    elseif eventType == "jump" then
        -- Jump event parameters
        local pullPower = params.pullPower or 0.5
        local jumpSuccess = params.success ~= false
        local isFirstJump = params.isFirstJump or false
        
        EmotionalFeedback.onJump(pullPower, jumpSuccess, isFirstJump)
        EmotionalFeedback.currentMood = { type = "energetic", intensity = 0.7 + pullPower * 0.3 }
        
    elseif eventType == "dash" then
        -- Dash event parameters
        local isEmergency = params.emergency or false
        local dashSuccess = params.success ~= false
        
        EmotionalFeedback.onDash(isEmergency, dashSuccess)
        EmotionalFeedback.currentMood = { type = "powerful", intensity = isEmergency and 0.9 or 0.7 }
        
    elseif eventType == "achievement" then
        -- Achievement unlocked
        EmotionalFeedback.triggerSpecialCelebration(params.type or "generic")
        EmotionalFeedback.currentMood = { type = "triumphant", intensity = 1.0 }
        
    elseif eventType == "failure" then
        -- Failure event
        EmotionalFeedback.onFailure(params.type or "generic")
        EmotionalFeedback.currentMood = { type = "determined", intensity = 0.4 }
        
    elseif eventType == "combo" then
        -- Combo achievement
        local count = params.count or 0
        emotionalState.achievement_streak = count
        emotionalState.confidence = math.min(1.0, emotionalState.confidence + count * 0.05)
        EmotionalFeedback.currentMood = { type = count > 5 and "triumphant" or "excited", intensity = math.min(1.0, 0.5 + count * 0.1) }
        
    elseif eventType == "near_miss" then
        -- Near miss event
        emotionalState.momentum = emotionalState.momentum + 0.3
        EmotionalFeedback.currentMood = { type = "intense", intensity = 0.8 }
        emotionalMemory.dramatic_saves = emotionalMemory.dramatic_saves + 1
        
    elseif eventType == "discovery" then
        -- Discovery event
        EmotionalFeedback.triggerSpecialCelebration("discovery")
        EmotionalFeedback.currentMood = { type = "excited", intensity = 0.9 }
        emotionalState.confidence = math.min(1.0, emotionalState.confidence + 0.2)
    end
    
    -- Update exposed emotions reference
    EmotionalFeedback.emotions = emotionalState
end

function EmotionalFeedback.update(dt)
    --[[
        Emotional State Evolution: How feelings change over time
        
        This function manages the decay and evolution of emotional states,
        ensuring that the feedback system feels natural and responsive
        rather than mechanical and predictable.
    --]]
    
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
    if EmotionalFeedback.currentMood and type(EmotionalFeedback.currentMood) == "table" and EmotionalFeedback.currentMood.intensity then
        local MOOD_DECAY = 0.2 * dt
        local newIntensity = math.max(0, EmotionalFeedback.currentMood.intensity - MOOD_DECAY)
        
        -- Update the intensity in place
        EmotionalFeedback.currentMood.intensity = newIntensity
        
        -- Reset to neutral if intensity is too low
        if newIntensity < 0.1 then
            EmotionalFeedback.currentMood = { type = "neutral", intensity = 0.5 }
        end
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Specific Emotional Events: The Moments That Matter
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionalFeedback.onJump(pullPower, jumpSuccess, isFirstJump)
    --[[
        Jump Emotional Response: The Moment of Liberation
        
        Jumping is the core interaction - make it feel amazing every time.
        The feedback intensity scales with pull power, creating a satisfying
        risk/reward relationship where bigger jumps feel more exciting.
    --]]
    
    if not jumpSuccess then
        return EmotionalFeedback.onFailure("jump_blocked")
    end
    
    -- Calculate emotional intensity based on pull power and context
    local config = feedbackConfigs.jump
    local baseIntensity = config.baseIntensity
    local powerBonus = pullPower * config.powerMultiplier
    local intensity = math.min(baseIntensity + powerBonus, config.maxIntensity)
    
    -- First jump ever is a special moment
    if isFirstJump and not emotionalMemory.first_successful_jump then
        emotionalMemory.first_successful_jump = true
        intensity = intensity + 0.4  -- Extra celebration for first success
        EmotionalFeedback.triggerSpecialCelebration("first_jump")
    end
    
    -- Build momentum and confidence
    emotionalState.momentum = math.min(1.0, emotionalState.momentum + intensity * 0.5)
    emotionalState.confidence = math.min(1.0, emotionalState.confidence + intensity * 0.3)
    emotionalState.achievement_streak = emotionalState.achievement_streak + 1
    emotionalState.last_celebration = 0
    
    -- Generate layered feedback
    EmotionalFeedback.triggerMultiSensoryFeedback("jump", intensity, {pullPower = pullPower})
    
    return intensity
end

function EmotionalFeedback.onLanding(player, planet, landingSpeed, isGentle)
    --[[
        Landing Emotional Response: The Relief and Satisfaction of Arrival
        
        Landings provide different emotional textures based on the approach:
        • Gentle landings feel graceful and skillful
        • Fast landings feel dramatic and exciting
        • Perfect landings (frame-perfect timing) feel masterful
    --]]
    
    local config = feedbackConfigs.landing
    local baseIntensity = config.baseIntensity
    
    -- Speed creates excitement (but too much speed might be scary)
    local speedBonus = math.min(landingSpeed / 1000, 1.0) * config.speedMultiplier
    
    -- Gentle landings have their own appeal
    local gentleBonus = isGentle and config.gentleBonus or 0
    
    -- Check for perfect landing (within perfect timing window)
    local isPerfect = EmotionalFeedback.checkPerfectLanding(player, planet)
    local perfectBonus = isPerfect and config.perfectBonus or 0
    
    if isPerfect then
        emotionalMemory.perfect_landings = emotionalMemory.perfect_landings + 1
    end
    
    local intensity = baseIntensity + speedBonus + gentleBonus + perfectBonus
    
    -- Update emotional state
    emotionalState.confidence = math.min(1.0, emotionalState.confidence + intensity * 0.2)
    emotionalState.momentum = math.min(1.0, emotionalState.momentum + intensity * 0.3)
    
    -- Special feedback for perfect landings
    if isPerfect then
        EmotionalFeedback.triggerSpecialCelebration("perfect_landing")
    end
    
    EmotionalFeedback.triggerMultiSensoryFeedback("landing", intensity, {speed = landingSpeed, x = player.x, y = player.y})
    
    return intensity
end

function EmotionalFeedback.onDash(isEmergencyDash, dashSuccess)
    --[[
        Dash Emotional Response: Superhuman Power Activation
        
        Dashing feels powerful and dramatic. Emergency dashes (when the player
        is in danger) should feel especially heroic and satisfying.
    --]]
    
    if not dashSuccess then
        return EmotionalFeedback.onFailure("dash_failed")
    end
    
    local config = feedbackConfigs.dash
    local intensity = config.baseIntensity
    
    -- Emergency dashes feel more heroic
    if isEmergencyDash then
        intensity = intensity + config.emergencyBonus
        emotionalMemory.dramatic_saves = emotionalMemory.dramatic_saves + 1
    end
    
    -- Update emotional state (dashing builds confidence quickly)
    emotionalState.confidence = math.min(1.0, emotionalState.confidence + intensity * 0.4)
    emotionalState.momentum = math.min(1.0, emotionalState.momentum + intensity * 0.6)
    
    EmotionalFeedback.triggerMultiSensoryFeedback("dash", intensity, {emergency = isEmergencyDash})
    
    return intensity
end

function EmotionalFeedback.onFailure(failureType)
    --[[
        Failure Emotional Response: Setbacks That Build Anticipation
        
        Failures should never feel punishing - they should build anticipation
        for the next success. The emotional system learns from failures to
        make the eventual success feel even better.
    --]]
    
    -- Reduce momentum and confidence slightly
    emotionalState.momentum = math.max(-0.5, emotionalState.momentum - 0.2)
    emotionalState.confidence = math.max(0.1, emotionalState.confidence - 0.1)
    
    -- Reset achievement streak (but gently)
    emotionalState.achievement_streak = math.max(0, emotionalState.achievement_streak - 1)
    
    -- Different failure types might have different feedback
    local intensity = 0.2  -- Gentle disappointment, not punishment
    
    EmotionalFeedback.triggerMultiSensoryFeedback("failure", intensity, {type = failureType})
    
    return intensity
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Multi-Sensory Feedback Generation
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionalFeedback.triggerMultiSensoryFeedback(actionType, intensity, extraParameter)
    --[[
        Multi-Channel Emotional Communication
        
        True emotional impact comes from coordinated feedback across multiple
        sensory channels. This function orchestrates visual, audio, and haptic
        feedback to create a unified emotional experience.
    --]]
    
    -- Visual feedback (particles, screen effects, color shifts)
    EmotionalFeedback.triggerVisualFeedback(actionType, intensity, extraParameter)
    
    -- Audio feedback (layered sounds, dynamic mixing)
    EmotionalFeedback.triggerAudioFeedback(actionType, intensity, extraParameter)
    
    -- Haptic feedback (controller vibration, if available)
    EmotionalFeedback.triggerHapticFeedback(actionType, intensity, extraParameter)
    
    -- Camera feedback (subtle movement, zoom, shake)
    EmotionalFeedback.triggerCameraFeedback(actionType, intensity, extraParameter)
end

function EmotionalFeedback.triggerVisualFeedback(actionType, intensity, params)
    --[[
        Emotional Visual Effects: Making Feelings Visible
        
        This function creates visual effects that amplify the emotional impact
        of player actions. The effects scale with intensity and adapt based on
        the context of the action.
    --]]
    
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    
    if actionType == "jump" then
        -- Launch Celebration: Express the joy of freedom through particles
        
        -- Get player position from game state for particle placement
        local GameState = Utils.require("src.core.game_state")
        local player = GameState and GameState.player
        local playerX = player and player.x or 0
        local playerY = player and player.y or 0
        
        -- Choose emotion based on context and intensity
        local emotionType = "joy"  -- Default to joy
        local customMessage = nil
        
        -- Check for special jump contexts
        if emotionalMemory.first_successful_jump == false then
            emotionType = "discovery"
            customMessage = "Your first leap into the cosmos!"
            emotionalMemory.first_successful_jump = true
        elseif intensity > 0.8 then
            emotionType = "power"
            customMessage = "Explosive launch!"
        elseif emotionalState.achievement_streak > 5 then
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
        
    elseif actionType == "landing" then
        -- Landing Impact: Particles that express arrival satisfaction
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
        
    elseif actionType == "dash" then
        -- Dash Trail Enhancement: Additional sparkle effects for heroic moments
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
        
    elseif actionType == "failure" then
        -- Gentle Disappointment: Subtle effects that don't punish
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
end

function EmotionalFeedback.triggerAudioFeedback(actionType, intensity, extraParameter)
    --[[Create audio that emotionally matches the action--]]
    
    -- This would integrate with the SoundManager to create layered audio
    -- For now, we'll set up the framework for future audio enhancement
    
    local SoundManager = Utils.require("src.audio.sound_manager")
    if not SoundManager then return end
    
    -- Intensity affects volume, pitch, and effect layers
    local volume = 0.5 + intensity * 0.5
    local pitch = 0.9 + intensity * 0.2  -- Higher intensity = higher pitch
    
    -- Future enhancement: Dynamic audio mixing based on emotional state
    -- SoundManager:playEmotional(actionType, volume, pitch, intensity)
end

function EmotionalFeedback.triggerHapticFeedback(actionType, intensity, extraParameter)
    --[[Create tactile feedback for supported devices--]]
    
    -- Mobile devices or controllers with haptic feedback
    if Utils.MobileInput and Utils.MobileInput.vibrate then
        local hapticIntensity = intensity * 0.5  -- Scale for comfort
        Utils.MobileInput.vibrate(hapticIntensity)
    end
end

function EmotionalFeedback.triggerCameraFeedback(actionType, intensity, extraParameter)
    --[[Subtle camera effects that enhance the emotional impact--]]
    
    -- This would integrate with the camera system for subtle effects
    -- • Small camera shake for impacts
    -- • Brief zoom for dramatic moments  
    -- • Smooth easing for satisfying actions
    
    -- Framework for future camera enhancement
    local Camera = Utils.require("src.core.camera")
    if not Camera then return end
    
    -- Camera effects would be applied here
    -- Camera:addEmotionalEffect(actionType, intensity)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Special Celebrations and Milestone Recognition
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionalFeedback.triggerSpecialCelebration(achievementType)
    --[[
        Milestone Celebrations: Making Special Moments Feel Special
        
        Some moments deserve extra attention. These celebrations create
        emotional peaks that players remember long after playing.
    --]]
    
    if emotionalState.surprise_cooldown > 0 then
        return  -- Prevent celebration fatigue
    end
    
    emotionalState.surprise_cooldown = 3.0  -- 3 second cooldown
    
    if achievementType == "first_jump" then
        -- Player's first successful jump ever
        EmotionalFeedback.createCelebrationBurst("first_success", {
            particleCount = 20,
            colors = {{1, 1, 0.5, 1}, {1, 0.8, 0.3, 1}},  -- Golden celebration
            duration = 1.5,
            intensity = 1.0
        })
        
    elseif achievementType == "perfect_landing" then
        -- Frame-perfect landing timing
        EmotionalFeedback.createCelebrationBurst("mastery", {
            particleCount = 15,
            colors = {{0.5, 1, 1, 1}, {0.3, 0.8, 1, 1}},  -- Crystal blue perfection
            duration = 1.0,
            intensity = 0.8
        })
        
    end
end

function EmotionalFeedback.createCelebrationBurst(celebrationType, config)
    --[[Generate a special visual celebration--]]
    
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    
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
            0, 0,  -- Will be positioned by calling context
            vx, vy, color, lifetime, 3 + math.random() * 2
        )
    end
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
    --[[Return current emotional state for other systems to use--]]
    return {
        confidence = emotionalState.confidence,
        momentum = emotionalState.momentum,
        streak = emotionalState.achievement_streak,
        flow_duration = emotionalState.flow_state_duration
    }
end

function EmotionalFeedback.getEmotionalMemory()
    --[[Return emotional memory for persistence and achievements--]]
    return Utils.deepCopy(emotionalMemory)
end

function EmotionalFeedback.getFeedbackMessage()
    --[[Get contextual feedback message based on current mood--]]
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
    
    local moodType = EmotionalFeedback.currentMood and EmotionalFeedback.currentMood.type or "neutral"
    return messages[moodType] or messages.neutral
end

function EmotionalFeedback.getVisualEffects()
    --[[Get current visual effects based on emotional state--]]
    -- This is a placeholder for future visual effects system
    return nil
end

function EmotionalFeedback.getAudioCue()
    --[[Get appropriate audio cue for current emotional state--]]
    local moodType = EmotionalFeedback.currentMood and EmotionalFeedback.currentMood.type or "neutral"
    local intensity = EmotionalFeedback.currentMood and EmotionalFeedback.currentMood.intensity or 0.5
    
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
    cue.intensity = intensity
    
    return cue
end

function EmotionalFeedback.debugEmotionalState()
    --[[
        Debug function to visualize current emotional state
        Useful for tuning and understanding the emotional flow
    --]]
    
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
end

return EmotionalFeedback