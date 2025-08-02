--[[
    Insight Generator: Insight Generation and Reporting
    
    This module generates actionable insights and recommendations based on
    analyzed player behavior and patterns.
--]]

local Utils = require("src.utils.utils")
local InsightGenerator = {}

-- Insight categories
InsightGenerator.insights = {
    movement = {},
    exploration = {},
    skill = {},
    emotional = {},
    recommendations = {}
}

-- Analytics data storage
InsightGenerator.data = {
    events = {},
    gameplay = {
        jumps = 0,
        landings = 0,
        dashes = 0,
        events = {}
    },
    progression = {}
}

-- Session tracking
InsightGenerator.session = {
    id = "",
    startTime = 0,
    duration = 0,
    active = false
}

-- Initialize insight generation
function InsightGenerator.init()
    local currentTime = love and love.timer and love.timer.getTime() or os.time()
    
    InsightGenerator.data = {
        events = {},
        gameplay = {
            jumps = 0,
            landings = 0,
            dashes = 0,
            events = {}
        },
        progression = {}
    }
    
    InsightGenerator.session = {
        id = tostring(currentTime),
        startTime = currentTime,
        duration = 0,
        active = true
    }
    
    InsightGenerator.insights = {
        movement = {},
        exploration = {},
        skill = {},
        emotional = {},
        recommendations = {}
    }
end

-- Generate insights from behavior data
function InsightGenerator.generateInsights(behaviorSummary, patternAnalysis)
    InsightGenerator.insights = {
        movement = InsightGenerator.generateMovementInsights(behaviorSummary.movement),
        exploration = InsightGenerator.generateExplorationInsights(behaviorSummary.exploration),
        skill = InsightGenerator.generateSkillInsights(patternAnalysis.skill),
        emotional = InsightGenerator.generateEmotionalInsights(patternAnalysis.emotional),
        recommendations = {}
    }
    
    -- Generate recommendations based on all insights
    InsightGenerator.generateRecommendations()
    
    return InsightGenerator.insights
end

-- Generate movement insights
function InsightGenerator.generateMovementInsights(movementData)
    local insights = {}
    
    if movementData.style == "methodical" then
        table.insert(insights, {
            type = "strength",
            message = "Careful, planned movements show excellent control",
            confidence = 0.8
        })
    elseif movementData.style == "adventurous" then
        table.insert(insights, {
            type = "strength",
            message = "Bold exploration style leads to creative discoveries",
            confidence = 0.8
        })
    end
    
    if movementData.mastery < 0.3 then
        table.insert(insights, {
            type = "growth",
            message = "Movement precision is improving with practice",
            confidence = 0.7
        })
    elseif movementData.mastery > 0.7 then
        table.insert(insights, {
            type = "mastery",
            message = "Exceptional spatial control demonstrated",
            confidence = 0.9
        })
    end
    
    return insights
end

-- Generate exploration insights
function InsightGenerator.generateExplorationInsights(explorationData)
    local insights = {}
    
    if explorationData.efficiency > 0.8 then
        table.insert(insights, {
            type = "strength",
            message = "Highly efficient at discovering new areas",
            confidence = 0.9
        })
    elseif explorationData.efficiency < 0.3 then
        table.insert(insights, {
            type = "tip",
            message = "Try varying jump power for better exploration success",
            confidence = 0.6
        })
    end
    
    if explorationData.style == "methodical" then
        table.insert(insights, {
            type = "pattern",
            message = "Systematic exploration approach ensures thorough coverage",
            confidence = 0.8
        })
    end
    
    return insights
end

-- Generate skill insights
function InsightGenerator.generateSkillInsights(skillData)
    local insights = {}
    
    if skillData.velocity > 0.01 then
        table.insert(insights, {
            type = "progress",
            message = "Skills are rapidly improving",
            confidence = 0.8
        })
    elseif skillData.plateau then
        table.insert(insights, {
            type = "challenge",
            message = "Ready for new challenges to break through skill plateau",
            confidence = 0.7
        })
    end
    
    if skillData.consistency > 0.8 then
        table.insert(insights, {
            type = "mastery",
            message = "Remarkably consistent performance achieved",
            confidence = 0.9
        })
    end
    
    return insights
end

-- Generate emotional insights
function InsightGenerator.generateEmotionalInsights(emotionalData)
    local insights = {}
    
    if emotionalData.mood == "flow" then
        table.insert(insights, {
            type = "state",
            message = "In the zone - optimal performance state",
            confidence = 0.9
        })
    elseif emotionalData.mood == "frustrated" then
        table.insert(insights, {
            type = "support",
            message = "Consider a short break or easier challenge",
            confidence = 0.7
        })
    end
    
    if emotionalData.satisfaction > 0.8 then
        table.insert(insights, {
            type = "positive",
            message = "High satisfaction with current progress",
            confidence = 0.8
        })
    end
    
    if emotionalData.energy < 0.3 then
        table.insert(insights, {
            type = "wellness",
            message = "Energy levels low - perfect time for a break",
            confidence = 0.8
        })
    end
    
    return insights
end

