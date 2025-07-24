-- Mock system for Orbit Jump tests
-- Provides mock implementations of LÖVE2D and other external dependencies

local Mocks = {}

-- Track function calls for testing
local callTracker = {}

-- Mock LÖVE2D framework
Mocks.love = {
    graphics = {
        getDimensions = function() return 800, 600 end,
        getWidth = function() return 800 end,
        getHeight = function() return 600 end,
        setColor = function(r, g, b, a)
            callTracker.setColor = callTracker.setColor or 0
            callTracker.setColor = callTracker.setColor + 1
        end,
        circle = function(mode, x, y, radius)
            callTracker.circle = callTracker.circle or 0
            callTracker.circle = callTracker.circle + 1
        end,
        rectangle = function(mode, x, y, width, height)
            callTracker.rectangle = callTracker.rectangle or 0
            callTracker.rectangle = callTracker.rectangle + 1
        end,
        line = function(...)
            callTracker.line = callTracker.line or 0
            callTracker.line = callTracker.line + 1
        end,
        arc = function(mode, x, y, radius, startAngle, endAngle)
            callTracker.arc = callTracker.arc or 0
            callTracker.arc = callTracker.arc + 1
        end,
        print = function(text, x, y)
            callTracker.print = callTracker.print or 0
            callTracker.print = callTracker.print + 1
        end,
        printf = function(text, x, y, limit, align)
            callTracker.printf = callTracker.printf or 0
            callTracker.printf = callTracker.printf + 1
        end,
        setFont = function(font)
            callTracker.setFont = callTracker.setFont or 0
            callTracker.setFont = callTracker.setFont + 1
        end,
        getFont = function() 
            return {
                getWidth = function(text) return string.len(text) * 8 end,
                getHeight = function() return 16 end
            }
        end,
        newFont = function(path, size) 
            callTracker.newFont = callTracker.newFont or 0
            callTracker.newFont = callTracker.newFont + 1
            return {
                getWidth = function(text) return string.len(text) * 8 end,
                getHeight = function() return size or 16 end
            }
        end,
        setLineWidth = function(width)
            callTracker.setLineWidth = callTracker.setLineWidth or 0
            callTracker.setLineWidth = callTracker.setLineWidth + 1
        end,
        setBackgroundColor = function(r, g, b, a)
            callTracker.setBackgroundColor = callTracker.setBackgroundColor or 0
            callTracker.setBackgroundColor = callTracker.setBackgroundColor + 1
        end,
        push = function()
            callTracker.push = callTracker.push or 0
            callTracker.push = callTracker.push + 1
        end,
        pop = function()
            callTracker.pop = callTracker.pop or 0
            callTracker.pop = callTracker.pop + 1
        end,
        translate = function(x, y)
            callTracker.translate = callTracker.translate or 0
            callTracker.translate = callTracker.translate + 1
        end,
        scale = function(sx, sy)
            callTracker.scale = callTracker.scale or 0
            callTracker.scale = callTracker.scale + 1
        end,
        rotate = function(angle)
            callTracker.rotate = callTracker.rotate or 0
            callTracker.rotate = callTracker.rotate + 1
        end,
        setScissor = function(x, y, width, height)
            callTracker.setScissor = callTracker.setScissor or 0
            callTracker.setScissor = callTracker.setScissor + 1
        end,
        captureScreenshot = function(callback)
            -- Mock screenshot data
            local mockData = {
                encode = function() return true end
            }
            callback(mockData)
            return true
        end
    },
    
    event = {
        quit = function(restart)
            callTracker.quit = callTracker.quit or 0
            callTracker.quit = callTracker.quit + 1
        end
    },
    
    timer = {
        getTime = function() return 0 end,
        getDelta = function() return 1/60 end
    },
    
    mouse = {
        getPosition = function() return 400, 300 end,
        isDown = function(button) return false end,
        position = {x = 400, y = 300}
    },
    
    keyboard = {
        isDown = function(key) return false end
    },
    
    filesystem = {
        write = function(filename, data)
            callTracker.filesystemWrite = callTracker.filesystemWrite or 0
            callTracker.filesystemWrite = callTracker.filesystemWrite + 1
            return true, nil
        end,
        read = function(filename)
            callTracker.filesystemRead = callTracker.filesystemRead or 0
            callTracker.filesystemRead = callTracker.filesystemRead + 1
            return "mock data", nil
        end,
        load = function(filename) 
            callTracker.filesystemLoad = callTracker.filesystemLoad or 0
            callTracker.filesystemLoad = callTracker.filesystemLoad + 1
            return function() return {} end
        end,
        exists = function(filename) 
            callTracker.filesystemExists = callTracker.filesystemExists or 0
            callTracker.filesystemExists = callTracker.filesystemExists + 1
            return true 
        end,
        getInfo = function(filename)
            callTracker.filesystemGetInfo = callTracker.filesystemGetInfo or 0
            callTracker.filesystemGetInfo = callTracker.filesystemGetInfo + 1
            return {size = 1024, type = "file"}
        end,
        createDirectory = function(dirname) 
            callTracker.filesystemCreateDirectory = callTracker.filesystemCreateDirectory or 0
            callTracker.filesystemCreateDirectory = callTracker.filesystemCreateDirectory + 1
            return true 
        end,
        getSaveDirectory = function()
            return "/tmp/orbit_jump_saves"
        end,
        setIdentity = function(identity)
            callTracker.filesystemSetIdentity = callTracker.filesystemSetIdentity or 0
            callTracker.filesystemSetIdentity = callTracker.filesystemSetIdentity + 1
        end,
        remove = function(filename)
            callTracker.filesystemRemove = callTracker.filesystemRemove or 0
            callTracker.filesystemRemove = callTracker.filesystemRemove + 1
            return true
        end
    },
    
    audio = {
        newSource = function(path, type)
            callTracker.audioNewSource = callTracker.audioNewSource or 0
            callTracker.audioNewSource = callTracker.audioNewSource + 1
            return {
                play = function() end,
                stop = function() end,
                setVolume = function(vol) end,
                setPitch = function(pitch) end,
                isPlaying = function() return false end,
                clone = function() 
                    return {
                        play = function() end,
                        stop = function() end,
                        setVolume = function(vol) end,
                        setPitch = function(pitch) end,
                        isPlaying = function() return false end
                    }
                end
            }
        end
    },
    
    window = {
        setFullscreen = function(fullscreen)
            callTracker.setFullscreen = callTracker.setFullscreen or 0
            callTracker.setFullscreen = callTracker.setFullscreen + 1
        end,
        setVSync = function(vsync)
            callTracker.setVSync = callTracker.setVSync or 0
            callTracker.setVSync = callTracker.setVSync + 1
        end
    }
}

