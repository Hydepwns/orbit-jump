-- Mock system for Orbit Jump tests
-- Provides mock implementations of LÖVE2D and other external dependencies

local Mocks = {}

-- Mock LÖVE2D framework
Mocks.love = {
    graphics = {
        getDimensions = function() return 800, 600 end,
        getWidth = function() return 800 end,
        getHeight = function() return 600 end,
        setColor = function() end,
        circle = function() end,
        rectangle = function() end,
        line = function() end,
        arc = function() end,
        print = function() end,
        printf = function() end,
        setFont = function() end,
        getFont = function() 
            return {
                getWidth = function() return 100 end,
                getHeight = function() return 20 end
            }
        end,
        newFont = function() 
            return {
                getWidth = function() return 100 end,
                getHeight = function() return 20 end
            }
        end,
        setLineWidth = function() end,
        setBackgroundColor = function() end,
        push = function() end,
        pop = function() end,
        translate = function() end,
        scale = function() end,
        rotate = function() end,
        captureScreenshot = function(callback)
            -- Mock screenshot data
            local mockData = {
                encode = function() return true end
            }
            callback(mockData)
            return true
        end
    },
    
    timer = {
        getTime = function() return 0 end,
        getDelta = function() return 1/60 end
    },
    
    mouse = {
        getPosition = function() return 400, 300 end,
        isDown = function() return false end
    },
    
    keyboard = {
        isDown = function() return false end
    },
    
    filesystem = {
        write = function() return true end,
        read = function() return "" end,
        load = function() 
            return function() return {} end
        end,
        exists = function() return true end,
        createDirectory = function() return true end
    },
    
    audio = {
        newSource = function()
            return {
                play = function() end,
                stop = function() end,
                setVolume = function() end,
                setPitch = function() end,
                isPlaying = function() return false end,
                clone = function() 
                    return {
                        play = function() end,
                        stop = function() end,
                        setVolume = function() end,
                        setPitch = function() end,
                        isPlaying = function() return false end
                    }
                end
            }
        end
    }
}

-- Mock math functions
Mocks.math = {
    random = function() return 0.5 end,
    sin = math.sin,
    cos = math.cos,
    sqrt = math.sqrt,
    atan2 = function(y, x) return Utils.atan2(y, x) end, -- Use Utils.atan2 pattern
    floor = math.floor,
    ceil = math.ceil,
    min = math.min,
    max = math.max,
    abs = math.abs,
    pi = math.pi
}

