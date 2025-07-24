-- Planet Lore System for Orbit Jump
-- Collectible logs and story fragments scattered across planets

local Utils = require("src.utils.utils")
local PlanetLore = {}

-- Lore entries for different planet types
PlanetLore.entries = {
    ice = {
        {
            id = "ice_1",
            title = "Frozen Memories",
            text = "These ice planets weren't always frozen. Long ago, they teemed with warm oceans and lush forests. Something changed the universe...",
            discovered = false
        },
        {
            id = "ice_2", 
            title = "Crystal Cores",
            text = "Deep within each ice planet lies a crystal core, still pulsing with ancient energy. The rings seem drawn to these cores.",
            discovered = false
        },
        {
            id = "ice_3",
            title = "The Great Freeze",
            text = "Log Entry 2847: The freeze is spreading faster than predicted. We've evacuated to the inner systems, but for how long?",
            discovered = false
        }
    },
    
    lava = {
        {
            id = "lava_1",
            title = "Forge Worlds",
            text = "These molten planets were once the forges of an ancient civilization. They shaped reality itself in these volcanic furnaces.",
            discovered = false
        },
        {
            id = "lava_2",
            title = "Eruption Patterns",
            text = "The eruptions follow a pattern - not random, but purposeful. As if the planet itself is trying to communicate.",
            discovered = false
        },
        {
            id = "lava_3",
            title = "Heat Death",
            text = "Warning: These planets burn too hot, too fast. Their cores will exhaust within cycles. Harvest the rings while you can.",
            discovered = false
        }
    },
    
    tech = {
        {
            id = "tech_1",
            title = "Machine Worlds",
            text = "Not planets at all, but massive constructs. Built by whom? For what purpose? The gravity pulses feel almost... intentional.",
            discovered = false
        },
        {
            id = "tech_2",
            title = "Signal Source",
            text = "Detected: Repeating signal from tech planet cores. Pattern suggests intelligence. Attempting to decode...",
            discovered = false
        },
        {
            id = "tech_3",
            title = "The Builders",
            text = "They called themselves the Architects. These tech planets were their laboratories, testing grounds for bending spacetime.",
            discovered = false
        }
    },
    
    void = {
        {
            id = "void_1",
            title = "Anti-Worlds",
            text = "Void planets shouldn't exist. They violate every law of physics we know. Yet here they are, pushing instead of pulling.",
            discovered = false
        },
        {
            id = "void_2",
            title = "The Hunger",
            text = "Stay away from the void planets. They're not empty - they're HUNGRY. They've already consumed three systems.",
            discovered = false
        },
        {
            id = "void_3",
            title = "Inverse Reality",
            text = "Final log: The void planets are tears in reality itself. On the other side? Another universe, reaching through...",
            discovered = false
        }
    },
    
    standard = {
        {
            id = "standard_1",
            title = "Origin Worlds",
            text = "These common planets were the first, the template from which all others were born. Simple, stable, safe.",
            discovered = false
        },
        {
            id = "standard_2",
            title = "Ring Origins",
            text = "The rings first appeared around standard planets. We thought they were debris. We were wrong. They're seeds.",
            discovered = false
        }
    }
}

-- Special lore unlocked by achievements
PlanetLore.specialEntries = {
    {
        id = "special_1",
        title = "The Ring Bearers",
        text = "You are not the first to collect the rings. Others came before, drawn by the same inexplicable pull. Where are they now?",
        requirement = "ring_collector",
        discovered = false
    },
    {
        id = "special_2",
        title = "The Void Walker",
        text = "You've traveled further than any before you. At the edge of everything, you can hear it - the heartbeat of the universe.",
        requirement = "void_walker",
        discovered = false
    },
    {
        id = "special_3",
        title = "The Truth",
        text = "The planets, the rings, your journey - all part of a vast engine. You're not collecting rings. You're powering something...",
        requirement = "space_explorer",
        discovered = false
    }
}

-- Currently displayed lore
PlanetLore.currentDisplay = nil
PlanetLore.displayTimer = 0
PlanetLore.fadeIn = 0