-- Mock math functions
Mocks.math = {
    random = function() return 0.5 end,
    sin = math.sin,
    cos = math.cos,
    sqrt = math.sqrt,
    atan2 = math.atan2,
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
    end,
    setColor = function(r, g, b, a)
        callTracker.setColor = callTracker.setColor or 0
        callTracker.setColor = callTracker.setColor + 1
    end,
    formatNumber = function(num)
        if num >= 1000 then
            return string.format("%.1fK", num / 1000)
        end
        return tostring(num)
    end
}

-- Mock os functions
Mocks.os = {
    clock = function() return 0 end,
    date = function() return "2024-01-01 00:00:00" end,
    time = function() return 1704067200 end -- 2024-01-01 00:00:00 UTC
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

-- Mock missing systems
Mocks.CosmicEvents = {
    triggerQuantumTeleport = function(x, y) end
}

Mocks.ring_constellations = {
    getConstellation = function() return "test" end,
    onRingCollected = function(ring, player) end
}

Mocks.SoundManager = {
    playCollectRing = function() end,
    playLand = function() end,
    playJump = function() end,
    playDash = function() end,
    playEventWarning = function() end
}

-- Mock ArtifactSystem
Mocks.ArtifactSystem = {
    artifacts = {
        {
            id = "origin_fragment_1",
            name = "Origin Fragment I",
            description = "The first explorers called it 'The Jump'",
            hint = "Near the center of known space",
            color = {0.8, 0.6, 1},
            discovered = false
        },
        {
            id = "origin_fragment_2",
            name = "Origin Fragment II", 
            description = "They learned to harness momentum",
            hint = "Where ice meets the void",
            color = {0.6, 0.8, 1},
            discovered = false
        }
    },
    spawnedArtifacts = {},
    collectedCount = 0,
    notificationQueue = {},
    pulsePhase = 0,
    particleTimer = 0,
    notificationTimer = 5,
    
    init = function()
        Mocks.ArtifactSystem.collectedCount = 0
        Mocks.ArtifactSystem.spawnedArtifacts = {}
        Mocks.ArtifactSystem.notificationQueue = {}
    end,
    
    spawnArtifacts = function(player, planets) end,
    update = function(dt, player, planets) end,
    collectArtifact = function(artifact, index) end,
    draw = function(camera) end,
    drawOnMap = function(camera, centerX, centerY, scale, alpha) end,
    getArtifactById = function(id) 
        for _, artifact in ipairs(Mocks.ArtifactSystem.artifacts) do
            if artifact.id == id then
                return artifact
            end
        end
        return nil
    end,
    getDiscoveredArtifacts = function()
        local discovered = {}
        for _, artifact in ipairs(Mocks.ArtifactSystem.artifacts) do
            if artifact.discovered then
                table.insert(discovered, artifact)
            end
        end
        return discovered
    end,
    isArtifactSpawned = function(id) return false end
}

-- Mock GameState with proper getPlanets function
Mocks.GameState = {
    getPlanets = function() 
        return {
            {
                x = 400,
                y = 300,
                radius = 80,
                rotationSpeed = 0.5,
                color = {0.8, 0.3, 0.3},
                type = "standard",
                gravityMultiplier = 1.0
            }
        }
    end,
    getRings = function()
        return {
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
        }
    end,
    addScore = function(score) end,
    addCombo = function() end
}

-- Mock RingSystem with collectRing function
Mocks.RingSystem = {
    collectRing = function(ring, player)
        if ring.collected then return 0 end
        ring.collected = true
        return ring.value or 10
    end,
    generateRing = function(x, y, planetType)
        return {
            x = x,
            y = y,
            radius = 25,
            innerRadius = 15,
            rotation = 0,
            rotationSpeed = 1.0,
            pulsePhase = 0,
            collected = false,
            color = {0.3, 0.7, 1, 0.8},
            type = "standard",
            value = 10
        }
    end,
    generateRings = function(planets, count)
        local rings = {}
        count = count or 10
        for i = 1, count do
            table.insert(rings, Mocks.RingSystem.generateRing(100 + i * 50, 100 + i * 50))
        end
        return rings
    end,
    updateRing = function(ring, dt) end,
    applyMagnetEffect = function(player, rings) end,
    reset = function() end,
    types = {
        standard = { value = 10, color = {0.3, 0.7, 1, 0.8} },
        ghost = { value = 20, color = {0.8, 0.8, 0.8, 0.6} },
        warp = { value = 30, color = {0.8, 0.2, 0.8, 0.8} },
        chain = { value = 25, color = {1, 0.8, 0.2, 0.8} }
    }
}

-- Mock ParticleSystem with get method
Mocks.ParticleSystem = {
    particles = {},
    particlePool = nil,
    maxParticles = 1000,
    
    init = function()
        -- Create mock object pool
        Mocks.ParticleSystem.particlePool = {
            objects = {},
            createFunc = function()
                return {
                    x = 0, y = 0,
                    vx = 0, vy = 0,
                    lifetime = 0,
                    maxLifetime = 1,
                    size = 2,
                    color = {1, 1, 1, 1},
                    type = "default"
                }
            end,
            resetFunc = function(particle)
                particle.x = 0
                particle.y = 0
                particle.vx = 0
                particle.vy = 0
                particle.lifetime = 0
                particle.maxLifetime = 1
                particle.size = 2
                particle.color = {1, 1, 1, 1}
                particle.type = "default"
            end,
            get = function(self)
                if #self.objects > 0 then
                    return table.remove(self.objects)
                else
                    return self.createFunc()
                end
            end,
            returnObject = function(self, obj)
                if self.resetFunc then
                    self.resetFunc(obj)
                end
                table.insert(self.objects, obj)
            end
        }
        Mocks.ParticleSystem.particles = {}
    end,
    
    create = function(x, y, vx, vy, color, lifetime, size, type)
        -- Check particle limit
        if #Mocks.ParticleSystem.particles >= Mocks.ParticleSystem.maxParticles then
            local oldest = table.remove(Mocks.ParticleSystem.particles, 1)
            if oldest and Mocks.ParticleSystem.particlePool then
                Mocks.ParticleSystem.particlePool:returnObject(oldest)
            end
        end
        
        -- Get particle from pool or create new
        local particle
        if Mocks.ParticleSystem.particlePool then
            particle = Mocks.ParticleSystem.particlePool:get()
        else
            particle = {}
        end
        
        -- Set particle properties
        particle.x = x
        particle.y = y
        particle.vx = vx or 0
        particle.vy = vy or 0
        particle.lifetime = lifetime or 1
        particle.maxLifetime = lifetime or 1
        particle.size = size or 2
        particle.color = color or {1, 1, 1, 1}
        particle.type = type or "default"
        
        table.insert(Mocks.ParticleSystem.particles, particle)
        return particle
    end,
    
    update = function(dt)
        local gravity = 200
        
        for i = #Mocks.ParticleSystem.particles, 1, -1 do
            local particle = Mocks.ParticleSystem.particles[i]
            
            -- Update position
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            
            -- Apply gravity
            particle.vy = particle.vy + gravity * dt
            
            -- Apply drag
            particle.vx = particle.vx * 0.98
            particle.vy = particle.vy * 0.98
            
            -- Update lifetime
            particle.lifetime = particle.lifetime - dt
            
            -- Remove dead particles
            if particle.lifetime <= 0 then
                table.remove(Mocks.ParticleSystem.particles, i)
                if Mocks.ParticleSystem.particlePool then
                    Mocks.ParticleSystem.particlePool:returnObject(particle)
                end
            end
        end
    end,
    
    getParticles = function()
        return Mocks.ParticleSystem.particles
    end,
    
    get = function()
        return Mocks.ParticleSystem.particles
    end,
    
    clear = function()
        if Mocks.ParticleSystem.particlePool then
            for _, particle in ipairs(Mocks.ParticleSystem.particles) do
                Mocks.ParticleSystem.particlePool:returnObject(particle)
            end
        end
        Mocks.ParticleSystem.particles = {}
    end,
    
    getCount = function()
        return #Mocks.ParticleSystem.particles
    end,
    
    burst = function(x, y, count, color, speed, lifetime)
        count = count or 10
        speed = speed or 200
        lifetime = lifetime or 1
        
        for i = 1, count do
            local angle = (i / count) * math.pi * 2 + math.random() * 0.5
            local vel = speed * (0.5 + math.random() * 0.5)
            local vx = math.cos(angle) * vel
            local vy = math.sin(angle) * vel
            
            Mocks.ParticleSystem.create(
                x + math.random(-5, 5),
                y + math.random(-5, 5),
                vx, vy,
                color,
                lifetime * (0.5 + math.random() * 0.5),
                2 + math.random() * 2
            )
        end
    end,
    
    trail = function(x, y, vx, vy, color, count)
        count = count or 3
        
        for i = 1, count do
            local spread = 20
            local pvx = vx * -0.5 + math.random(-spread, spread)
            local pvy = vy * -0.5 + math.random(-spread, spread)
            
            Mocks.ParticleSystem.create(
                x + math.random(-5, 5),
                y + math.random(-5, 5),
                pvx, pvy,
                color,
                0.3 + math.random() * 0.3,
                1 + math.random() * 2
            )
        end
    end,
    
    sparkle = function(x, y, color)
        local count = 5
        for i = 1, count do
            local angle = math.random() * math.pi * 2
            local speed = 50 + math.random() * 100
            local vx = math.cos(angle) * speed
            local vy = math.sin(angle) * speed
            
            Mocks.ParticleSystem.create(
                x, y,
                vx, vy,
                color or {1, 1, 0.8, 1},
                0.5 + math.random() * 0.5,
                1 + math.random() * 2,
                "sparkle"
            )
        end
    end
}

-- Mock Config module
Mocks.Config = {
    mobile = {
        buttonSize = 60,
        touchSensitivity = 1.0,
        hapticFeedback = true
    },
    game = {
        startingScore = 0,
        maxCombo = 100,
        ringValue = 10,
        jumpPower = 1.0,
        dashPower = 1.0
    },
    sound = {
        enabled = true,
        masterVolume = 1.0,
        musicVolume = 0.8,
        sfxVolume = 0.9
    },
    blockchain = {
        enabled = false,
        network = "ethereum",
        batchInterval = 30,
        gasLimit = 300000
    },
    progression = {
        enabled = true,
        saveInterval = 30,
        maxUpgradeLevel = 10
    }
}

-- Setup mock environment
function Mocks.setup()
    -- Reset call tracker
    callTracker = {}
    
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
    os.time = Mocks.os.time
    io.open = Mocks.io.open
    
    -- Create mock love object if it doesn't exist
    if not love then
        love = Mocks.love
    end
    
    -- Set up global mocks
    _G.CosmicEvents = Mocks.CosmicEvents
    _G.ring_constellations = Mocks.ring_constellations
    _G.SoundManager = Mocks.SoundManager
    _G.Config = Mocks.Config
    _G.ArtifactSystem = Mocks.ArtifactSystem
    _G.GameState = Mocks.GameState
    _G.RingSystem = Mocks.RingSystem
    _G.ParticleSystem = Mocks.ParticleSystem
    
    -- Mock Utils functions
    local Utils = require("src.utils.utils")
    if Utils then
        Utils.distance = Mocks.utils.distance
        Utils.randomFloat = Mocks.utils.randomFloat
        Utils.setColor = Mocks.utils.setColor
        Utils.formatNumber = Mocks.utils.formatNumber
        
        -- Mock ObjectPool for particle system
        if not Utils.ObjectPool then
            Utils.ObjectPool = {}
        end
        
        Utils.ObjectPool.new = function(createFunc, resetFunc)
            local pool = {
                objects = {},
                createFunc = createFunc,
                resetFunc = resetFunc
            }
            
            function pool:get()
                if #self.objects > 0 then
                    return table.remove(self.objects)
                else
                    return self.createFunc()
                end
            end
            
            function pool:returnObject(obj)
                if self.resetFunc then
                    self.resetFunc(obj)
                end
                table.insert(self.objects, obj)
            end
            
            -- Add aliases for backward compatibility
            function pool:acquire()
                return self:get()
            end
            
            function pool:release(obj)
                return self:returnObject(obj)
            end
            
            return pool
        end
        
        -- Mock Logger
        if not Utils.Logger then
            Utils.Logger = {
                info = function(msg, ...) end,
                warn = function(msg, ...) end,
                error = function(msg, ...) end,
                debug = function(msg, ...) end,
                init = function() end,
                levels = {
                    DEBUG = 0,
                    INFO = 1,
                    WARN = 2,
                    ERROR = 3
                }
            }
        end
        
        -- Mock ErrorHandler
        if not Utils.ErrorHandler then
            Utils.ErrorHandler = {
                safeCall = function(func, ...)
                    local success, result = pcall(func, ...)
                    return success, result
                end,
                rawPcall = function(func, ...)
                    return pcall(func, ...)
                end
            }
        end
    end
end

-- Get call count for a function
function Mocks.getCallCount(functionName)
    return callTracker[functionName] or 0
end

-- Reset call tracker
function Mocks.resetCallTracker()
    callTracker = {}
end

-- Reset mock state
function Mocks.reset()
    -- Reset any mock state here
    Mocks.love.timer.getTime = function() return 0 end
    Mocks.love.mouse.getPosition = function() return 400, 300 end
    Mocks.resetCallTracker()
    
    -- Reset particle system
    Mocks.ParticleSystem.init()
    
    -- Reset artifact system
    Mocks.ArtifactSystem.init()
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
        speedBoost = 1.0,
        hasShield = false
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