--[[
    ═══════════════════════════════════════════════════════════════════════════
    Player Analytics: The Observer of Human Behavior
    ═══════════════════════════════════════════════════════════════════════════
    
    This system watches. It learns. It remembers.
    
    Not for surveillance, but for compassion - understanding how humans play
    so that the game can adapt to serve them better. Every jump, every pause,
    every hesitation tells a story. This system reads those stories and
    whispers insights to other systems that can use them to create better
    experiences.
    
    101% Philosophy: "Observation without judgment, learning with empathy"
    
    Behavioral Patterns We Track:
    • Movement Preferences: How does this player like to move through space?
    • Risk Tolerance: Do they take calculated risks or play it safe?
    • Exploration Style: Methodical surveyor or chaotic wanderer?
    • Skill Development: How does mastery emerge over time?
    • Emotional Rhythms: When do they get frustrated? When do they feel flow?
    • Session Patterns: How do they engage with the game over time?
    
    The Sacred Rule: All data serves the player's experience, never external goals.
--]]

local Utils = require("src.utils.utils")
local PlayerAnalytics = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Behavioral Memory Architecture: The Mind That Remembers
    ═══════════════════════════════════════════════════════════════════════════
--]]

PlayerAnalytics.memory = {
    -- Movement Psychology: How does this human navigate space?
    movementProfile = {
        preferredJumpPower = 0,      -- Average power they use
        jumpPowerVariance = 0,       -- How consistent are they?
        averageJumpDistance = 0,     -- Spatial preference
        riskTolerance = 0,           -- 0-1: conservative to adventurous
        planningTime = 0,            -- Average time between landing and jumping
        totalJumps = 0,
        totalDistance = 0,
        
        -- Movement Efficiency
        wastedMovement = 0,          -- Movement that doesn't advance goals
        efficientPaths = 0,          -- Direct routes taken
        creativePaths = 0,           -- Interesting non-optimal routes
        
        -- Spatial Awareness
        collisionRate = 0,           -- How often they hit things
        nearMissRate = 0,            -- How often they almost hit things
        spatialMastery = 0           -- Overall movement skill (0-1)
    },
    
    -- Exploration Psychology: How do they discover the world?
    explorationProfile = {
        explorationStyle = "unknown", -- "methodical", "chaotic", "balanced"
        newPlanetAttempts = 0,       -- Tries to reach undiscovered planets
        newPlanetSuccesses = 0,      -- Actually makes it to them
        explorationEfficiency = 0,   -- Success rate
        
        -- Discovery Patterns
        averageTimeToRevisit = 0,    -- How long before returning to planets
        planetVisitDistribution = {},-- How evenly they visit different areas
        explorationRadius = 0,       -- How far from start they typically go
        
        -- Learning Curve
        discoveryMomentum = 0,       -- How discovery rate changes over time
        comfortZoneSize = 0,         -- Size of area they stay within
        expansionRate = 0            -- How quickly they expand their territory
    },
    
    -- Skill Development: The arc of mastery
    skillProgression = {
        initialSkill = 0,            -- Baseline skill when we started tracking
        currentSkill = 0,            -- Current skill level (0-1)
        skillVelocity = 0,           -- Rate of improvement
        skillPlateau = false,        -- Have they hit a learning plateau?
        
        -- Mastery Indicators
        consistency = 0,             -- How reliable are their movements?
        adaptability = 0,            -- How well do they handle new situations?
        efficiency = 0,              -- How optimal are their solutions?
        creativity = 0,              -- How often do they find novel approaches?
        
        -- Learning Patterns
        practiceTime = 0,            -- Time spent on similar tasks
        challengeSeeking = 0,        -- How often they attempt difficult things
        failureRecovery = 0,         -- How well they bounce back from mistakes
        improvementRate = {}         -- Historical skill progression
    },
    
    -- Emotional Rhythms: The feeling journey
    emotionalProfile = {
        frustrationTolerance = 0,    -- How much difficulty they enjoy
        flowStateDuration = 0,       -- Time spent in smooth, effortless play
        pauseFrequency = 0,          -- How often they take breaks
        retryPersistence = 0,        -- How many times they attempt difficult jumps
        
        -- Emotional States (inferred from behavior)
        currentMood = "neutral",     -- "focused", "frustrated", "exploring", "mastery"
        sessionEnergy = 1.0,         -- 0-1: tired to energetic
        confidenceLevel = 0.5,       -- 0-1: hesitant to bold
        
        -- Satisfaction Indicators
        achievementReactions = {},   -- How they respond to success
        failurePatterns = {},        -- How they handle setbacks
        engagementLevel = 0,         -- How absorbed they are in the game
        sessionSatisfaction = 0      -- Overall satisfaction with current session
    },
    
    -- Session Patterns: The rhythm of engagement
    sessionData = {
        totalSessions = 0,
        averageSessionLength = 0,
        preferredPlayTimes = {},     -- When they like to play
        sessionStartMood = {},       -- How they typically begin
        sessionEndMood = {},         -- How they typically finish
        
        -- Engagement Patterns
        warmupTime = 0,              -- Time to get into flow
        peakPerformanceTime = 0,     -- When they play best in a session
        fadeTime = 0,                -- When performance starts declining
        
        -- Break Patterns
        breakFrequency = 0,          -- How often they pause
        breakDuration = 0,           -- How long breaks typically last
        returnBehavior = "",         -- How they re-engage after breaks
        
        -- Long-term Patterns
        playSchedule = {},           -- Weekly/daily patterns
        seasonalChanges = {},        -- How behavior changes over time
        progressSatisfaction = 0     -- How they feel about long-term progress
    }
}