-- Discover a random lore entry for a planet type
function PlanetLore.discoverRandomLore(planetType)
    local entries = PlanetLore.entries[planetType]
    if not entries then return nil end
    
    -- Find undiscovered entries
    local undiscovered = {}
    for _, entry in ipairs(entries) do
        if not entry.discovered then
            table.insert(undiscovered, entry)
        end
    end
    
    if #undiscovered == 0 then return nil end
    
    -- Pick a random undiscovered entry
    local entry = undiscovered[math.random(#undiscovered)]
    entry.discovered = true
    
    -- Display it
    PlanetLore.display(entry)
    
    return entry
end

-- Check and unlock special entries
function PlanetLore.checkSpecialEntries()
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    
    for _, entry in ipairs(PlanetLore.specialEntries) do
        if not entry.discovered and AchievementSystem.achievements[entry.requirement] then
            if AchievementSystem.achievements[entry.requirement].unlocked then
                entry.discovered = true
                PlanetLore.display(entry)
                return entry
            end
        end
    end
    
    return nil
end

-- Display a lore entry
function PlanetLore.display(entry)
    PlanetLore.currentDisplay = entry
    PlanetLore.displayTimer = 8.0 -- Show for 8 seconds
    PlanetLore.fadeIn = 0
    
    -- Play discovery sound
    local soundManager = Utils.require("src.audio.sound_manager")
    if soundManager and soundManager.playLoreDiscovered then
        soundManager:playLoreDiscovered()
    end
end

-- Update the display
function PlanetLore.update(dt)
    if PlanetLore.currentDisplay then
        -- Fade in
        if PlanetLore.fadeIn < 1 then
            PlanetLore.fadeIn = math.min(1, PlanetLore.fadeIn + dt * 2)
        end
        
        -- Update timer
        PlanetLore.displayTimer = PlanetLore.displayTimer - dt
        
        -- Fade out
        if PlanetLore.displayTimer < 1 then
            PlanetLore.fadeIn = PlanetLore.displayTimer
        end
        
        -- Remove when done
        if PlanetLore.displayTimer <= 0 then
            PlanetLore.currentDisplay = nil
        end
    end
end

-- Draw the lore display
function PlanetLore.draw()
    if not PlanetLore.currentDisplay then return end
    
    local entry = PlanetLore.currentDisplay
    local alpha = PlanetLore.fadeIn
    
    local width = 600
    local height = 200
    local x = (love.graphics.getWidth() - width) / 2
    local y = love.graphics.getHeight() - height - 50
    
    -- Background
    love.graphics.setColor(0, 0, 0, alpha * 0.9)
    love.graphics.rectangle("fill", x, y, width, height, 10)
    
    -- Border
    love.graphics.setColor(0.5, 0.3, 0.8, alpha * 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 10)
    
    -- Icon
    love.graphics.setColor(0.7, 0.5, 1, alpha)
    love.graphics.circle("fill", x + 50, y + 50, 30)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("📜", x + 35, y + 35)
    
    -- Title
    love.graphics.setColor(1, 0.9, 0.5, alpha)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.print("LORE DISCOVERED", x + 100, y + 20)
    
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(entry.title, x + 100, y + 45)
    
    -- Text (word wrap)
    love.graphics.setColor(0.8, 0.8, 0.8, alpha)
    love.graphics.printf(entry.text, x + 30, y + 80, width - 60, "left")
    
    -- Progress hint
    love.graphics.setColor(0.5, 0.5, 0.5, alpha * 0.7)
    love.graphics.print("More lore awaits on distant worlds...", x + 30, y + height - 30)
end

-- Get completion stats
function PlanetLore.getStats()
    local total = 0
    local discovered = 0
    
    -- Count regular entries
    for planetType, entries in pairs(PlanetLore.entries) do
        for _, entry in ipairs(entries) do
            total = total + 1
            if entry.discovered then
                discovered = discovered + 1
            end
        end
    end
    
    -- Count special entries
    for _, entry in ipairs(PlanetLore.specialEntries) do
        total = total + 1
        if entry.discovered then
            discovered = discovered + 1
        end
    end
    
    return {
        total = total,
        discovered = discovered,
        percentage = (discovered / total) * 100
    }
end

-- Save/Load
function PlanetLore.getSaveData()
    local saveData = {
        entries = {},
        specialEntries = {}
    }
    
    -- Save regular entries
    for planetType, entries in pairs(PlanetLore.entries) do
        saveData.entries[planetType] = {}
        for _, entry in ipairs(entries) do
            saveData.entries[planetType][entry.id] = entry.discovered
        end
    end
    
    -- Save special entries
    for _, entry in ipairs(PlanetLore.specialEntries) do
        saveData.specialEntries[entry.id] = entry.discovered
    end
    
    return saveData
end

function PlanetLore.loadSaveData(data)
    if not data then return end
    
    -- Load regular entries
    if data.entries then
        for planetType, entries in pairs(data.entries) do
            if PlanetLore.entries[planetType] then
                for _, entry in ipairs(PlanetLore.entries[planetType]) do
                    if data.entries[planetType][entry.id] ~= nil then
                        entry.discovered = data.entries[planetType][entry.id]
                    end
                end
            end
        end
    end
    
    -- Load special entries
    if data.specialEntries then
        for _, entry in ipairs(PlanetLore.specialEntries) do
            if data.specialEntries[entry.id] ~= nil then
                entry.discovered = data.specialEntries[entry.id]
            end
        end
    end
end

return PlanetLore