-- Mastery System for deep progression tracking
local MasterySystem = {}
local mastery = {
    planet_mastery = {}, -- Track per planet type
    technique_mastery = {}, -- Track advanced techniques
    total_mastery_points = 0,
    unlocked_bonuses = {},
    mentor_status = false
}
-- Planet types and their mastery requirements
local PLANET_TYPES = {
    {id = "normal", name = "Terra", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "ice", name = "Cryo", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "fire", name = "Inferno", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "bouncy", name = "Elastic", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "gravity", name = "Graviton", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "tiny", name = "Micro", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "giant", name = "Titan", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "ring_rich", name = "Aureate", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "void", name = "Null", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "storm", name = "Tempest", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "crystal", name = "Prismatic", mastery_levels = {10, 50, 100, 250, 500}},
    {id = "magnetic", name = "Flux", mastery_levels = {10, 50, 100, 250, 500}}
}
-- Advanced techniques to master
local TECHNIQUES = {
    {
        id = "bank_shot",
        name = "Bank Shot Master",
        description = "Use gravity to curve around planets",
        requirements = {count = 100, perfect = true},
        tracking_metric = "successful_bank_shots"
    },
    {
        id = "gravity_slingshot",
        name = "Gravity Assist Expert",
        description = "Use planet gravity to boost speed",
        requirements = {count = 50, speed_boost = 1.5},
        tracking_metric = "gravity_assists"
    },
    {
        id = "precision_landing",
        name = "Bullseye Champion",
        description = "Land in exact planet center",
        requirements = {count = 500, tolerance = 5}, -- 5 pixel tolerance
        tracking_metric = "bullseye_landings"
    },
    {
        id = "combo_master",
        name = "Combo Virtuoso",
        description = "Maintain long ring collection combos",
        requirements = {count = 25, min_combo = 20},
        tracking_metric = "high_combos"
    },
    {
        id = "speed_demon",
        name = "Velocity Master",
        description = "Complete jumps at maximum speed",
        requirements = {count = 100, min_speed = 800},
        tracking_metric = "speed_jumps"
    },
    {
        id = "ring_sniper",
        name = "Ring Hunter",
        description = "Collect all rings in a jump sequence",
        requirements = {count = 50, perfect_collection = true},
        tracking_metric = "perfect_ring_runs"
    }
}
-- Mastery bonuses per level
local MASTERY_BONUSES = {
    planet = {
        [1] = {points = 2, bonus = "5% more points on this planet type"},
        [2] = {points = 3, bonus = "10% larger perfect landing zone"},
        [3] = {points = 5, bonus = "Visual aura when landing"},
        [4] = {points = 7, bonus = "15% more rings spawn on this type"},
        [5] = {points = 10, bonus = "Master skin for this planet type"}
    },
    technique = {
        achievement = {points = 15, bonus = "Technique tutorial unlocked"},
        mentor = {points = 25, bonus = "Mentor status and special badge"}
    }
}
function MasterySystem.init()
    -- Initialize planet mastery tracking
    for _, planet in ipairs(PLANET_TYPES) do
        mastery.planet_mastery[planet.id] = {
            perfect_landings = 0,
            current_level = 0,
            total_landings = 0,
            bonuses_unlocked = {}
        }
    end
    -- Initialize technique mastery tracking
    for _, technique in ipairs(TECHNIQUES) do
        mastery.technique_mastery[technique.id] = {
            count = 0,
            completed = false,
            tutorial_unlocked = false,
            stats = {}
        }
    end
    -- Load saved data
    MasterySystem.loadData()