-- Analytics State
PlayerAnalytics.isTracking = false
PlayerAnalytics.sessionStartTime = 0
PlayerAnalytics.lastActionTime = 0
PlayerAnalytics.currentAnalysisWindow = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    System Lifecycle: Birth, Growth, and Memory
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerAnalytics.init()
    PlayerAnalytics.sessionStartTime = love.timer.getTime()
    PlayerAnalytics.lastActionTime = PlayerAnalytics.sessionStartTime
    PlayerAnalytics.isTracking = true
    
    -- Initialize memory structures if they don't exist
    PlayerAnalytics.initializeMemoryStructures()
    
    -- Restore from save data
    PlayerAnalytics.restoreFromSave()
    
    -- Begin session analysis
    PlayerAnalytics.beginSession()
    
    Utils.Logger.info("🔍 Player Analytics initialized - Observing with compassion")
    return true
end

function PlayerAnalytics.initializeMemoryStructures()
    -- Ensure all nested tables exist with safe defaults
    if not PlayerAnalytics.memory.movementProfile then
        PlayerAnalytics.memory.movementProfile = {
            preferredJumpPower = 0, jumpPowerVariance = 0, averageJumpDistance = 0,
            riskTolerance = 0.5, planningTime = 0, totalJumps = 0, totalDistance = 0,
            wastedMovement = 0, efficientPaths = 0, creativePaths = 0,
            collisionRate = 0, nearMissRate = 0, spatialMastery = 0
        }
    end
    
    -- Initialize other profiles similarly...
    PlayerAnalytics.initializeExplorationProfile()
    PlayerAnalytics.initializeSkillProfile()
    PlayerAnalytics.initializeEmotionalProfile()
    PlayerAnalytics.initializeSessionProfile()
end

function PlayerAnalytics.beginSession()
    local memory = PlayerAnalytics.memory
    memory.sessionData.totalSessions = memory.sessionData.totalSessions + 1
    
    -- Analyze how they start sessions
    local startMood = PlayerAnalytics.inferCurrentMood()
    table.insert(memory.sessionData.sessionStartMood, startMood)
    
    Utils.Logger.info("📊 Session %d begun - mood: %s", 
        memory.sessionData.totalSessions, startMood)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Learning Functions: The Algorithms of Understanding
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Learn from player movement
function PlayerAnalytics.onPlayerJump(jumpPower, jumpAngle, startX, startY, targetX, targetY, planningTime)
    local movement = PlayerAnalytics.memory.movementProfile
    local currentTime = love.timer.getTime()
    
    -- Update basic statistics
    movement.totalJumps = movement.totalJumps + 1
    
    -- Calculate jump distance
    local jumpDistance = Utils.distance(startX, startY, targetX, targetY)
    movement.totalDistance = movement.totalDistance + jumpDistance
    movement.averageJumpDistance = movement.totalDistance / movement.totalJumps
    
    -- Analyze jump power preferences
    movement.preferredJumpPower = Utils.lerp(movement.preferredJumpPower, jumpPower, 0.1)
    
    -- Update planning time (how long they think before jumping)
    if planningTime and planningTime > 0 then
        movement.planningTime = Utils.lerp(movement.planningTime, planningTime, 0.1)
    end
    
    -- Analyze risk tolerance
    PlayerAnalytics.analyzeRiskTolerance(jumpPower, jumpDistance, startX, startY)
    
    -- Update skill assessment
    PlayerAnalytics.updateMovementSkill(jumpPower, jumpDistance, planningTime)
    
    PlayerAnalytics.lastActionTime = currentTime
    
    Utils.Logger.debug("📈 Jump analyzed: power=%.2f, distance=%.1f, planning=%.1fs", 
        jumpPower, jumpDistance, planningTime or 0)
