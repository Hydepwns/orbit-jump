--[[
    ═══════════════════════════════════════════════════════════════════════════
    Dynamic Configuration System - A/B Testing & Live Balance Adjustments
    ═══════════════════════════════════════════════════════════════════════════
    
    This system implements the dynamic configuration framework from the Feedback
    Integration Plan, allowing for live balance adjustments and A/B testing
    without requiring game restarts.
--]]

local Utils = require("src.utils.utils")
local Config = require("src.utils.config")

local DynamicConfig = {}

-- Dynamic configuration state
DynamicConfig.isActive = false
DynamicConfig.lastUpdateTime = 0
DynamicConfig.updateInterval = 30 -- Check for updates every 30 seconds

-- Core dynamic configuration values from the plan
DynamicConfig.values = {
    -- XP System Tweaks
    xp_scaling_factors = {1.15, 1.12, 1.08, 1.05}, -- Per level tier
    xp_source_multipliers = {
        perfect_landing = 1.0,
        combo_ring = 1.0,
        discovery = 1.0,
        streak_bonus = 1.0,
        mystery_box = 1.0
    },
    
    -- Event Frequency Control
    mystery_box_spawn_rate = 0.015, -- Base rate per frame
    random_event_chance = 0.03,
    event_cooldown_minutes = 2,
    event_intensity_multiplier = 1.0,
    
    -- Streak System Balance
    grace_period_base = 3.0,
    streak_thresholds = {5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 75, 100},
    bonus_duration_multiplier = 1.0,
    streak_pressure_modifier = 1.0,
    grace_period_learning_bonus = 0.5,
    
    -- UI/Visual Settings
    particle_intensity = 1.0,
    screen_glow_intensity = 1.0,
    animation_speed = 1.0,
    ui_feedback_strength = 1.0,
    celebration_intensity = 1.0,
    
    -- Difficulty Curve Adjustments
    difficulty_scaling = 1.0,
    jump_power_scaling = 1.0,
    precision_requirement = 1.0,
    forgiveness_factor = 1.0,
    
    -- Progression Pacing
    level_up_xp_scaling = 1.0,
    reward_frequency_multiplier = 1.0,
    achievement_unlock_pacing = 1.0,
    prestige_incentive_strength = 1.0,
    
    -- Feature Toggles
    features = {
        mystery_boxes_enabled = true,
        random_events_enabled = true,
        streak_shields_enabled = true,
        adaptive_difficulty = true,
        performance_scaling = true,
        accessibility_features = true
    }
}

-- A/B Test configurations
DynamicConfig.abTests = {
    -- XP Curve Tests
    xp_curve_test = {
        enabled = true,
        variants = {
            control = {xp_scaling_factors = {1.15, 1.12, 1.08, 1.05}},
            variant_a = {xp_scaling_factors = {1.20, 1.15, 1.10, 1.05}}, -- Faster early, same late
            variant_b = {xp_scaling_factors = {1.10, 1.08, 1.06, 1.04}}  -- Slower overall
        }
    },
    
    -- Event Frequency Tests  
    event_frequency_test = {
        enabled = true,
        variants = {
            high = {mystery_box_spawn_rate = 0.020, random_event_chance = 0.04},
            normal = {mystery_box_spawn_rate = 0.015, random_event_chance = 0.03},
            low = {mystery_box_spawn_rate = 0.010, random_event_chance = 0.02}
        }
    },
    
    -- Grace Period Tests
    grace_period_test = {
        enabled = true,
        variants = {
            short = {grace_period_base = 2.5},
            normal = {grace_period_base = 3.0},
            long = {grace_period_base = 3.5}
        }
    },
    
    -- Visual Effects Tests
    visual_effects_test = {
        enabled = true,
        variants = {
            full = {particle_intensity = 1.0, screen_glow_intensity = 1.0},
            reduced = {particle_intensity = 0.6, screen_glow_intensity = 0.7},
            minimal = {particle_intensity = 0.3, screen_glow_intensity = 0.4}
        }
    }
}

-- Configuration change history for rollback
DynamicConfig.history = {}
DynamicConfig.maxHistorySize = 10

-- Performance thresholds for automatic rollback
DynamicConfig.rollbackThresholds = {
    retention_drop_percent = 10, -- Rollback if retention drops > 10%
    crash_rate_threshold = 0.01, -- Rollback if crash rate > 1%
    fps_drop_threshold = 0.15,   -- Rollback if avg FPS drops > 15%
    satisfaction_drop = 0.5      -- Rollback if satisfaction drops > 0.5 points
}

