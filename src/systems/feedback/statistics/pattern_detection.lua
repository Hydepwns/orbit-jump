--[[
    ═══════════════════════════════════════════════════════════════════════════
    Pattern Detection - Behavioral Pattern Recognition
    ═══════════════════════════════════════════════════════════════════════════
    
    This module provides pattern recognition capabilities for analyzing player
    behavior, identifying common sequences, and detecting anomalies in gameplay data.
--]]

local Utils = require("src.utils.utils")
local StatisticalTools = require("src.systems.feedback.statistics.statistical_tools")

local PatternDetection = {}

-- Configuration
PatternDetection.config = {
    min_sequence_length = 3,
    min_occurrence_threshold = 3,
    max_sequence_length = 10,
    similarity_threshold = 0.8
}

-- Player Journey Analysis
function PatternDetection.analyzePlayerJourneys(sessionData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    
    local journeys = {}
    local commonPaths = {}
    
    -- Extract event sequences from sessions
    for _, session in ipairs(sessionData) do
        if session.events and #session.events > 0 then
            local journey = {}
            for _, event in ipairs(session.events) do
                if event.name then
                    table.insert(journey, event.name)
                end
            end
            if #journey > 0 then
                table.insert(journeys, journey)
            end
        end
    end
    
    -- Find common sequences
    local sequenceCounts = {}
    for _, journey in ipairs(journeys) do
        for length = PatternDetection.config.min_sequence_length, 
                     math.min(PatternDetection.config.max_sequence_length, #journey) do
            for i = 1, #journey - length + 1 do
                local sequence = table.concat(journey, "->", i, i + length - 1)
                sequenceCounts[sequence] = (sequenceCounts[sequence] or 0) + 1
            end
        end
    end
    
    -- Extract most common paths
    for sequence, count in pairs(sequenceCounts) do
        if count >= PatternDetection.config.min_occurrence_threshold then
            table.insert(commonPaths, {
                sequence = sequence,
                frequency = count,
                percentage = (count / #journeys) * 100
            })
        end
    end
    
    -- Sort by frequency
    table.sort(commonPaths, function(a, b) return a.frequency > b.frequency end)
    
    return {
        total_journeys = #journeys,
        common_paths = commonPaths,
        unique_patterns = PatternDetection.countUniquePatterns(journeys),
        average_journey_length = PatternDetection.calculateAverageJourneyLength(journeys)
    }
end

-- Count unique patterns in journeys
function PatternDetection.countUniquePatterns(journeys)
    local uniquePatterns = {}
    
    for _, journey in ipairs(journeys) do
        local pattern = table.concat(journey, "->")
        uniquePatterns[pattern] = true
    end
    
    return table.getn(uniquePatterns)
end

-- Calculate average journey length
function PatternDetection.calculateAverageJourneyLength(journeys)
    if #journeys == 0 then return 0 end
    
    local totalLength = 0
    for _, journey in ipairs(journeys) do
        totalLength = totalLength + #journey
    end
    
    return totalLength / #journeys
end

-- Quit Point Analysis
function PatternDetection.analyzeQuitPoints(quitData, thresholds)
    if not quitData then
        return {error = "No quit data provided"}
    end
    
    thresholds = thresholds or {
        quit_point_threshold = 0.15, -- 15% quit rate triggers review
        min_quit_count = 5
    }
    
    local quitsByLevel = {}
    local quitsByContext = {}
    
    -- Aggregate quit data
    for level, quitCount in pairs(quitData) do
        if quitCount and quitCount > 0 then
            quitsByLevel[level] = quitCount
        end
    end
    
    -- Calculate total quits
    local totalQuits = 0
    for _, count in pairs(quitsByLevel) do
        totalQuits = totalQuits + count
    end
    
    -- Find problematic levels
    local problematicLevels = {}
    for level, count in pairs(quitsByLevel) do
        if count >= thresholds.min_quit_count then
            local quitRate = count / totalQuits
            if quitRate > thresholds.quit_point_threshold then
                table.insert(problematicLevels, {
                    level = level,
                    quit_rate = quitRate,
                    quit_count = count,
                    severity = PatternDetection.calculateQuitSeverity(quitRate, thresholds.quit_point_threshold)
                })
            end
        end
    end
    
    -- Sort by quit rate
    table.sort(problematicLevels, function(a, b) return a.quit_rate > b.quit_rate end)
    
    return {
        total_quits = totalQuits,
        problematic_levels = problematicLevels,
        quit_distribution = quitsByLevel,
        average_quit_rate = totalQuits > 0 and totalQuits / table.getn(quitsByLevel) or 0
    }
end

-- Calculate quit severity level
function PatternDetection.calculateQuitSeverity(quitRate, threshold)
    local ratio = quitRate / threshold
    if ratio > 3 then return "critical"
    elseif ratio > 2 then return "high"
    elseif ratio > 1.5 then return "moderate"
    else return "low"
    end
end

-- Behavioral Pattern Classification
function PatternDetection.classifyPlayerBehavior(sessionData, playerMetrics)
    if not sessionData or not playerMetrics then
        return {error = "Missing session data or player metrics"}
    end
    
    local behaviorPatterns = {
        player_segments = {},
        common_journeys = {},
        drop_off_points = {},
        engagement_drivers = {}
    }
    
    -- Analyze session patterns
    local sessionAnalysis = PatternDetection.analyzeSessionPatterns(sessionData)
    behaviorPatterns.session_patterns = sessionAnalysis
    
    -- Classify player segments
    behaviorPatterns.player_segments = PatternDetection.classifyPlayerSegments(playerMetrics)
    
    -- Identify drop-off points
    behaviorPatterns.drop_off_points = PatternDetection.identifyDropOffPoints(sessionData)
    
    -- Find engagement drivers
    behaviorPatterns.engagement_drivers = PatternDetection.identifyEngagementDrivers(sessionData, playerMetrics)
    
    return behaviorPatterns
end

-- Analyze session patterns
function PatternDetection.analyzeSessionPatterns(sessionData)
    local patterns = {
        session_lengths = {},
        session_frequencies = {},
        time_of_day_patterns = {},
        day_of_week_patterns = {}
    }
    
    -- Extract session lengths
    for _, session in ipairs(sessionData) do
        if session.duration then
            table.insert(patterns.session_lengths, session.duration)
        end
    end
    
    -- Calculate session frequency patterns
    local sessionCounts = {}
    for _, session in ipairs(sessionData) do
        if session.date then
            local date = os.date("%Y-%m-%d", session.date)
            sessionCounts[date] = (sessionCounts[date] or 0) + 1
        end
    end
    
    for date, count in pairs(sessionCounts) do
        table.insert(patterns.session_frequencies, count)
    end
    
    return patterns
end

-- Classify player segments
function PatternDetection.classifyPlayerSegments(playerMetrics)
    local segments = {
        casual = {criteria = {}, players = {}},
        regular = {criteria = {}, players = {}},
        hardcore = {criteria = {}, players = {}},
        at_risk = {criteria = {}, players = {}}
    }
    
    -- Define segment criteria
    segments.casual.criteria = {
        sessions_per_day = {max = 1},
        avg_session_duration = {max = 300}, -- 5 minutes
        total_playtime = {max = 3600} -- 1 hour
    }
    
    segments.regular.criteria = {
        sessions_per_day = {min = 1, max = 3},
        avg_session_duration = {min = 300, max = 900}, -- 5-15 minutes
        total_playtime = {min = 3600, max = 18000} -- 1-5 hours
    }
    
    segments.hardcore.criteria = {
        sessions_per_day = {min = 3},
        avg_session_duration = {min = 900}, -- 15+ minutes
        total_playtime = {min = 18000} -- 5+ hours
    }
    
    segments.at_risk.criteria = {
        sessions_per_day = {max = 0.5},
        avg_session_duration = {max = 180}, -- 3 minutes
        progression_satisfaction = {max = 3.0}
    }
    
    return segments
end

-- Identify drop-off points
function PatternDetection.identifyDropOffPoints(sessionData)
    local dropOffPoints = {}
    
    -- Analyze session completion rates
    local completionRates = {}
    for _, session in ipairs(sessionData) do
        if session.level and session.completed then
            completionRates[session.level] = completionRates[session.level] or {completed = 0, total = 0}
            completionRates[session.level].total = completionRates[session.level].total + 1
            if session.completed then
                completionRates[session.level].completed = completionRates[session.level].completed + 1
            end
        end
    end
    
    -- Find levels with low completion rates
    for level, data in pairs(completionRates) do
        local completionRate = data.completed / data.total
        if completionRate < 0.7 and data.total >= 10 then -- Less than 70% completion
            table.insert(dropOffPoints, {
                level = level,
                completion_rate = completionRate,
                total_attempts = data.total,
                severity = completionRate < 0.5 and "critical" or "moderate"
            })
        end
    end
    
    table.sort(dropOffPoints, function(a, b) return a.completion_rate < b.completion_rate end)
    
    return dropOffPoints
end

-- Identify engagement drivers
function PatternDetection.identifyEngagementDrivers(sessionData, playerMetrics)
    local drivers = {
        positive_drivers = {},
        negative_drivers = {},
        recommendations = {}
    }
    
    -- Analyze correlation between metrics and engagement
    if playerMetrics.satisfaction_scores and playerMetrics.session_lengths then
        local correlation = StatisticalTools.correlation(
            playerMetrics.satisfaction_scores,
            playerMetrics.session_lengths
        )
        
        if correlation.correlation > 0.3 then
            table.insert(drivers.positive_drivers, {
                factor = "satisfaction",
                correlation = correlation.correlation,
                strength = correlation.strength
            })
        end
    end
    
    -- Analyze reward frequency impact
    if playerMetrics.reward_frequency and playerMetrics.retention_rates then
        local correlation = StatisticalTools.correlation(
            playerMetrics.reward_frequency,
            playerMetrics.retention_rates
        )
        
        if correlation.correlation > 0.2 then
            table.insert(drivers.positive_drivers, {
                factor = "reward_frequency",
                correlation = correlation.correlation,
                strength = correlation.strength
            })
        end
    end
    
    return drivers
end

-- Anomaly Detection
function PatternDetection.detectAnomalies(data, method)
    method = method or "statistical"
    
    if method == "statistical" then
        return PatternDetection.statisticalAnomalyDetection(data)
    elseif method == "isolation_forest" then
        return PatternDetection.isolationForestAnomalyDetection(data)
    end
    
    return {}
end

-- Statistical anomaly detection
function PatternDetection.statisticalAnomalyDetection(data)
    if not data or #data < 10 then
        return {error = "Insufficient data for anomaly detection"}
    end
    
    local mean = StatisticalTools.mean(data)
    local stdDev = StatisticalTools.standardDeviation(data, mean)
    
    local anomalies = {}
    for i, value in ipairs(data) do
        local zScore = math.abs((value - mean) / stdDev)
        if zScore > 2.5 then -- More than 2.5 standard deviations
            table.insert(anomalies, {
                index = i,
                value = value,
                z_score = zScore,
                severity = zScore > 3.5 and "extreme" or "moderate"
            })
        end
    end
    
    return anomalies
end

-- Simplified isolation forest anomaly detection
function PatternDetection.isolationForestAnomalyDetection(data)
    -- Simplified implementation - in production would use proper isolation forest
    local anomalies = {}
    local sorted = {}
    
    for i, v in ipairs(data) do sorted[i] = v end
    table.sort(sorted)
    
    local q1 = StatisticalTools.percentile(sorted, 0.25)
    local q3 = StatisticalTools.percentile(sorted, 0.75)
    local iqr = q3 - q1
    
    for i, value in ipairs(data) do
        if value < (q1 - 1.5 * iqr) or value > (q3 + 1.5 * iqr) then
            table.insert(anomalies, {
                index = i,
                value = value,
                method = "iqr",
                severity = "moderate"
            })
        end
    end
    
    return anomalies
end

-- Sequence Similarity Analysis
function PatternDetection.calculateSequenceSimilarity(seq1, seq2)
    if not seq1 or not seq2 then return 0 end
    
    -- Simple Levenshtein distance-based similarity
    local distance = PatternDetection.levenshteinDistance(seq1, seq2)
    local maxLength = math.max(#seq1, #seq2)
    
    if maxLength == 0 then return 1 end
    
    return 1 - (distance / maxLength)
end

-- Levenshtein distance calculation
function PatternDetection.levenshteinDistance(seq1, seq2)
    local matrix = {}
    
    for i = 0, #seq1 do
        matrix[i] = {}
        matrix[i][0] = i
    end
    
    for j = 0, #seq2 do
        matrix[0][j] = j
    end
    
    for i = 1, #seq1 do
        for j = 1, #seq2 do
            local cost = seq1[i] == seq2[j] and 0 or 1
            matrix[i][j] = math.min(
                matrix[i-1][j] + 1,     -- deletion
                matrix[i][j-1] + 1,     -- insertion
                matrix[i-1][j-1] + cost -- substitution
            )
        end
    end
    
    return matrix[#seq1][#seq2]
end

return PatternDetection 