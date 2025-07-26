-- MockBuilder utility for consistent mock object creation
-- Provides standardized patterns for creating test mocks

local MockBuilder = {}

-- State tracking for validation
MockBuilder._createdMocks = {}
MockBuilder._mockRegistry = {}

-- Reset all mock state (call between tests)
function MockBuilder.reset()
    MockBuilder._createdMocks = {}
    -- Reset any stateful mocks
    for _, mock in pairs(MockBuilder._mockRegistry) do
        if mock.reset then
            mock.reset()
        end
    end
end

-- Validate that mocks are properly configured
function MockBuilder.validate()
    local issues = {}
    for mockType, mocks in pairs(MockBuilder._createdMocks) do
        for _, mock in ipairs(mocks) do
            if mock._validate then
                local issue = mock._validate()
                if issue then
                    table.insert(issues, string.format("%s: %s", mockType, issue))
                end
            end
        end
    end
    return issues
end

-- Track created mocks for validation
local function trackMock(mockType, mock)
    if not MockBuilder._createdMocks[mockType] then
        MockBuilder._createdMocks[mockType] = {}
    end
    table.insert(MockBuilder._createdMocks[mockType], mock)
    return mock
end

-- Create a standardized player mock
function MockBuilder.createPlayer(options)
    options = options or {}
    local player = {
        x = options.x or 0,
        y = options.y or 0,
        vx = options.vx or 0,
        vy = options.vy or 0,
        radius = options.radius or 10,
        onPlanet = options.onPlanet or false,
        isDashing = options.isDashing or false,
        hasShield = options.hasShield or false,
        dashCooldown = options.dashCooldown or 0,
        trailPositions = options.trailPositions or {},
        jumpPower = options.jumpPower or 300,
        gravityMultiplier = options.gravityMultiplier or 1.0,
        
        -- Validation
        _validate = function()
            if not player.x or not player.y then
                return "Player must have x,y coordinates"
            end
            if player.radius <= 0 then
                return "Player radius must be positive"
            end
            return nil
        end
    }
    
    return trackMock("player", player)
end

-- Create a standardized planet mock
function MockBuilder.createPlanet(options)
    options = options or {}
    local planet = {
        x = options.x or 0,
        y = options.y or 0,
        radius = options.radius or 50,
        rotationSpeed = options.rotationSpeed or 1.0,
        discovered = options.discovered or false,
        type = options.type or "standard",
        color = options.color or {0.7, 0.4, 0.3},
        gravityMultiplier = options.gravityMultiplier or 1.0,
        
        -- Validation
        _validate = function()
            if planet.radius <= 0 then
                return "Planet radius must be positive"
            end
            if not planet.rotationSpeed then
                return "Planet must have rotationSpeed"
            end
            return nil
        end
    }
    
    return trackMock("planet", planet)
end

-- Create a standardized ring mock
function MockBuilder.createRing(options)
    options = options or {}
    local ring = {
        x = options.x or 0,
        y = options.y or 0,
        radius = options.radius or 25,
        innerRadius = options.innerRadius or 15,
        rotation = options.rotation or 0,
        rotationSpeed = options.rotationSpeed or 1.0,
        pulsePhase = options.pulsePhase or 0,
        collected = options.collected or false,
        color = options.color or {0.3, 0.7, 1, 0.8},
        type = options.type or "standard",
        value = options.value or 10,
        
        -- Validation
        _validate = function()
            if ring.radius <= ring.innerRadius then
                return "Ring radius must be greater than innerRadius"
            end
            if ring.value <= 0 then
                return "Ring value must be positive"
            end
            return nil
        end
    }
    
    return trackMock("ring", ring)
end

-- Create a standardized particle mock
function MockBuilder.createParticle(options)
    options = options or {}
    local particle = {
        x = options.x or 0,
        y = options.y or 0,
        vx = options.vx or 0,
        vy = options.vy or 0,
        life = options.life or 1.0,
        maxLife = options.maxLife or 1.0,
        color = options.color or {1, 1, 1, 1},
        size = options.size or 2,
        
        -- Validation
        _validate = function()
            if particle.life < 0 or particle.life > particle.maxLife then
                return "Particle life must be between 0 and maxLife"
            end
            if particle.size <= 0 then
                return "Particle size must be positive"
            end
            return nil
        end
    }
    
    return trackMock("particle", particle)