-- Mock Utils functions
Mocks.utils = {
    distance = function(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1
        return math.sqrt(dx*dx + dy*dy), dx, dy
    end,
    randomFloat = function(min, max)
        return min + (max - min) * 0.5
    end
}

-- Mock os functions
Mocks.os = {
    clock = function() return 0 end,
    date = function() return "2024-01-01 00:00:00" end
}

-- Mock io functions
Mocks.io = {
    open = function() 
        return {
            write = function() end,
            read = function() return "" end,
            close = function() end,
            flush = function() end
        }
    end
}

-- Mock table functions
Mocks.table = {
    insert = table.insert,
    remove = table.remove,
    concat = table.concat,
    sort = table.sort,
    getn = function(t) return #t end -- Lua 5.0 compatibility
}

-- Mock string functions
Mocks.string = {
    format = string.format,
    gsub = string.gsub,
    gmatch = string.gmatch,
    sub = string.sub,
    len = string.len,
    rep = string.rep
}

-- Setup mock environment
function Mocks.setup()
    -- Replace global functions with mocks
    love = Mocks.love
    math.random = Mocks.math.random
    math.sin = Mocks.math.sin
    math.cos = Mocks.math.cos
    math.sqrt = Mocks.math.sqrt
    math.atan2 = Mocks.math.atan2
    math.floor = Mocks.math.floor
    math.ceil = Mocks.math.ceil
    math.min = Mocks.math.min
    math.max = Mocks.math.max
    math.abs = Mocks.math.abs
    math.pi = Mocks.math.pi
    table.getn = Mocks.table.getn
    os.clock = Mocks.os.clock
    os.date = Mocks.os.date
    io.open = Mocks.io.open
    
    -- Create mock love object if it doesn't exist
    if not love then
        love = Mocks.love
    end
    
    -- Mock Utils functions
    local Utils = require("src.utils.utils")
    if Utils then
        Utils.distance = Mocks.utils.distance
        Utils.randomFloat = Mocks.utils.randomFloat
        
        -- Mock ObjectPool for particle system
        if Utils.ObjectPool then
            Utils.ObjectPool.new = function(createFunc, maxSize)
                local pool = {
                    objects = {},
                    maxSize = maxSize or 100,
                    createFunc = createFunc
                }
                
                function pool:acquire()
                    if #self.objects > 0 then
                        return table.remove(self.objects)
                    else
                        return self.createFunc()
                    end
                end
                
                function pool:release(obj)
                    if #self.objects < self.maxSize then
                        table.insert(self.objects, obj)
                    end
                end
                
                return pool
            end
        end
    end
end

-- Reset mock state
function Mocks.reset()
    -- Reset any mock state here
    Mocks.love.timer.getTime = function() return 0 end
    Mocks.love.mouse.getPosition = function() return 400, 300 end
end

-- Mock game state for testing
Mocks.gameState = {
    player = {
        x = 400,
        y = 300,
        vx = 0,
        vy = 0,
        radius = 10,
        onPlanet = 1,
        angle = 0,
        jumpPower = 300,
        dashPower = 500,
        isDashing = false,
        dashTimer = 0,
        dashCooldown = 0,
        trail = {},
        speedBoost = 1.0
    },
    
    planets = {
        {
            x = 400,
            y = 300,
            radius = 80,
            rotationSpeed = 0.5,
            color = {0.8, 0.3, 0.3},
            type = "standard",
            gravityMultiplier = 1.0
        }
    },
    
    rings = {
        {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            rotation = 0,
            rotationSpeed = 1.0,
            pulsePhase = 0,
            collected = false,
            color = {0.3, 0.7, 1, 0.8},
            type = "standard"
        }
    },
    
    particles = {},
    score = 0,
    combo = 0,
    comboTimer = 0
}

-- Mock progression data
Mocks.progressionData = {
    totalScore = 1000,
    totalRingsCollected = 50,
    totalJumps = 25,
    totalPlayTime = 300,
    highestCombo = 8,
    gamesPlayed = 5,
    achievements = {
        firstRing = { unlocked = true },
        comboMaster = { unlocked = false }
    },
    upgrades = {
        jumpPower = 2,
        dashPower = 1,
        speedBoost = 1,
        ringValue = 2,
        comboMultiplier = 1,
        gravityResistance = 1
    }
}

-- Mock achievement data
Mocks.achievementData = {
    first_planet = {
        id = "first_planet",
        name = "Baby Steps",
        description = "Discover your first planet",
        icon = "🌍",
        points = 10,
        unlocked = true,
        progress = 1,
        target = 1
    },
    planet_hopper = {
        id = "planet_hopper",
        name = "Planet Hopper", 
        description = "Discover 10 planets",
        icon = "🚀",
        points = 50,
        unlocked = false,
        progress = 3,
        target = 10
    }
}

-- Mock upgrade data
Mocks.upgradeData = {
    jump_power = {
        id = "jump_power",
        name = "Jump Power",
        description = "Increase jump strength",
        icon = "🚀",
        maxLevel = 5,
        currentLevel = 2,
        baseCost = 100,
        costMultiplier = 1.5,
        effect = function(level) return 1 + (level * 0.2) end
    },
    dash_power = {
        id = "dash_power",
        name = "Dash Power",
        description = "Increase dash strength",
        icon = "⚡",
        maxLevel = 5,
        currentLevel = 1,
        baseCost = 150,
        costMultiplier = 1.8,
        effect = function(level) return 1 + (level * 0.3) end
    }
}

-- Helper function to create mock objects
function Mocks.createMock(properties)
    local mock = {}
    for key, value in pairs(properties) do
        mock[key] = value
    end
    return mock
end

-- Helper function to create mock function
function Mocks.createMockFunction(returnValue)
    return function(...)
        return returnValue
    end
end

-- Helper function to create mock function with call tracking
function Mocks.createTrackedMockFunction(returnValue)
    local calls = {}
    local mock = function(...)
        table.insert(calls, {...})
        return returnValue
    end
    mock.getCalls = function() return calls end
    mock.getCallCount = function() return #calls end
    mock.reset = function() calls = {} end
    return mock
end

return Mocks 