-- Generate system recommendations
function InsightGenerator.generateRecommendations()
    local recommendations = {}
    
    -- Analyze all insights to generate recommendations
    for category, insights in pairs(InsightGenerator.insights) do
        for _, insight in ipairs(insights) do
            if insight.type == "challenge" or insight.type == "tip" then
                table.insert(recommendations, {
                    category = category,
                    priority = insight.confidence,
                    action = insight.message
                })
            end
        end
    end
    
    -- Sort by priority
    table.sort(recommendations, function(a, b) return a.priority > b.priority end)
    
    InsightGenerator.insights.recommendations = recommendations
end

-- Track gameplay event
function InsightGenerator.trackEvent(eventName, params)
    table.insert(InsightGenerator.data.events, {
        name = eventName,
        params = params or {},
        timestamp = love and love.timer and love.timer.getTime() or os.time()
    })
    
    -- Update specific counters
    if eventName == "jump" then
        InsightGenerator.data.gameplay.jumps = InsightGenerator.data.gameplay.jumps + 1
    elseif eventName == "landing" then
        InsightGenerator.data.gameplay.landings = InsightGenerator.data.gameplay.landings + 1
    elseif eventName == "dash" then
        InsightGenerator.data.gameplay.dashes = InsightGenerator.data.gameplay.dashes + 1
    end
end

-- Track progression event
function InsightGenerator.trackProgression(params)
    table.insert(InsightGenerator.data.progression, {
        type = params.type,
        value = params.value,
        timestamp = love and love.timer and love.timer.getTime() or os.time()
    })
end

-- Get session report
function InsightGenerator.getSessionReport()
    local currentTime = love and love.timer and love.timer.getTime() or os.time()
    InsightGenerator.session.duration = currentTime - InsightGenerator.session.startTime
    
    return {
        session = InsightGenerator.session,
        gameplay = InsightGenerator.data.gameplay,
        insights = InsightGenerator.insights,
        eventCount = #InsightGenerator.data.events,
        progressionCount = #InsightGenerator.data.progression
    }
end

-- Get player profile with insights
function InsightGenerator.getPlayerProfile(behaviorSummary, patternAnalysis)
    -- Generate fresh insights
    InsightGenerator.generateInsights(behaviorSummary, patternAnalysis)
    
    return {
        playstyle = {
            movement = behaviorSummary.movement.style,
            exploration = behaviorSummary.exploration.style,
            primary = behaviorSummary.movement.style -- Primary style identifier
        },
        metrics = {
            totalJumps = behaviorSummary.movement.totalJumps,
            skillLevel = patternAnalysis.skill.level,
            satisfaction = patternAnalysis.emotional.satisfaction,
            consistency = patternAnalysis.skill.consistency
        },
        insights = InsightGenerator.insights,
        recommendations = InsightGenerator.insights.recommendations
    }
end

-- Get system recommendations for game adaptation
function InsightGenerator.getSystemRecommendations(behaviorSummary, patternAnalysis)
    local recommendations = {}
    
    -- Difficulty recommendations
    if patternAnalysis.skill.level > 0.7 and not patternAnalysis.skill.plateau then
        table.insert(recommendations, {
            system = "difficulty",
            action = "increase",
            reason = "High skill level with continued improvement",
            confidence = 0.8
        })
    elseif patternAnalysis.skill.level < 0.3 and patternAnalysis.emotional.confidence < 0.4 then
        table.insert(recommendations, {
            system = "difficulty",
            action = "decrease",
            reason = "Low skill and confidence levels",
            confidence = 0.7
        })
    end
    
    -- Content recommendations
    if behaviorSummary.exploration.style == "methodical" then
        table.insert(recommendations, {
            system = "content",
            action = "show_hidden_areas",
            reason = "Player enjoys thorough exploration",
            confidence = 0.8
        })
    elseif behaviorSummary.movement.style == "adventurous" then
        table.insert(recommendations, {
            system = "content",
            action = "add_challenges",
            reason = "Player seeks risky, creative paths",
            confidence = 0.8
        })
    end
    
    -- Emotional support recommendations
    if patternAnalysis.emotional.mood == "frustrated" then
        table.insert(recommendations, {
            system = "support",
            action = "offer_hint",
            reason = "Player showing signs of frustration",
            confidence = 0.7
        })
    elseif patternAnalysis.emotional.energy < 0.3 then
        table.insert(recommendations, {
            system = "support",
            action = "suggest_break",
            reason = "Low energy levels detected",
            confidence = 0.8
        })
    end
    
    return recommendations
end

-- Save insight data
function InsightGenerator.saveState()
    return {
        data = InsightGenerator.data,
        session = InsightGenerator.session,
        insights = InsightGenerator.insights
    }
end

-- Update session data
function InsightGenerator.updateSession(sessionTime)
    if InsightGenerator.session then
        InsightGenerator.session.duration = sessionTime
    end
end

-- Restore insight data
function InsightGenerator.restoreState(state)
    if state then
        if state.data then
            InsightGenerator.data = state.data
        end
        if state.session then
            InsightGenerator.session = state.session
        end
        if state.insights then
            InsightGenerator.insights = state.insights
        end
    end
end

return InsightGenerator