end

-- Create a standardized camera mock
function MockBuilder.createCamera(options)
    options = options or {}
    local camera = {
        x = options.x or 0,
        y = options.y or 0,
        scale = options.scale or 1.0,
        rotation = options.rotation or 0,
        
        -- Camera methods
        worldToScreen = function(worldX, worldY)
            return (worldX - camera.x) * camera.scale, (worldY - camera.y) * camera.scale
        end,
        
        screenToWorld = function(screenX, screenY)
            return screenX / camera.scale + camera.x, screenY / camera.scale + camera.y
        end,
        
        -- Validation
        _validate = function()
            if camera.scale <= 0 then
                return "Camera scale must be positive"
            end
            return nil
        end
    }
    
    return trackMock("camera", camera)
end

-- Create a standardized game state mock
function MockBuilder.createGameState(options)
    options = options or {}
    local gameState = {
        planets = options.planets or {},
        rings = options.rings or {},
        particles = options.particles or {},
        player = options.player or MockBuilder.createPlayer(),
        score = options.score or 0,
        combo = options.combo or 0,
        gameMode = options.gameMode or "playing",
        
        -- Game state methods
        getPlanets = function() return gameState.planets end,
        getRings = function() return gameState.rings end,
        getParticles = function() return gameState.particles end,
        addScore = function(points) gameState.score = gameState.score + points end,
        addCombo = function() gameState.combo = gameState.combo + 1 end,
        showMessage = function(message) end,
        getStats = function() return {score = gameState.score, combo = gameState.combo} end,
        setPlanets = function(planets) gameState.planets = planets end,
        setRings = function(rings) gameState.rings = rings end,
        addParticle = function(particle) table.insert(gameState.particles, particle) end,
        
        -- Validation
        _validate = function()
            if gameState.score < 0 then
                return "Score cannot be negative"
            end
            if gameState.combo < 0 then
                return "Combo cannot be negative"
            end
            return nil
        end
    }
    
    return trackMock("gameState", gameState)
end

-- Create enhanced graphics call tracker for renderer tests
function MockBuilder.createGraphicsTracker()
    local tracker = {
        calls = {},
        
        -- Clear all tracked calls
        clear = function()
            tracker.calls = {}
        end,
        
        -- Get calls of a specific type
        getCalls = function(callType)
            local filtered = {}
            for _, call in ipairs(tracker.calls) do
                if call.type == callType then
                    table.insert(filtered, call)
                end
            end
            return filtered
        end,
        
        -- Count calls of a specific type
        countCalls = function(callType)
            return #tracker.getCalls(callType)
        end,
        
        -- Check if a call exists matching a predicate
        hasCall = function(callType, predicate)
            local calls = tracker.getCalls(callType)
            if not predicate then return #calls > 0 end
            
            for _, call in ipairs(calls) do
                if predicate(call) then
                    return true
                end
            end
            return false
        end,
        
        -- Record a graphics call
        record = function(callType, data)
            data.type = callType
            table.insert(tracker.calls, data)
        end
    }
    
    return tracker
end

-- Create mock systems for integration tests
function MockBuilder.createMockSystems()
    return {
        SoundManager = {
            play = function(sound, volume, pitch) end,
            playJump = function() end,
            playRingCollect = function(combo) end,
            playDash = function() end,
            playLand = function() end,
            playGameOver = function() end,
            setEnabled = function(enabled) end,
            setVolume = function(volume) end
        },
        
        ParticleSystem = {
            add = function(particle) end,
            update = function(dt) end,
            get = function() return {} end,
            clear = function() end
        },
        
        AchievementSystem = {
            checkAchievement = function(type, data) end,
            unlockAchievement = function(id) end,
            getUnlockedAchievements = function() return {} end
        },
        
        PerformanceMonitor = {
            startTimer = function(name) end,
            endTimer = function(name) return 0 end,
            update = function(dt) end,
            getReport = function() return {fps = 60, frameTime = "16.67ms"} end
        }
    }
end

return MockBuilder