end
function MasterySystem.trackPlanetLanding(planet_type, is_perfect, landing_position, planet_center, planet_radius)
    local planet_data = mastery.planet_mastery[planet_type]
    if not planet_data then return end
    planet_data.total_landings = planet_data.total_landings + 1
    if is_perfect then
        planet_data.perfect_landings = planet_data.perfect_landings + 1
        -- Check for level up
        local planet_info = nil
        for _, p in ipairs(PLANET_TYPES) do
            if p.id == planet_type then
                planet_info = p
                break
            end
        end
        if planet_info then
            for level, requirement in ipairs(planet_info.mastery_levels) do
                if planet_data.current_level < level and planet_data.perfect_landings >= requirement then
                    planet_data.current_level = level
                    -- Unlock bonus
                    local bonus = MASTERY_BONUSES.planet[level]
                    table.insert(planet_data.bonuses_unlocked, bonus)
                    mastery.total_mastery_points = mastery.total_mastery_points + bonus.points
                    -- Return level up info for UI notification
                    return {
                        type = "planet_mastery",
                        planet = planet_info.name,
                        level = level,
                        bonus = bonus.bonus,
                        points = bonus.points
                    }
                end
            end
        end
    end
    -- Track precision for bullseye technique
    local distance = math.sqrt((landing_position.x - planet_center.x)^2 + (landing_position.y - planet_center.y)^2)
    if distance <= 5 then -- Within 5 pixels of center
        MasterySystem.trackTechnique("precision_landing", {bullseye = true})
    end
end
function MasterySystem.trackTechnique(technique_id, data)
    local technique_data = mastery.technique_mastery[technique_id]
    if not technique_data or technique_data.completed then return end
    local technique_info = nil
    for _, t in ipairs(TECHNIQUES) do
        if t.id == technique_id then
            technique_info = t
            break
        end
    end
    if not technique_info then return end
    -- Update tracking based on technique type
    local valid = false
    if technique_id == "bank_shot" and data.curved_path then
        technique_data.count = technique_data.count + 1
        valid = true
    elseif technique_id == "gravity_slingshot" and data.speed_boost and data.speed_boost >= 1.5 then
        technique_data.count = technique_data.count + 1
        valid = true
    elseif technique_id == "precision_landing" and data.bullseye then
        technique_data.count = technique_data.count + 1
        valid = true
    elseif technique_id == "combo_master" and data.combo_length and data.combo_length >= 20 then
        technique_data.count = technique_data.count + 1
        valid = true
    elseif technique_id == "speed_demon" and data.jump_speed and data.jump_speed >= 800 then
        technique_data.count = technique_data.count + 1
        valid = true
    elseif technique_id == "ring_sniper" and data.perfect_collection then
        technique_data.count = technique_data.count + 1
        valid = true
    end
    -- Check for completion
    if valid and technique_data.count >= technique_info.requirements.count then
        technique_data.completed = true
        technique_data.tutorial_unlocked = true
        -- Award mastery points
        local bonus = MASTERY_BONUSES.technique.achievement
        mastery.total_mastery_points = mastery.total_mastery_points + bonus.points
        -- Check for mentor status
        local completed_count = 0
        for _, t_data in pairs(mastery.technique_mastery) do
            if t_data.completed then
                completed_count = completed_count + 1
            end
        end
        if completed_count >= 4 and not mastery.mentor_status then
            mastery.mentor_status = true
            mastery.total_mastery_points = mastery.total_mastery_points + MASTERY_BONUSES.technique.mentor.points
        end
        return {
            type = "technique_mastery",
            technique = technique_info.name,
            description = technique_info.description,
            points = bonus.points,
            mentor_status = mastery.mentor_status
        }
    end
end
function MasterySystem.getPlanetBonus(planet_type)
    local planet_data = mastery.planet_mastery[planet_type]
    if not planet_data then return {} end
    local bonuses = {
        point_multiplier = 1 + (planet_data.current_level * 0.05),
        landing_zone_bonus = 1 + (planet_data.current_level >= 2 and 0.1 or 0),
        ring_spawn_bonus = 1 + (planet_data.current_level >= 4 and 0.15 or 0),
        has_aura = planet_data.current_level >= 3,
        has_master_skin = planet_data.current_level >= 5
    }
    return bonuses