end

-- Analyze risk tolerance from jump characteristics
function PlayerAnalytics.analyzeRiskTolerance(jumpPower, jumpDistance, startX, startY)
    -- High power jumps to distant targets = high risk tolerance
    -- Conservative, short jumps = low risk tolerance
    
    local powerRisk = jumpPower / 1000 -- Normalize to 0-1 range
    local distanceRisk = math.min(jumpDistance / 1000, 1.0) -- Cap at 1000 units
    
    local jumpRisk = (powerRisk + distanceRisk) / 2
    
    -- Exponential moving average to update risk tolerance
    local movement = PlayerAnalytics.memory.movementProfile
    movement.riskTolerance = Utils.lerp(movement.riskTolerance, jumpRisk, 0.05)
end

-- Update movement skill assessment
function PlayerAnalytics.updateMovementSkill(jumpPower, jumpDistance, planningTime)
    local movement = PlayerAnalytics.memory.movementProfile
    local skill = PlayerAnalytics.memory.skillProgression
    
    -- Skill indicators:
    -- 1. Consistency in jump power
    local powerConsistency = 1.0 - math.abs(jumpPower - movement.preferredJumpPower) / 1000
    
    -- 2. Efficient use of power (not overpowering short jumps)
    local expectedPower = jumpDistance * 0.5 -- Rough efficiency estimate
    local powerEfficiency = 1.0 - math.abs(jumpPower - expectedPower) / jumpPower
    
    -- 3. Planning efficiency (not too fast, not too slow)
    local planningEfficiency = 1.0
    if planningTime then
        local optimalPlanningTime = 2.0 -- 2 seconds is "good" planning time
        planningEfficiency = 1.0 - math.abs(planningTime - optimalPlanningTime) / optimalPlanningTime
    end
    
    -- Combine skill factors
    local currentSkillSample = (powerConsistency + powerEfficiency + planningEfficiency) / 3
    
    -- Update overall skill with exponential moving average
    skill.currentSkill = Utils.lerp(skill.currentSkill, currentSkillSample, 0.1)
    movement.spatialMastery = skill.currentSkill
    
    -- Track skill progression over time
    table.insert(skill.improvementRate, {
        time = love.timer.getTime(),
        skill = skill.currentSkill
    })
    
    -- Keep only recent skill history
    if #skill.improvementRate > 100 then
        table.remove(skill.improvementRate, 1)
    end
end

-- Learn from planet discovery
function PlayerAnalytics.onPlanetDiscovered(planet, discoveryMethod, attemptsToReach)
    local exploration = PlayerAnalytics.memory.explorationProfile
    
    exploration.newPlanetAttempts = exploration.newPlanetAttempts + (attemptsToReach or 1)
    exploration.newPlanetSuccesses = exploration.newPlanetSuccesses + 1
    exploration.explorationEfficiency = exploration.newPlanetSuccesses / exploration.newPlanetAttempts
    
    -- Analyze exploration style
    PlayerAnalytics.analyzeExplorationStyle(planet, discoveryMethod, attemptsToReach)
    
    Utils.Logger.info("🌍 Planet discovery analyzed: efficiency %.1f%%", 
        exploration.explorationEfficiency * 100)
end

