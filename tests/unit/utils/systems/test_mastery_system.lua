-- Test suite for Mastery System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup
Mocks.setup()
TestFramework.init()
-- Load system
local MasterySystem = Utils.require("src.systems.mastery_system")
-- Test helper functions
local function setupSystem()
    -- Reset mastery data by accessing the internal mastery table
    local mastery_data = MasterySystem.getData()
    mastery_data.planet_mastery = {}
    mastery_data.technique_mastery = {}
    mastery_data.total_mastery_points = 0
    mastery_data.unlocked_bonuses = {}
    mastery_data.mentor_status = false
end
-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        TestFramework.assert(type(data.planet_mastery) == "table", "Should have planet mastery table")
        TestFramework.assert(type(data.technique_mastery) == "table", "Should have technique mastery table")
        TestFramework.assert(data.total_mastery_points == 0, "Should start with 0 mastery points")
        TestFramework.assert(data.mentor_status == false, "Should start without mentor status")
        -- Check planet mastery initialization
        TestFramework.assert(data.planet_mastery["normal"] ~= nil, "Should initialize normal planet mastery")
        TestFramework.assert(data.planet_mastery["normal"].perfect_landings == 0, "Should start with 0 perfect landings")
        TestFramework.assert(data.planet_mastery["normal"].current_level == 0, "Should start at level 0")
        TestFramework.assert(data.planet_mastery["normal"].total_landings == 0, "Should start with 0 total landings")
        TestFramework.assert(type(data.planet_mastery["normal"].bonuses_unlocked) == "table", "Should have bonuses table")
        -- Check technique mastery initialization
        TestFramework.assert(data.technique_mastery["bank_shot"] ~= nil, "Should initialize bank shot technique")
        TestFramework.assert(data.technique_mastery["bank_shot"].count == 0, "Should start with 0 count")
        TestFramework.assert(data.technique_mastery["bank_shot"].completed == false, "Should start incomplete")
        TestFramework.assert(data.technique_mastery["bank_shot"].tutorial_unlocked == false, "Should start without tutorial")
        -- Verify all planet types are initialized
        local planet_types = {"normal", "ice", "fire", "bouncy", "gravity", "tiny", "giant", "ring_rich", "void", "storm", "crystal", "magnetic"}
        for _, planet_type in ipairs(planet_types) do
            TestFramework.assert(data.planet_mastery[planet_type] ~= nil, "Should initialize " .. planet_type .. " planet mastery")
        end
        -- Verify all techniques are initialized
        local techniques = {"bank_shot", "gravity_slingshot", "precision_landing", "combo_master", "speed_demon", "ring_sniper"}
        for _, technique in ipairs(techniques) do
            TestFramework.assert(data.technique_mastery[technique] ~= nil, "Should initialize " .. technique .. " technique")
        end
    end,
    ["planet landing tracking - normal landing"] = function()
        setupSystem()
        MasterySystem.init()
        local result = MasterySystem.trackPlanetLanding("normal", false, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        local data = MasterySystem.getData()
        TestFramework.assert(data.planet_mastery["normal"].total_landings == 1, "Should increment total landings")
        TestFramework.assert(data.planet_mastery["normal"].perfect_landings == 0, "Should not increment perfect landings")
        TestFramework.assert(data.planet_mastery["normal"].current_level == 0, "Should remain at level 0")
        TestFramework.assert(result == nil, "Should not return level up info for normal landing")
    end,
    ["planet landing tracking - perfect landing"] = function()
        setupSystem()
        MasterySystem.init()
        local result = MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        local data = MasterySystem.getData()
        TestFramework.assert(data.planet_mastery["normal"].total_landings == 1, "Should increment total landings")
        TestFramework.assert(data.planet_mastery["normal"].perfect_landings == 1, "Should increment perfect landings")
        TestFramework.assert(result == nil, "Should not level up with only 1 perfect landing")
    end,
    ["planet mastery level up"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        data.planet_mastery["normal"].perfect_landings = 9
        -- 10th perfect landing should trigger level up
        local result = MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        TestFramework.assert(result ~= nil, "Should return level up info")
        TestFramework.assert(result.type == "planet_mastery", "Should be planet mastery level up")
        TestFramework.assert(result.planet == "Terra", "Should include planet name")
        TestFramework.assert(result.level == 1, "Should reach level 1")
        TestFramework.assert(type(result.bonus) == "string", "Should include bonus description")
        TestFramework.assert(result.points == 2, "Should award 2 mastery points")
        TestFramework.assert(data.planet_mastery["normal"].current_level == 1, "Should update current level")
        TestFramework.assert(data.total_mastery_points == 2, "Should update total mastery points")
        TestFramework.assert(#data.planet_mastery["normal"].bonuses_unlocked == 1, "Should unlock bonus")
    end,
    ["planet mastery multiple levels"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        -- Level up to level 2 (50 perfect landings)
        data.planet_mastery["ice"].perfect_landings = 49
        local result = MasterySystem.trackPlanetLanding("ice", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        TestFramework.assert(result.level == 2, "Should reach level 2")
        TestFramework.assert(result.points == 3, "Should award 3 mastery points for level 2")
        TestFramework.assert(data.planet_mastery["ice"].current_level == 2, "Should update to level 2")
        TestFramework.assert(data.total_mastery_points == 5, "Should have 5 total points (2 + 3)")
    end,
    ["planet mastery unknown planet type"] = function()
        setupSystem()
        MasterySystem.init()
        -- Should handle gracefully
        local result = MasterySystem.trackPlanetLanding("unknown", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        TestFramework.assert(result == nil, "Should handle unknown planet type gracefully")
        local data = MasterySystem.getData()
        TestFramework.assert(data.total_mastery_points == 0, "Should not award points for unknown planet")
    end,
    ["bullseye landing detection"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        -- Landing exactly at center (distance = 0)
        MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        TestFramework.assert(data.technique_mastery["precision_landing"].count == 1, "Should detect bullseye landing")
        -- Landing within 5 pixel tolerance
        MasterySystem.trackPlanetLanding("normal", true, {x = 103, y = 104}, {x = 100, y = 100}, 50)
        TestFramework.assert(data.technique_mastery["precision_landing"].count == 2, "Should detect bullseye within tolerance")
        -- Landing outside tolerance
        MasterySystem.trackPlanetLanding("normal", true, {x = 110, y = 110}, {x = 100, y = 100}, 50)
        TestFramework.assert(data.technique_mastery["precision_landing"].count == 2, "Should not count landing outside tolerance")
    end,
    ["technique tracking - bank shot"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        local result = MasterySystem.trackTechnique("bank_shot", {curved_path = true})
        TestFramework.assert(data.technique_mastery["bank_shot"].count == 1, "Should increment bank shot count")
        TestFramework.assert(result == nil, "Should not complete with only 1 attempt")
        -- Invalid attempt
        MasterySystem.trackTechnique("bank_shot", {curved_path = false})
        TestFramework.assert(data.technique_mastery["bank_shot"].count == 1, "Should not increment invalid attempt")
    end,
    ["technique tracking - gravity slingshot"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        MasterySystem.trackTechnique("gravity_slingshot", {speed_boost = 1.6})
        TestFramework.assert(data.technique_mastery["gravity_slingshot"].count == 1, "Should count valid gravity assist")
        -- Insufficient speed boost
        MasterySystem.trackTechnique("gravity_slingshot", {speed_boost = 1.2})
        TestFramework.assert(data.technique_mastery["gravity_slingshot"].count == 1, "Should not count insufficient speed boost")
    end,
    ["technique tracking - combo master"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        MasterySystem.trackTechnique("combo_master", {combo_length = 25})
        TestFramework.assert(data.technique_mastery["combo_master"].count == 1, "Should count high combo")
        MasterySystem.trackTechnique("combo_master", {combo_length = 15})
        TestFramework.assert(data.technique_mastery["combo_master"].count == 1, "Should not count low combo")
    end,
    ["technique tracking - speed demon"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        MasterySystem.trackTechnique("speed_demon", {jump_speed = 850})
        TestFramework.assert(data.technique_mastery["speed_demon"].count == 1, "Should count high speed jump")
        MasterySystem.trackTechnique("speed_demon", {jump_speed = 750})
        TestFramework.assert(data.technique_mastery["speed_demon"].count == 1, "Should not count low speed jump")
    end,
    ["technique tracking - ring sniper"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        MasterySystem.trackTechnique("ring_sniper", {perfect_collection = true})
        TestFramework.assert(data.technique_mastery["ring_sniper"].count == 1, "Should count perfect ring collection")
        MasterySystem.trackTechnique("ring_sniper", {perfect_collection = false})
        TestFramework.assert(data.technique_mastery["ring_sniper"].count == 1, "Should not count imperfect collection")
    end,
    ["technique completion"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        data.technique_mastery["precision_landing"].count = 499
        -- Complete technique with 500th attempt
        local result = MasterySystem.trackTechnique("precision_landing", {bullseye = true})
        TestFramework.assert(result ~= nil, "Should return completion info")
        TestFramework.assert(result.type == "technique_mastery", "Should be technique mastery")
        TestFramework.assert(result.technique == "Bullseye Champion", "Should include technique name")
        TestFramework.assert(result.points == 15, "Should award 15 mastery points")
        TestFramework.assert(result.mentor_status == false, "Should not have mentor status yet")
        TestFramework.assert(data.technique_mastery["precision_landing"].completed == true, "Should mark as completed")
        TestFramework.assert(data.technique_mastery["precision_landing"].tutorial_unlocked == true, "Should unlock tutorial")
        TestFramework.assert(data.total_mastery_points == 15, "Should update total mastery points")
    end,
    ["technique completion - already completed"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        data.technique_mastery["bank_shot"].completed = true
        local result = MasterySystem.trackTechnique("bank_shot", {curved_path = true})
        TestFramework.assert(result == nil, "Should not track already completed technique")
        TestFramework.assert(data.technique_mastery["bank_shot"].count == 0, "Should not increment count")
    end,
    ["mentor status unlock"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        -- Complete 3 techniques (not enough for mentor)
        data.technique_mastery["bank_shot"].completed = true
        data.technique_mastery["gravity_slingshot"].completed = true
        data.technique_mastery["precision_landing"].completed = true
        data.technique_mastery["combo_master"].count = 24
        -- Complete 4th technique to unlock mentor status
        local result = MasterySystem.trackTechnique("combo_master", {combo_length = 25})
        TestFramework.assert(result.mentor_status == true, "Should unlock mentor status")
        TestFramework.assert(data.mentor_status == true, "Should set mentor status")
        TestFramework.assert(data.total_mastery_points == 40, "Should award mentor bonus (15 + 25)")
    end,
    ["mentor status - already unlocked"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        data.mentor_status = true
        data.total_mastery_points = 100
        -- Complete 4 techniques
        data.technique_mastery["bank_shot"].completed = true
        data.technique_mastery["gravity_slingshot"].completed = true
        data.technique_mastery["precision_landing"].completed = true
        data.technique_mastery["combo_master"].completed = true
        data.technique_mastery["speed_demon"].count = 99
        -- Complete 5th technique
        local result = MasterySystem.trackTechnique("speed_demon", {jump_speed = 850})
        TestFramework.assert(data.total_mastery_points == 115, "Should only award technique points, not mentor bonus again")
    end,
    ["technique tracking - unknown technique"] = function()
        setupSystem()
        MasterySystem.init()
        local result = MasterySystem.trackTechnique("unknown_technique", {some_data = true})
        TestFramework.assert(result == nil, "Should handle unknown technique gracefully")
        local data = MasterySystem.getData()
        TestFramework.assert(data.total_mastery_points == 0, "Should not award points for unknown technique")
    end,
    ["planet bonus calculation"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        -- Level 0 bonuses
        local bonuses = MasterySystem.getPlanetBonus("normal")
        TestFramework.assert(bonuses.point_multiplier == 1.0, "Should have 1.0x multiplier at level 0")
        TestFramework.assert(bonuses.landing_zone_bonus == 1.0, "Should have no landing zone bonus at level 0")
        TestFramework.assert(bonuses.ring_spawn_bonus == 1.0, "Should have no ring spawn bonus at level 0")
        TestFramework.assert(bonuses.has_aura == false, "Should not have aura at level 0")
        TestFramework.assert(bonuses.has_master_skin == false, "Should not have master skin at level 0")
        -- Level 3 bonuses
        data.planet_mastery["ice"].current_level = 3
        bonuses = MasterySystem.getPlanetBonus("ice")
        TestFramework.assert(bonuses.point_multiplier == 1.15, "Should have 1.15x multiplier at level 3")
        TestFramework.assert(bonuses.landing_zone_bonus == 1.1, "Should have landing zone bonus at level 3")
        TestFramework.assert(bonuses.ring_spawn_bonus == 1.0, "Should not have ring spawn bonus at level 3")
        TestFramework.assert(bonuses.has_aura == true, "Should have aura at level 3")
        TestFramework.assert(bonuses.has_master_skin == false, "Should not have master skin at level 3")
        -- Level 5 bonuses (max)
        data.planet_mastery["fire"].current_level = 5
        bonuses = MasterySystem.getPlanetBonus("fire")
        TestFramework.assert(bonuses.point_multiplier == 1.25, "Should have 1.25x multiplier at level 5")
        TestFramework.assert(bonuses.landing_zone_bonus == 1.1, "Should have landing zone bonus at level 5")
        TestFramework.assert(bonuses.ring_spawn_bonus == 1.15, "Should have ring spawn bonus at level 5")
        TestFramework.assert(bonuses.has_aura == true, "Should have aura at level 5")
        TestFramework.assert(bonuses.has_master_skin == true, "Should have master skin at level 5")
    end,
    ["planet bonus - unknown planet"] = function()
        setupSystem()
        MasterySystem.init()
        local bonuses = MasterySystem.getPlanetBonus("unknown")
        TestFramework.assert(type(bonuses) == "table", "Should return empty bonuses table")
        TestFramework.assert(next(bonuses) == nil, "Should be empty table")
    end,
    ["planet visual effect"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        -- No effect at low level
        local effect = MasterySystem.getPlanetVisualEffect("normal")
        TestFramework.assert(effect == nil, "Should have no effect at level 0")
        data.planet_mastery["normal"].current_level = 2
        effect = MasterySystem.getPlanetVisualEffect("normal")
        TestFramework.assert(effect == nil, "Should have no effect at level 2")
        -- Effect at level 3
        data.planet_mastery["ice"].current_level = 3
        effect = MasterySystem.getPlanetVisualEffect("ice")
        TestFramework.assert(effect ~= nil, "Should have effect at level 3")
        TestFramework.assert(effect.has_aura == true, "Should have aura")
        TestFramework.assert(type(effect.aura_color) == "table", "Should have aura color")
        TestFramework.assert(effect.aura_size == 1.3, "Should have correct aura size")
        TestFramework.assert(effect.particle_effect == false, "Should not have particles at level 3")
        TestFramework.assert(effect.master_skin == false, "Should not have master skin at level 3")
        -- Enhanced effect at level 5
        data.planet_mastery["fire"].current_level = 5
        effect = MasterySystem.getPlanetVisualEffect("fire")
        TestFramework.assert(effect.aura_size == 1.5, "Should have larger aura at level 5")
        TestFramework.assert(effect.particle_effect == true, "Should have particles at level 5")
        TestFramework.assert(effect.master_skin == true, "Should have master skin at level 5")
    end,
    ["data access"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        TestFramework.assert(type(data) == "table", "Should return mastery data")
        TestFramework.assert(type(data.planet_mastery) == "table", "Should include planet mastery")
        TestFramework.assert(type(data.technique_mastery) == "table", "Should include technique mastery")
        TestFramework.assert(type(data.total_mastery_points) == "number", "Should include total points")
        TestFramework.assert(type(data.mentor_status) == "boolean", "Should include mentor status")
    end,
    ["mastery point accumulation"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        -- Level up planets
        data.planet_mastery["normal"].perfect_landings = 10
        MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50) -- +2 points
        data.planet_mastery["ice"].perfect_landings = 50
        MasterySystem.trackPlanetLanding("ice", true, {x = 100, y = 100}, {x = 100, y = 100}, 50) -- +3 points
        TestFramework.assert(data.total_mastery_points == 5, "Should accumulate planet mastery points")
        -- Complete technique
        data.technique_mastery["bank_shot"].count = 100
        MasterySystem.trackTechnique("bank_shot", {curved_path = true}) -- +15 points
        TestFramework.assert(data.total_mastery_points == 20, "Should accumulate technique mastery points")
    end,
    ["comprehensive mastery progression"] = function()
        setupSystem()
        MasterySystem.init()
        local data = MasterySystem.getData()
        -- Master multiple planet types
        for level = 1, 5 do
            data.planet_mastery["normal"].perfect_landings = 10 * (10^(level-1)) -- 10, 100, 1000, etc
            if level == 1 then data.planet_mastery["normal"].perfect_landings = 10 end
            if level == 2 then data.planet_mastery["normal"].perfect_landings = 50 end
            if level == 3 then data.planet_mastery["normal"].perfect_landings = 100 end
            if level == 4 then data.planet_mastery["normal"].perfect_landings = 250 end
            if level == 5 then data.planet_mastery["normal"].perfect_landings = 500 end
            MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        end
        -- Should have mastered normal planet (2+3+5+7+10 = 27 points)
        TestFramework.assert(data.planet_mastery["normal"].current_level == 5, "Should master normal planet")
        TestFramework.assert(data.total_mastery_points == 27, "Should have correct mastery points from planet")
        -- Complete all techniques
        local techniques = {"bank_shot", "gravity_slingshot", "precision_landing", "combo_master", "speed_demon", "ring_sniper"}
        for _, technique in ipairs(techniques) do
            data.technique_mastery[technique].count = 999 -- Set high count
            if technique == "bank_shot" then
                MasterySystem.trackTechnique(technique, {curved_path = true})
            elseif technique == "gravity_slingshot" then
                MasterySystem.trackTechnique(technique, {speed_boost = 2.0})
            elseif technique == "precision_landing" then
                MasterySystem.trackTechnique(technique, {bullseye = true})
            elseif technique == "combo_master" then
                MasterySystem.trackTechnique(technique, {combo_length = 30})
            elseif technique == "speed_demon" then
                MasterySystem.trackTechnique(technique, {jump_speed = 900})
            elseif technique == "ring_sniper" then
                MasterySystem.trackTechnique(technique, {perfect_collection = true})
            end
        end
        -- Should have mentor status and all technique points (27 + 6*15 + 25 = 142 points)
        TestFramework.assert(data.mentor_status == true, "Should have mentor status")
        TestFramework.assert(data.total_mastery_points == 142, "Should have maximum mastery points")
        -- Verify all techniques completed
        for _, technique in ipairs(techniques) do
            TestFramework.assert(data.technique_mastery[technique].completed == true, "Should complete " .. technique)
        end
    end
}
-- Run tests
local function run()
    return TestFramework.runTests(tests, "Mastery System Tests")
end
return {run = run}