end
function MasterySystem.draw()
    -- Draw mastery HUD
    love.graphics.setColor(0.8, 0.8, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    -- Total mastery points
    love.graphics.print("Mastery: " .. mastery.total_mastery_points .. " pts", 10, love.graphics.getHeight() - 30)
    -- Mentor badge
    if mastery.mentor_status then
        love.graphics.setColor(1, 0.8, 0, 1)
        love.graphics.print("◆ MENTOR", 10, love.graphics.getHeight() - 50)
    end
end
function MasterySystem.drawMasteryMenu()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    -- Title
    love.graphics.setColor(0.8, 0.8, 1, 1)
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.printf("MASTERY PROGRESS", 0, 30, love.graphics.getWidth(), "center")
    -- Tabs
    local tab_width = 200
    local tab_x = love.graphics.getWidth() / 2 - tab_width
    -- Planet Mastery Tab
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    love.graphics.rectangle("fill", tab_x, 80, tab_width, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Planets", tab_x, 90, tab_width, "center")
    -- Technique Mastery Tab
    love.graphics.setColor(0.5, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", tab_x + tab_width, 80, tab_width, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Techniques", tab_x + tab_width, 90, tab_width, "center")
    -- Content area - Planet Mastery
    local y = 140
    love.graphics.setFont(love.graphics.newFont(16))
    local mastered_count = 0
    for _, planet in ipairs(PLANET_TYPES) do
        local planet_data = mastery.planet_mastery[planet.id]
        if planet_data.current_level >= 5 then
            mastered_count = mastered_count + 1
        end
        -- Planet name and progress
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(planet.name, 100, y)
        -- Progress bar
        local bar_width = 300
        local bar_x = 250
        love.graphics.setColor(0.2, 0.2, 0.3, 1)
        love.graphics.rectangle("fill", bar_x, y, bar_width, 20)
        -- Fill based on progress
        local next_level = planet_data.current_level + 1
        if next_level <= #planet.mastery_levels then
            local current = planet_data.perfect_landings
            local required = planet.mastery_levels[next_level]
            local prev_required = planet_data.current_level > 0 and planet.mastery_levels[planet_data.current_level] or 0
            local progress = (current - prev_required) / (required - prev_required)
            love.graphics.setColor(0.5, 0.8, 1, 1)
            love.graphics.rectangle("fill", bar_x, y, bar_width * progress, 20)
            -- Progress text
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(current .. "/" .. required, bar_x, y + 2, bar_width, "center")
        else
            -- Mastered
            love.graphics.setColor(1, 0.8, 0, 1)
            love.graphics.rectangle("fill", bar_x, y, bar_width, 20)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.printf("MASTERED", bar_x, y + 2, bar_width, "center")
        end
        -- Level stars
        love.graphics.setColor(1, 0.8, 0, 1)
        for i = 1, planet_data.current_level do
            love.graphics.print("★", 560 + (i * 20), y)
        end
        y = y + 30
    end
    -- Master status
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Master of " .. mastered_count .. "/" .. #PLANET_TYPES .. " Planet Types",
        0, love.graphics.getHeight() - 60, love.graphics.getWidth(), "center")
end
function MasterySystem.drawTechniqueMenu()
    -- Similar to planet menu but for techniques
    local y = 140
    love.graphics.setFont(love.graphics.newFont(16))
    for _, technique in ipairs(TECHNIQUES) do
        local technique_data = mastery.technique_mastery[technique.id]
        -- Technique name
        if technique_data.completed then
            love.graphics.setColor(1, 0.8, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.print(technique.name, 100, y)
        -- Description
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(technique.description, 100, y + 20)
        -- Progress
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(technique_data.count .. "/" .. technique.requirements.count, 500, y + 10)
        -- Completed indicator
        if technique_data.completed then
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.print("✓", 600, y + 10)
        end
        y = y + 50
    end
end
function MasterySystem.getPlanetVisualEffect(planet_type)
    local planet_data = mastery.planet_mastery[planet_type]
    if not planet_data or planet_data.current_level < 3 then
        return nil
    end
    -- Return visual effect based on mastery level
    return {
        has_aura = true,
        aura_color = {0.8, 0.8, 1, 0.5},
        aura_size = 1 + (planet_data.current_level * 0.1),
        particle_effect = planet_data.current_level >= 4,
        master_skin = planet_data.current_level >= 5
    }
end
function MasterySystem.saveData()
    local save_data = {
        mastery = mastery
    }
    love.filesystem.write("mastery_save.lua", TSerial.pack(save_data))
end
function MasterySystem.loadData()
    if love.filesystem.getInfo("mastery_save.lua") then
        local contents = love.filesystem.read("mastery_save.lua")
        local save_data = TSerial.unpack(contents)
        if save_data and save_data.mastery then
            mastery = save_data.mastery
        end
    end
end
function MasterySystem.getData()
    return mastery
end
return MasterySystem