-- Analyze exploration patterns
function PlayerAnalytics.analyzeExplorationStyle(planet, discoveryMethod, attempts)
    local exploration = PlayerAnalytics.memory.explorationProfile
    
    -- Multiple attempts = methodical approach
    -- Single attempt success = either lucky or skillful
    -- Failed attempts then success = persistent
    
    if attempts == 1 then
        exploration.creativePaths = exploration.creativePaths + 1
    elseif attempts <= 3 then
        exploration.explorationStyle = "balanced"
    else
        exploration.explorationStyle = "methodical"
    end
    
    -- Update exploration radius
    local distanceFromOrigin = Utils.distance(0, 0, planet.x, planet.y)
    exploration.explorationRadius = math.max(exploration.explorationRadius, distanceFromOrigin)
end

-- Infer current emotional state from behavior patterns
function PlayerAnalytics.inferCurrentMood()
    local currentTime = love.timer.getTime()
    local timeSinceLastAction = currentTime - PlayerAnalytics.lastActionTime
    local movement = PlayerAnalytics.memory.movementProfile
    local emotional = PlayerAnalytics.memory.emotionalProfile
    
    -- Quick successive actions = focused or frustrated
    if timeSinceLastAction < 1.0 then
        if movement.collisionRate > 0.2 then
            return "frustrated"
        else
            return "focused"
        end
    
    -- Long pauses = thinking or frustrated
    elseif timeSinceLastAction > 10.0 then
        return "contemplating"
    
    -- Medium risk taking = confident
    elseif movement.riskTolerance > 0.6 and movement.riskTolerance < 0.9 then
        return "confident"
    
    -- Low risk = cautious or learning
    elseif movement.riskTolerance < 0.3 then
        return "cautious"
    
    else
        return "neutral"
    end
end

-- Update emotional profile based on events
function PlayerAnalytics.onEmotionalEvent(eventType, intensity, context)
    local emotional = PlayerAnalytics.memory.emotionalProfile
    
    if eventType == "success" then
        emotional.confidenceLevel = math.min(1.0, emotional.confidenceLevel + intensity * 0.1)
        emotional.sessionSatisfaction = math.min(1.0, emotional.sessionSatisfaction + intensity * 0.05)
        
    elseif eventType == "failure" then
        emotional.confidenceLevel = math.max(0.0, emotional.confidenceLevel - intensity * 0.05)
        emotional.retryPersistence = emotional.retryPersistence + 1
        
    elseif eventType == "flow_state" then
        emotional.flowStateDuration = emotional.flowStateDuration + (context.duration or 1.0)
        
    elseif eventType == "pause" then
        emotional.pauseFrequency = emotional.pauseFrequency + 1
    end
    
    -- Update current mood based on recent events
    emotional.currentMood = PlayerAnalytics.inferCurrentMood()
    
    Utils.Logger.debug("💭 Emotional event: %s (intensity %.2f) -> mood: %s", 
        eventType, intensity, emotional.currentMood)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Data Analysis and Insights: Wisdom from Observation
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Get comprehensive player profile
function PlayerAnalytics.getPlayerProfile()
    local memory = PlayerAnalytics.memory
    
    return {
        -- Movement Characteristics
        movementStyle = PlayerAnalytics.classifyMovementStyle(),
        skillLevel = memory.skillProgression.currentSkill,
        riskTolerance = memory.movementProfile.riskTolerance,
        spatialMastery = memory.movementProfile.spatialMastery,
        
        -- Exploration Characteristics  
        explorationStyle = memory.explorationProfile.explorationStyle,
        explorationEfficiency = memory.explorationProfile.explorationEfficiency,
        adventurousness = memory.explorationProfile.explorationRadius / 2000, -- Normalize
        
        -- Emotional Characteristics
        currentMood = memory.emotionalProfile.currentMood,
        confidenceLevel = memory.emotionalProfile.confidenceLevel,
        frustrationTolerance = memory.emotionalProfile.frustrationTolerance,
        sessionSatisfaction = memory.emotionalProfile.sessionSatisfaction,
        
        -- Session Characteristics
        sessionCount = memory.sessionData.totalSessions,
        engagementLevel = memory.emotionalProfile.engagementLevel,
        preferredSessionLength = memory.sessionData.averageSessionLength
    }
end

-- Classify movement style based on behavior patterns
function PlayerAnalytics.classifyMovementStyle()
    local movement = PlayerAnalytics.memory.movementProfile
    
    if movement.riskTolerance > 0.7 and movement.spatialMastery > 0.6 then
        return "bold_expert"
    elseif movement.riskTolerance > 0.7 and movement.spatialMastery < 0.4 then
        return "reckless_learner"
    elseif movement.riskTolerance < 0.3 and movement.spatialMastery > 0.6 then
        return "precise_master"
    elseif movement.riskTolerance < 0.3 and movement.spatialMastery < 0.4 then
        return "cautious_beginner"
    else
        return "balanced_player"
    end