-- Initialize dynamic configuration system
function DynamicConfig.init()
    DynamicConfig.isActive = true
    DynamicConfig.lastUpdateTime = love.timer.getTime()
    
    -- Load saved configuration state
    DynamicConfig.loadState()
    
    -- Apply initial configuration based on A/B test assignments
    DynamicConfig.applyABTestAssignments()
    
    Utils.Logger.info("⚙️ Dynamic Configuration System initialized")
    return true
end

-- Apply A/B test assignments from Analytics system
function DynamicConfig.applyABTestAssignments()
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if not FeedbackAnalytics or not FeedbackAnalytics.abTests then return end
    
    local assignments = FeedbackAnalytics.abTests.test_assignments
    if not assignments then return end
    
    -- Apply XP scaling variant
    if assignments.xp_scaling and DynamicConfig.abTests.xp_curve_test.variants[assignments.xp_scaling] then
        local variant = DynamicConfig.abTests.xp_curve_test.variants[assignments.xp_scaling]
        DynamicConfig.applyConfigurationChange("xp_scaling_factors", variant.xp_scaling_factors, "ab_test")
    end
    
    -- Apply event frequency variant
    if assignments.event_frequency and DynamicConfig.abTests.event_frequency_test.variants[assignments.event_frequency] then
        local variant = DynamicConfig.abTests.event_frequency_test.variants[assignments.event_frequency]
        DynamicConfig.applyConfigurationChange("mystery_box_spawn_rate", variant.mystery_box_spawn_rate, "ab_test")
        DynamicConfig.applyConfigurationChange("random_event_chance", variant.random_event_chance, "ab_test")
    end
    
    -- Apply grace period variant
    if assignments.grace_period then
        DynamicConfig.applyConfigurationChange("grace_period_base", assignments.grace_period, "ab_test")
    end
    
    -- Apply visual intensity variant
    if assignments.visual_intensity and DynamicConfig.abTests.visual_effects_test.variants[assignments.visual_intensity] then
        local variant = DynamicConfig.abTests.visual_effects_test.variants[assignments.visual_intensity]
        DynamicConfig.applyConfigurationChange("particle_intensity", variant.particle_intensity, "ab_test")
        DynamicConfig.applyConfigurationChange("screen_glow_intensity", variant.screen_glow_intensity, "ab_test")
    end
    
    Utils.Logger.info("⚙️ A/B test configurations applied")
end

-- Get current configuration value
function DynamicConfig.getValue(key)
    return DynamicConfig.values[key]
end

-- Get XP scaling factor for a specific level tier
function DynamicConfig.getXPScalingFactor(tier)
    local factors = DynamicConfig.values.xp_scaling_factors
    local index = math.min(tier, #factors)
    return factors[index] or 1.05 -- Default fallback
end

-- Get XP multiplier for a specific source
function DynamicConfig.getXPMultiplier(source)
    return DynamicConfig.values.xp_source_multipliers[source] or 1.0
end

-- Get grace period with learning bonus applied
function DynamicConfig.getGracePeriod(playerSkillLevel)
    local basePeriod = DynamicConfig.values.grace_period_base
    local learningBonus = DynamicConfig.values.grace_period_learning_bonus
    
    -- New players get extra grace period
    if playerSkillLevel and playerSkillLevel < 0.3 then
        return basePeriod + (learningBonus * (0.3 - playerSkillLevel))
    end
    
    return basePeriod
end

-- Get streak threshold for a specific level
function DynamicConfig.getStreakThreshold(level)
    local thresholds = DynamicConfig.values.streak_thresholds
    
    -- Find appropriate threshold
    for i = 1, #thresholds do
        if level <= thresholds[i] then
            return thresholds[i]
        end
    end
    
    -- For very high levels, extrapolate
    return thresholds[#thresholds] + (level - thresholds[#thresholds])
end

-- Check if a feature is enabled
function DynamicConfig.isFeatureEnabled(featureName)
    return DynamicConfig.values.features[featureName] ~= false
end

-- Apply a configuration change with history tracking
function DynamicConfig.applyConfigurationChange(key, value, reason)
    -- Store current value in history
    local historyEntry = {
        timestamp = love.timer.getTime(),
        key = key,
        oldValue = DynamicConfig.values[key],
        newValue = value,
        reason = reason or "manual"
    }
    
    table.insert(DynamicConfig.history, historyEntry)
    
    -- Limit history size
    if #DynamicConfig.history > DynamicConfig.maxHistorySize then
        table.remove(DynamicConfig.history, 1)
    end
    
    -- Apply the change
    if key == "xp_source_multipliers" and type(value) == "table" then
        for source, multiplier in pairs(value) do
            DynamicConfig.values.xp_source_multipliers[source] = multiplier
        end
    elseif key == "features" and type(value) == "table" then
        for feature, enabled in pairs(value) do
            DynamicConfig.values.features[feature] = enabled
        end
    else
        DynamicConfig.values[key] = value
    end
    
    -- Notify systems of configuration change
    DynamicConfig.notifyConfigurationChange(key, value)
    
    -- Save state
    DynamicConfig.saveState()
    
    Utils.Logger.info("⚙️ Configuration changed: %s = %s (reason: %s)", 
                     key, tostring(value), reason)
end

-- Batch apply multiple configuration changes
function DynamicConfig.applyConfigurationBatch(changes, reason)
    for key, value in pairs(changes) do
        DynamicConfig.applyConfigurationChange(key, value, reason)
    end
end

-- Rollback to previous configuration
function DynamicConfig.rollbackConfiguration(steps)
    steps = steps or 1
    
    if #DynamicConfig.history < steps then
        Utils.Logger.warn("⚙️ Cannot rollback %d steps, only %d entries in history", steps, #DynamicConfig.history)
        return false
    end
    
    -- Apply rollback for the specified number of steps
    for i = 1, steps do
        local entry = table.remove(DynamicConfig.history) -- Remove from end (most recent)
        if entry then
            DynamicConfig.values[entry.key] = entry.oldValue
            DynamicConfig.notifyConfigurationChange(entry.key, entry.oldValue)
            Utils.Logger.info("⚙️ Rolled back: %s = %s", entry.key, tostring(entry.oldValue))
        end
    end
    
    DynamicConfig.saveState()
    return true
end

-- Automatic rollback based on performance metrics
function DynamicConfig.checkAutoRollback(metrics)
    if not metrics then return false end
    
    local shouldRollback = false
    local reason = ""
    
    -- Check retention drop
    if metrics.retention_drop and metrics.retention_drop > DynamicConfig.rollbackThresholds.retention_drop_percent then
        shouldRollback = true
        reason = string.format("retention drop: %.1f%%", metrics.retention_drop)
    end
    
    -- Check crash rate
    if metrics.crash_rate and metrics.crash_rate > DynamicConfig.rollbackThresholds.crash_rate_threshold then
        shouldRollback = true
        reason = string.format("crash rate: %.2f%%", metrics.crash_rate * 100)
    end
    
    -- Check FPS drop
    if metrics.fps_drop and metrics.fps_drop > DynamicConfig.rollbackThresholds.fps_drop_threshold then
        shouldRollback = true
        reason = string.format("FPS drop: %.1f%%", metrics.fps_drop * 100)
    end
    
    -- Check satisfaction drop
    if metrics.satisfaction_drop and metrics.satisfaction_drop > DynamicConfig.rollbackThresholds.satisfaction_drop then
        shouldRollback = true
        reason = string.format("satisfaction drop: %.1f points", metrics.satisfaction_drop)
    end
    
    if shouldRollback then
        Utils.Logger.warn("⚠️ Auto-rollback triggered: %s", reason)
        DynamicConfig.rollbackConfiguration(1)
        
        -- Track rollback event
        local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
        if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
            FeedbackAnalytics.trackEvent("auto_rollback", {
                reason = reason,
                metrics = metrics
            })
        end
        
        return true
    end
    
    return false
end

-- Notify other systems of configuration changes
function DynamicConfig.notifyConfigurationChange(key, value)
    -- Notify relevant systems
    if string.find(key, "xp_") then
        local XPSystem = Utils.require("src.systems.xp_system")
        if XPSystem and XPSystem.onConfigurationChanged then
            XPSystem.onConfigurationChanged(key, value)
        end
    end
    
    if string.find(key, "streak_") or key == "grace_period_base" then
        local StreakSystem = Utils.require("src.systems.streak_system")
        if StreakSystem and StreakSystem.onConfigurationChanged then
            StreakSystem.onConfigurationChanged(key, value)
        end
    end
    
    if string.find(key, "event_") or string.find(key, "mystery_box") then
        local MysteryBoxSystem = Utils.require("src.systems.mystery_box_system")
        local RandomEventsSystem = Utils.require("src.systems.random_events_system")
        
        if MysteryBoxSystem and MysteryBoxSystem.onConfigurationChanged then
            MysteryBoxSystem.onConfigurationChanged(key, value) 
        end
        
        if RandomEventsSystem and RandomEventsSystem.onConfigurationChanged then
            RandomEventsSystem.onConfigurationChanged(key, value)
        end
    end
    
    if string.find(key, "particle_") or string.find(key, "glow_") or string.find(key, "animation_") then
        local Renderer = Utils.require("src.core.renderer")
        if Renderer and Renderer.onConfigurationChanged then
            Renderer.onConfigurationChanged(key, value)
        end
    end
end

-- Update system (check for remote configuration updates)
function DynamicConfig.update(dt)
    if not DynamicConfig.isActive then return end
    
    local currentTime = love.timer.getTime()
    
    -- Check for configuration updates periodically
    if currentTime - DynamicConfig.lastUpdateTime > DynamicConfig.updateInterval then
        DynamicConfig.checkForRemoteUpdates()
        DynamicConfig.lastUpdateTime = currentTime
    end
end

-- Check for remote configuration updates (placeholder for server integration)
function DynamicConfig.checkForRemoteUpdates()
    -- In a real implementation, this would fetch from a configuration server
    -- For now, we'll just validate current configuration
    
    local valid, errors = DynamicConfig.validateConfiguration()
    if not valid then
        Utils.Logger.warn("⚠️ Configuration validation failed: %s", table.concat(errors, ", "))
        -- Could trigger automatic fix or rollback here
    end
end

-- Validate current configuration
function DynamicConfig.validateConfiguration()
    local errors = {}
    
    -- Validate XP scaling factors
    if not DynamicConfig.values.xp_scaling_factors or #DynamicConfig.values.xp_scaling_factors == 0 then
        table.insert(errors, "XP scaling factors missing")
    else
        for i, factor in ipairs(DynamicConfig.values.xp_scaling_factors) do
            if type(factor) ~= "number" or factor <= 0 or factor > 5 then
                table.insert(errors, string.format("Invalid XP scaling factor[%d]: %s", i, tostring(factor)))
            end
        end
    end
    
    -- Validate spawn rates
    if DynamicConfig.values.mystery_box_spawn_rate < 0 or DynamicConfig.values.mystery_box_spawn_rate > 1 then
        table.insert(errors, "Mystery box spawn rate out of range")
    end
    
    if DynamicConfig.values.random_event_chance < 0 or DynamicConfig.values.random_event_chance > 1 then
        table.insert(errors, "Random event chance out of range")
    end
    
    -- Validate grace period
    if DynamicConfig.values.grace_period_base < 0.5 or DynamicConfig.values.grace_period_base > 10 then
        table.insert(errors, "Grace period out of reasonable range")
    end
    
    -- Validate multipliers
    local multiplierKeys = {"particle_intensity", "screen_glow_intensity", "animation_speed"}
    for _, key in ipairs(multiplierKeys) do
        if DynamicConfig.values[key] < 0 or DynamicConfig.values[key] > 3 then
            table.insert(errors, string.format("%s out of range", key))
        end
    end
    
    return #errors == 0, errors
end

-- Get configuration report for debugging
function DynamicConfig.getConfigurationReport()
    return {
        current_values = DynamicConfig.values,
        history = DynamicConfig.history,
        ab_tests = DynamicConfig.abTests,
        rollback_thresholds = DynamicConfig.rollbackThresholds,
        last_update = DynamicConfig.lastUpdateTime,
        is_active = DynamicConfig.isActive
    }
end

-- Save configuration state
function DynamicConfig.saveState()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("dynamicConfig", {
            values = DynamicConfig.values,
            history = DynamicConfig.history,
            last_update = love.timer.getTime()
        })
    end
end

-- Load configuration state
function DynamicConfig.loadState()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local data = SaveSystem.getData("dynamicConfig")
        if data then
            if data.values then
                -- Merge saved values with defaults
                for key, value in pairs(data.values) do
                    DynamicConfig.values[key] = value
                end
            end
            if data.history then
                DynamicConfig.history = data.history
            end
            Utils.Logger.info("⚙️ Dynamic configuration state loaded")
        end
    end
end

-- Export current configuration for external tools
function DynamicConfig.exportConfiguration()
    return {
        timestamp = love.timer.getTime(),
        values = DynamicConfig.values,
        ab_tests = DynamicConfig.abTests,
        history = DynamicConfig.history
    }
end

-- Import configuration from external source
function DynamicConfig.importConfiguration(configData, reason)
    if not configData or not configData.values then
        Utils.Logger.error("Invalid configuration data for import")
        return false
    end
    
    -- Validate imported configuration
    local tempValues = DynamicConfig.values
    DynamicConfig.values = configData.values
    
    local valid, errors = DynamicConfig.validateConfiguration()
    if not valid then
        DynamicConfig.values = tempValues -- Restore original
        Utils.Logger.error("Configuration import failed validation: %s", table.concat(errors, ", "))
        return false
    end
    
    -- Apply all changes as a batch
    for key, value in pairs(configData.values) do
        DynamicConfig.applyConfigurationChange(key, value, reason or "import")
    end
    
    Utils.Logger.info("⚙️ Configuration imported successfully")
    return true
end

return DynamicConfig