end

-- Get recommendations for other systems
function PlayerAnalytics.getSystemRecommendations()
    local profile = PlayerAnalytics.getPlayerProfile()
    local recommendations = {}
    
    -- Recommendations for difficulty adjustment
    if profile.skillLevel < 0.3 and profile.frustrationTolerance < 0.5 then
        recommendations.difficultyAdjustment = "easier"
        recommendations.helpLevel = "more_guidance"
    elseif profile.skillLevel > 0.7 and profile.riskTolerance > 0.6 then
        recommendations.difficultyAdjustment = "harder"
        recommendations.helpLevel = "less_guidance"
    end
    
    -- Recommendations for UI adaptation
    if profile.currentMood == "frustrated" then
        recommendations.uiTone = "encouraging"
        recommendations.feedbackLevel = "more_positive"
    elseif profile.currentMood == "confident" then
        recommendations.uiTone = "challenging"
        recommendations.feedbackLevel = "achievement_focused"
    end
    
    -- Recommendations for content presentation
    if profile.explorationStyle == "methodical" then
        recommendations.contentPacing = "structured"
        recommendations.informationDensity = "detailed"
    elseif profile.explorationStyle == "chaotic" then
        recommendations.contentPacing = "flexible"
        recommendations.informationDensity = "minimal"
    end
    
    return recommendations
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    System Integration and Persistence
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Save analytics data
function PlayerAnalytics.saveAnalyticsData()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("playerAnalytics", PlayerAnalytics.memory)
        Utils.Logger.debug("📊 Analytics data saved")
    end
end

-- Restore analytics from save
function PlayerAnalytics.restoreFromSave()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local saveData = SaveSystem.getData()
        if saveData and saveData.playerAnalytics then
            PlayerAnalytics.memory = Utils.mergeTables(PlayerAnalytics.memory, saveData.playerAnalytics)
            Utils.Logger.info("📊 Analytics data restored from save")
        end
    end
end

-- Initialize profile sections
function PlayerAnalytics.initializeExplorationProfile()
    if not PlayerAnalytics.memory.explorationProfile then
        PlayerAnalytics.memory.explorationProfile = {
            explorationStyle = "unknown", newPlanetAttempts = 0, newPlanetSuccesses = 0,
            explorationEfficiency = 0, averageTimeToRevisit = 0, planetVisitDistribution = {},
            explorationRadius = 0, discoveryMomentum = 0, comfortZoneSize = 0, expansionRate = 0
        }
    end
end

function PlayerAnalytics.initializeSkillProfile()
    if not PlayerAnalytics.memory.skillProgression then
        PlayerAnalytics.memory.skillProgression = {
            initialSkill = 0, currentSkill = 0, skillVelocity = 0, skillPlateau = false,
            consistency = 0, adaptability = 0, efficiency = 0, creativity = 0,
            practiceTime = 0, challengeSeeking = 0, failureRecovery = 0, improvementRate = {}
        }
    end
end

function PlayerAnalytics.initializeEmotionalProfile()
    if not PlayerAnalytics.memory.emotionalProfile then
        PlayerAnalytics.memory.emotionalProfile = {
            frustrationTolerance = 0.5, flowStateDuration = 0, pauseFrequency = 0, retryPersistence = 0,
            currentMood = "neutral", sessionEnergy = 1.0, confidenceLevel = 0.5,
            achievementReactions = {}, failurePatterns = {}, engagementLevel = 0, sessionSatisfaction = 0
        }
    end
end

function PlayerAnalytics.initializeSessionProfile()
    if not PlayerAnalytics.memory.sessionData then
        PlayerAnalytics.memory.sessionData = {
            totalSessions = 0, averageSessionLength = 0, preferredPlayTimes = {},
            sessionStartMood = {}, sessionEndMood = {}, warmupTime = 0, peakPerformanceTime = 0,
            fadeTime = 0, breakFrequency = 0, breakDuration = 0, returnBehavior = "",
            playSchedule = {}, seasonalChanges = {}, progressSatisfaction = 0
        }
    end
end

return PlayerAnalytics