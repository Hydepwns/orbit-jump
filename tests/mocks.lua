-- Mock system for Orbit Jump tests
-- Provides mock implementations of LÖVE2D and other external dependencies

local Mocks = {}

-- Track function calls for testing
local callTracker = {}

-- Mock LÖVE2D framework with enhanced graphics state tracking
Mocks.love = {
  graphics = {
    -- Internal graphics state
    _state = {
      color = {1, 1, 1, 1},
      font = nil,
      lineWidth = 1,
      blendMode = "alpha",
      transformStack = {},
      currentTransform = {x = 0, y = 0, rotation = 0, scaleX = 1, scaleY = 1}
    },
    
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
    rectangle = function(mode, x, y, width, height, rx, ry, segments)
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
      return Mocks.mockFont(16)
    end,
    newFont = function(path, size)
      callTracker.newFont = callTracker.newFont or 0
      callTracker.newFont = callTracker.newFont + 1
      return Mocks.mockFont(size or 16)
    end,
    getDefaultFont = function()
      return Mocks.mockFont(12)
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
      -- Save current transform state
      table.insert(Mocks.love.graphics._state.transformStack, {
        x = Mocks.love.graphics._state.currentTransform.x,
        y = Mocks.love.graphics._state.currentTransform.y,
        rotation = Mocks.love.graphics._state.currentTransform.rotation,
        scaleX = Mocks.love.graphics._state.currentTransform.scaleX,
        scaleY = Mocks.love.graphics._state.currentTransform.scaleY
      })
    end,
    pop = function()
      callTracker.pop = callTracker.pop or 0
      callTracker.pop = callTracker.pop + 1
      -- Restore previous transform state
      if #Mocks.love.graphics._state.transformStack > 0 then
        local prevTransform = table.remove(Mocks.love.graphics._state.transformStack)
        Mocks.love.graphics._state.currentTransform = prevTransform
      end
    end,
    translate = function(x, y)
      callTracker.translate = callTracker.translate or 0
      callTracker.translate = callTracker.translate + 1
      Mocks.love.graphics._state.currentTransform.x = Mocks.love.graphics._state.currentTransform.x + (x or 0)
      Mocks.love.graphics._state.currentTransform.y = Mocks.love.graphics._state.currentTransform.y + (y or 0)
    end,
    scale = function(sx, sy)
      callTracker.scale = callTracker.scale or 0
      callTracker.scale = callTracker.scale + 1
      sy = sy or sx
      Mocks.love.graphics._state.currentTransform.scaleX = Mocks.love.graphics._state.currentTransform.scaleX * sx
      Mocks.love.graphics._state.currentTransform.scaleY = Mocks.love.graphics._state.currentTransform.scaleY * sy
    end,
    rotate = function(angle)
      callTracker.rotate = callTracker.rotate or 0
      callTracker.rotate = callTracker.rotate + 1
      Mocks.love.graphics._state.currentTransform.rotation = Mocks.love.graphics._state.currentTransform.rotation + angle
    end,
    setScissor = function(x, y, width, height)
      callTracker.setScissor = callTracker.setScissor or 0
      callTracker.setScissor = callTracker.setScissor + 1
    end,
    captureScreenshot = function(callback)
      callTracker.captureScreenshot = callTracker.captureScreenshot or 0
      callTracker.captureScreenshot = callTracker.captureScreenshot + 1
      local mockData = {
        encode = function(format, filename) return true end,
        getFormat = function() return "rgba8" end,
        getDimensions = function() return 800, 600 end,
        getWidth = function() return 800 end,
        getHeight = function() return 600 end
      }
      if callback then callback(mockData) end
      return true
    end,
    
    -- Additional graphics functions
    polygon = function(mode, ...)
      callTracker.polygon = callTracker.polygon or 0
      callTracker.polygon = callTracker.polygon + 1
    end,
    points = function(...)
      callTracker.points = callTracker.points or 0
      callTracker.points = callTracker.points + 1
    end,
    getLineWidth = function() return 1 end,
    clear = function(r, g, b, a)
      callTracker.clear = callTracker.clear or 0
      callTracker.clear = callTracker.clear + 1
    end,
    present = function()
      callTracker.present = callTracker.present or 0
      callTracker.present = callTracker.present + 1
    end,
    shear = function(kx, ky)
      callTracker.shear = callTracker.shear or 0
      callTracker.shear = callTracker.shear + 1
    end,
    origin = function()
      callTracker.origin = callTracker.origin or 0
      callTracker.origin = callTracker.origin + 1
    end,
    intersectScissor = function(x, y, width, height)
      callTracker.intersectScissor = callTracker.intersectScissor or 0
      callTracker.intersectScissor = callTracker.intersectScissor + 1
    end,
    setBlendMode = function(mode, alphamode)
      callTracker.setBlendMode = callTracker.setBlendMode or 0
      callTracker.setBlendMode = callTracker.setBlendMode + 1
    end,
    getBlendMode = function() return "alpha", "alphamultiply" end,
    newImage = function(path)
      callTracker.newImage = callTracker.newImage or 0
      callTracker.newImage = callTracker.newImage + 1
      return Mocks.mockImage()
    end,
    draw = function(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
      callTracker.draw = callTracker.draw or 0
      callTracker.draw = callTracker.draw + 1
    end,
    newCanvas = function(width, height)
      callTracker.newCanvas = callTracker.newCanvas or 0
      callTracker.newCanvas = callTracker.newCanvas + 1
      return Mocks.mockCanvas(width or 800, height or 600)
    end,
    setCanvas = function(canvas)
      callTracker.setCanvas = callTracker.setCanvas or 0
      callTracker.setCanvas = callTracker.setCanvas + 1
    end,
    getCanvas = function() return nil end
  },

  event = {
    quit = function(restart)
      callTracker.quit = callTracker.quit or 0
      callTracker.quit = callTracker.quit + 1
    end
  },

  timer = {
    -- Internal time state for consistent testing
    _time = 0,
    _delta = 1 / 60,
    
    getTime = function() return Mocks.love.timer._time end,
    getDelta = function() return Mocks.love.timer._delta end,
    getFPS = function() return 60 end,
    getAverageDelta = function() return 1 / 60 end,
    sleep = function(s) end,
    step = function()
      Mocks.love.timer._time = Mocks.love.timer._time + Mocks.love.timer._delta
      return Mocks.love.timer._delta
    end,
    
    -- Test helpers
    setTime = function(time) Mocks.love.timer._time = time end,
    setDelta = function(delta) Mocks.love.timer._delta = delta end,
    advance = function(time) 
      Mocks.love.timer._time = Mocks.love.timer._time + time 
    end,
    reset = function() 
      Mocks.love.timer._time = 0 
      Mocks.love.timer._delta = 1 / 60
    end
  },

  mouse = {
    -- Internal state for testing
    _position = { x = 400, y = 300 },
    _buttons = {},
    _pressed = {},
    _released = {},
    
    getPosition = function() return Mocks.love.mouse._position.x, Mocks.love.mouse._position.y end,
    getX = function() return Mocks.love.mouse._position.x end,
    getY = function() return Mocks.love.mouse._position.y end,
    isDown = function(button) return Mocks.love.mouse._buttons[button] or false end,
    wasPressed = function(button) return Mocks.love.mouse._pressed[button] or false end,
    wasReleased = function(button) return Mocks.love.mouse._released[button] or false end,
    getRelativeMode = function() return false end,
    setRelativeMode = function(enable) end,
    isVisible = function() return true end,
    setVisible = function(visible) end,
    isCursorSupported = function() return true end,
    getCursor = function() return nil end,
    setCursor = function(cursor) end,
    position = { x = 400, y = 300 },
    
    -- Test helpers
    setPosition = function(x, y) 
      Mocks.love.mouse._position.x = x
      Mocks.love.mouse._position.y = y
    end,
    pressButton = function(button)
      Mocks.love.mouse._buttons[button] = true
      Mocks.love.mouse._pressed[button] = true
    end,
    releaseButton = function(button)
      Mocks.love.mouse._buttons[button] = false
      Mocks.love.mouse._released[button] = true
    end,
    clearInputs = function()
      Mocks.love.mouse._pressed = {}
      Mocks.love.mouse._released = {}
    end
  },

  keyboard = {
    -- Internal state for testing
    _keys = {},
    _pressed = {},
    _released = {},
    
    isDown = function(key) return Mocks.love.keyboard._keys[key] or false end,
    wasPressed = function(key) return Mocks.love.keyboard._pressed[key] or false end,
    wasReleased = function(key) return Mocks.love.keyboard._released[key] or false end,
    hasKeyRepeat = function() return false end,
    setKeyRepeat = function(enable) end,
    hasTextInput = function() return false end,
    setTextInput = function(enable) end,
    hasScreenKeyboard = function() return false end,
    isScancodeDown = function(scancode) return false end,
    
    -- Test helpers
    pressKey = function(key)
      Mocks.love.keyboard._keys[key] = true
      Mocks.love.keyboard._pressed[key] = true
    end,
    releaseKey = function(key)
      Mocks.love.keyboard._keys[key] = false
      Mocks.love.keyboard._released[key] = true
    end,
    clearInputs = function()
      Mocks.love.keyboard._pressed = {}
      Mocks.love.keyboard._released = {}
    end
  },
  
  touch = {
    getTouchCount = function() return 0 end,
    getTouches = function() return {} end,
    getPosition = function(id) return 0, 0 end,
    getPressure = function(id) return 1 end
  },
  
  joystick = {
    getJoysticks = function() return {} end,
    getJoystickCount = function() return 0 end
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
      return { size = 1024, type = "file" }
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

  sound = {
    newSoundData = function(samples, rate, bits, channels)
      callTracker.soundNewSoundData = callTracker.soundNewSoundData or 0
      callTracker.soundNewSoundData = callTracker.soundNewSoundData + 1
      return {
        getSampleCount = function() return samples end,
        setSample = function(self, i, sample) end,
        getSample = function(self, i) return 0 end,
        getChannelCount = function() return channels or 1 end,
        getDuration = function() return samples / (rate or 44100) end,
        getSampleRate = function() return rate or 44100 end
      }
    end
  },
  
  audio = {
    newSource = function(path, sourceType)
      callTracker.audioNewSource = callTracker.audioNewSource or 0
      callTracker.audioNewSource = callTracker.audioNewSource + 1
      -- If path is a SoundData object, create source from it
      if type(path) == "table" and path.getSampleCount then
        return Mocks.mockAudioSource()
      end
      return Mocks.mockAudioSource()
    end,
    play = function(source)
      callTracker.audioPlay = callTracker.audioPlay or 0
      callTracker.audioPlay = callTracker.audioPlay + 1
    end,
    stop = function(source)
      callTracker.audioStop = callTracker.audioStop or 0
      callTracker.audioStop = callTracker.audioStop + 1
    end,
    pause = function(source)
      callTracker.audioPause = callTracker.audioPause or 0
      callTracker.audioPause = callTracker.audioPause + 1
    end,
    resume = function(source)
      callTracker.audioResume = callTracker.audioResume or 0
      callTracker.audioResume = callTracker.audioResume + 1
    end,
    setVolume = function(volume)
      callTracker.audioSetVolume = callTracker.audioSetVolume or 0
      callTracker.audioSetVolume = callTracker.audioSetVolume + 1
    end,
    getVolume = function() return 1.0 end,
    getActiveSourceCount = function() return 0 end,
    getMaxSources = function() return 32 end,
    getOrientation = function() return 0, 0, -1, 0, 1, 0 end,
    setOrientation = function(fx, fy, fz, ux, uy, uz) end,
    getPosition = function() return 0, 0, 0 end,
    setPosition = function(x, y, z) end,
    getVelocity = function() return 0, 0, 0 end,
    setVelocity = function(x, y, z) end,
    getDopplerScale = function() return 1 end,
    setDopplerScale = function(scale) end,
    getDistanceModel = function() return "inverseclamped" end,
    setDistanceModel = function(model) end
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
  random = function(n, m)
    if n and m then
      -- math.random(n, m) - return integer between n and m
      return n + math.floor((m - n + 1) * 0.5)
    elseif n then
      -- math.random(n) - return integer between 1 and n
      return math.max(1, math.floor(n * 0.5) + 1)
    else
      -- math.random() - return float between 0 and 1
      return 0.5
    end
  end,
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
    return math.sqrt(dx * dx + dy * dy), dx, dy
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
  time = function() return 1704067200 end   -- 2024-01-01 00:00:00 UTC
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
  getn = function(t) return #t end   -- Lua 5.0 compatibility
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
  triggerQuantumTeleport = function(x, y) end,
  startEvent = function(eventType, params) end,
  createWarpEffect = function(x, y) end,
  events = {},
  activeEvents = {},
  init = function() end,
  update = function(dt) end,
  isEventActive = function(eventType) return false end
}

Mocks.ring_constellations = {
  getConstellation = function() return "test" end,
  onRingCollected = function(ring, player) end
}

Mocks.SoundManager = {
  new = function(self)
    local instance = {
      sounds = {},
      enabled = true,
      volume = 1.0
    }
    setmetatable(instance, {__index = Mocks.SoundManager})
    return instance
  end,
  load = function(self) 
    -- Mock sounds would be loaded here
  end,
  play = function(self, soundName, volume, pitch) end,
  playCollectRing = function() end,
  playLand = function() end,
  playJump = function() end,
  playDash = function() end,
  playEventWarning = function() end,
  playRingCollect = function(self, combo) end,
  playCombo = function(self) end,
  playGameOver = function(self) end,
  playCollect = function(self) end,
  playConstellation = function(self) end,
  restartAmbient = function(self) end,
  update = function(self, dt) end,
  init = function() end,
  setVolume = function(self, volume) 
    if type(self) == "table" and self.volume then
      self.volume = volume
    end
  end,
  getVolume = function(self) 
    if type(self) == "table" and self.volume then
      return self.volume
    end
    return 1.0 
  end,
  setEnabled = function(self, enabled)
    if type(self) == "table" then
      self.enabled = enabled
    end
  end,
  isMuted = function() return false end,
  mute = function() end,
  unmute = function() end
}

-- Mock WarpDrive system
Mocks.WarpDrive = {
  init = function() end,
  isActive = function() return false end,
  activate = function(targetX, targetY) end,
  deactivate = function() end,
  update = function(dt, player) end,
  canWarp = function(player) return true end,
  getWarpZones = function() return {} end
}

-- Mock ErrorHandler for better test isolation
Mocks.ErrorHandler = {
  safeCall = function(func, ...)
    local success, result = pcall(func, ...)
    if not success then
      Mocks.trackCall("error", result)
    end
    return success, result
  end,
  rawPcall = function(func, ...)
    return pcall(func, ...)
  end,
  handleModuleError = function(moduleName, error)
    Mocks.trackCall("error", string.format("Module %s error: %s", moduleName, error))
  end,
  validateModule = function(module, requiredFunctions)
    if not module then return false end
    for _, func in ipairs(requiredFunctions or {}) do
      if not module[func] then return false end
    end
    return true
  end,
  init = function() end
}

-- Mock ArtifactSystem
Mocks.ArtifactSystem = {
  artifacts = {
    {
      id = "origin_fragment_1",
      name = "Origin Fragment I",
      description = "The first explorers called it 'The Jump'",
      hint = "Near the center of known space",
      color = { 0.8, 0.6, 1 },
      discovered = false
    },
    {
      id = "origin_fragment_2",
      name = "Origin Fragment II",
      description = "They learned to harness momentum",
      hint = "Where ice meets the void",
      color = { 0.6, 0.8, 1 },
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
        color = { 0.8, 0.3, 0.3 },
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
        color = { 0.3, 0.7, 1, 0.8 },
        type = "standard"
      }
    }
  end,
  addScore = function(score) end,
  addCombo = function() end,
  showMessage = function(message) end,
  getStats = function() return {score = 0, combo = 0} end,
  setPlanets = function(planets) end,
  setRings = function(rings) end,
  addParticle = function(particle) end,
  getParticles = function() return {} end,
  addMessage = function(message) end
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
      color = { 0.3, 0.7, 1, 0.8 },
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
    standard = { value = 10, color = { 0.3, 0.7, 1, 0.8 } },
    ghost = { value = 20, color = { 0.8, 0.8, 0.8, 0.6 } },
    warp = { value = 30, color = { 0.8, 0.2, 0.8, 0.8 } },
    chain = { value = 25, color = { 1, 0.8, 0.2, 0.8 } }
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
          x = 0,
          y = 0,
          vx = 0,
          vy = 0,
          lifetime = 0,
          maxLifetime = 1,
          size = 2,
          color = { 1, 1, 1, 1 },
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
        particle.color = { 1, 1, 1, 1 }
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
    particle.color = color or { 1, 1, 1, 1 }
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
        color or { 1, 1, 0.8, 1 },
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
  
  -- Load MockBuilder if available and initialize
  local success, MockBuilder = pcall(require, "tests.mock_builder")
  if success then
    MockBuilder.reset()
    _G.MockBuilder = MockBuilder
  end

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
  
  -- Initialize renderer with mock fonts if it exists
  local Utils = require("src.utils.utils")
  local success, Renderer = pcall(Utils.require, "src.core.renderer")
  if success and Renderer then
    Renderer.fonts = {
      light = Mocks.mockFont(14),
      regular = Mocks.mockFont(16),
      bold = Mocks.mockFont(18),
      extraBold = Mocks.mockFont(20)
    }
  end
  _G.SoundManager = Mocks.SoundManager
  _G.Config = Mocks.Config
  _G.ArtifactSystem = Mocks.ArtifactSystem
  _G.GameState = Mocks.GameState
  _G.RingSystem = Mocks.RingSystem
  _G.ParticleSystem = Mocks.ParticleSystem
  _G.WarpDrive = Mocks.WarpDrive
  _G.ErrorHandler = Mocks.ErrorHandler
  _G.mockGameState = Mocks.gameState

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
        info = function(msg, ...)
          callTracker.info = callTracker.info or 0
          callTracker.info = callTracker.info + 1
        end,
        warn = function(msg, ...)
          callTracker.warn = callTracker.warn or 0
          callTracker.warn = callTracker.warn + 1
        end,
        error = function(msg, ...)
          callTracker.error = callTracker.error or 0
          callTracker.error = callTracker.error + 1
        end,
        debug = function(msg, ...)
          callTracker.debug = callTracker.debug or 0
          callTracker.debug = callTracker.debug + 1
        end,
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
      Utils.ErrorHandler = Mocks.ErrorHandler
    end
    
    -- Mock MobileInput
    if not Utils.MobileInput then
      Utils.MobileInput = {
        init = function() 
          Mocks.trackCall("mobile_input_init")
        end,
        isMobile = function() return false end,
        handleTouch = function(id, x, y, pressure) 
          Mocks.trackCall("mobile_input_touch")
          return true 
        end,
        handleTouchMove = function(id, x, y, pressure) 
          Mocks.trackCall("mobile_input_touch_move")
          return true 
        end,
        handleTouchRelease = function(id, x, y, pressure) 
          Mocks.trackCall("mobile_input_touch_release")
          return true 
        end,
        isEnabled = function() return false end,
        setEnabled = function(enabled) end
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
      color = { 0.8, 0.3, 0.3 },
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
      color = { 0.3, 0.7, 1, 0.8 },
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
    table.insert(calls, { ... })
    return returnValue
  end
  mock.getCalls = function() return calls end
  mock.getCallCount = function() return #calls end
  mock.reset = function() calls = {} end
  return mock
end

-- Helper function to create a mock font
function Mocks.mockFont(size)
  size = size or 16
  return {
    getWidth = function(text) 
      return string.len(tostring(text)) * (size * 0.6) 
    end,
    getHeight = function() return size end,
    getLineHeight = function() return size * 1.2 end,
    getBaseline = function() return size * 0.8 end,
    getAscent = function() return size * 0.8 end,
    getDescent = function() return size * 0.2 end,
    getWrap = function(text, wraplimit)
      local lines = {}
      local words = {}
      for word in string.gmatch(tostring(text), "%S+") do
        table.insert(words, word)
      end
      
      local line = ""
      for _, word in ipairs(words) do
        local testLine = line == "" and word or (line .. " " .. word)
        if string.len(testLine) * (size * 0.6) <= wraplimit then
          line = testLine
        else
          table.insert(lines, line)
          line = word
        end
      end
      if line ~= "" then
        table.insert(lines, line)
      end
      
      return string.len(text) * (size * 0.6), lines
    end,
    hasGlyphs = function(...) return true end,
    setFallbacks = function(...) end,
    getFilter = function() return "linear", "linear", 1 end,
    setFilter = function(min, mag, anisotropy) end
  }
end

-- Helper function to create a mock audio source
function Mocks.mockAudioSource()
  local source = {
    _isPlaying = false,
    _volume = 1.0,
    _pitch = 1.0,
    _looping = false,
    _position = {0, 0, 0},
    _velocity = {0, 0, 0},
    _direction = {0, 0, 0}
  }
  
  -- Mock the :new() method that some tests expect
  source.new = function(self, ...)
    return Mocks.mockAudioSource()
  end
  
  source.play = function(self)
    callTracker.sourcePlay = callTracker.sourcePlay or 0
    callTracker.sourcePlay = callTracker.sourcePlay + 1
    self._isPlaying = true
  end
  
  source.stop = function(self)
    callTracker.sourceStop = callTracker.sourceStop or 0
    callTracker.sourceStop = callTracker.sourceStop + 1
    self._isPlaying = false
  end
  
  source.pause = function(self)
    callTracker.sourcePause = callTracker.sourcePause or 0
    callTracker.sourcePause = callTracker.sourcePause + 1
    self._isPlaying = false
  end
  
  source.resume = function(self)
    callTracker.sourceResume = callTracker.sourceResume or 0
    callTracker.sourceResume = callTracker.sourceResume + 1
    self._isPlaying = true
  end
  
  source.isPlaying = function(self) return self._isPlaying end
  source.isPaused = function(self) return not self._isPlaying end
  source.isStopped = function(self) return not self._isPlaying end
  
  source.setVolume = function(self, volume) self._volume = volume end
  source.getVolume = function(self) return self._volume end
  
  source.setPitch = function(self, pitch) self._pitch = pitch end
  source.getPitch = function(self) return self._pitch end
  
  source.setLooping = function(self, looping) self._looping = looping end
  source.isLooping = function(self) return self._looping end
  
  source.setPosition = function(self, x, y, z) self._position = {x, y or 0, z or 0} end
  source.getPosition = function(self) return unpack(self._position) end
  
  source.setVelocity = function(self, x, y, z) self._velocity = {x, y or 0, z or 0} end
  source.getVelocity = function(self) return unpack(self._velocity) end
  
  source.setDirection = function(self, x, y, z) self._direction = {x, y or 0, z or 0} end
  source.getDirection = function(self) return unpack(self._direction) end
  
  source.clone = function(self)
    return Mocks.mockAudioSource()
  end
  
  source.getDuration = function(self, unit) return 1.0 end
  source.getType = function(self) return "static" end
  source.getChannelCount = function(self) return 2 end
  source.getSampleRate = function(self) return 44100 end
  source.getBitDepth = function(self) return 16 end
  
  return source
end

-- Helper function to create a mock image
function Mocks.mockImage()
  return {
    getWidth = function() return 64 end,
    getHeight = function() return 64 end,
    getDimensions = function() return 64, 64 end,
    getPixel = function(x, y) return 1, 1, 1, 1 end,
    getFormat = function() return "rgba8" end,
    getFilter = function() return "linear", "linear", 1 end,
    setFilter = function(min, mag, anisotropy) end,
    getWrap = function() return "clamp", "clamp" end,
    setWrap = function(horiz, vert) end,
    getMipmapMode = function() return "none" end,
    setMipmapMode = function(mode, sharpness) end,
    isReadable = function() return true end,
    getData = function() return "mock image data" end
  }
end

-- Helper function to create a mock canvas
function Mocks.mockCanvas(width, height)
  local canvas = Mocks.mockImage()
  canvas.getWidth = function() return width end
  canvas.getHeight = function() return height end
  canvas.getDimensions = function() return width, height end
  canvas.renderTo = function(func) if func then func() end end
  canvas.newImageData = function() return "mock canvas data" end
  canvas.getMSAA = function() return 0 end
  return canvas
end

-- Track mock function usage
function Mocks.trackCall(name, ...)
  callTracker[name] = callTracker[name] or 0
  callTracker[name] = callTracker[name] + 1
end

-- Reusable Mock Patterns
Mocks.patterns = {}

-- Pattern: Game System with init/update/reset
function Mocks.patterns.gameSystem(systemName, customMethods)
  local system = {
    init = function() 
      Mocks.trackCall(systemName .. "_init")
    end,
    update = function(dt) 
      Mocks.trackCall(systemName .. "_update")
    end,
    reset = function() 
      Mocks.trackCall(systemName .. "_reset")
    end,
    isActive = function() return false end
  }
  
  -- Add custom methods
  if customMethods then
    for name, func in pairs(customMethods) do
      system[name] = func
    end
  end
  
  return system
end

-- Pattern: UI Component with show/hide/toggle
function Mocks.patterns.uiComponent(componentName, initialVisible)
  return {
    visible = initialVisible or false,
    alpha = initialVisible and 1.0 or 0.0,
    
    show = function(self)
      Mocks.trackCall(componentName .. "_show")
      self.visible = true
      self.alpha = 1.0
    end,
    
    hide = function(self)
      Mocks.trackCall(componentName .. "_hide")
      self.visible = false
      self.alpha = 0.0
    end,
    
    toggle = function(self)
      if self.visible then
        self:hide()
      else
        self:show()
      end
    end,
    
    update = function(self, dt)
      -- Fade animation mock
      if self.visible and self.alpha < 1.0 then
        self.alpha = math.min(1.0, self.alpha + dt * 2)
      elseif not self.visible and self.alpha > 0.0 then
        self.alpha = math.max(0.0, self.alpha - dt * 2)
      end
    end,
    
    draw = function(self)
      if self.alpha > 0 then
        Mocks.trackCall(componentName .. "_draw")
      end
    end,
    
    handleInput = function(self, key)
      if self.visible then
        Mocks.trackCall(componentName .. "_input_" .. tostring(key))
        return true -- consumed
      end
      return false
    end
  }
end

-- Pattern: Entity with position and movement
function Mocks.patterns.entity(x, y, radius)
  return {
    x = x or 0,
    y = y or 0,
    vx = 0,
    vy = 0,
    radius = radius or 10,
    active = true,
    
    update = function(self, dt)
      if self.active then
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
      end
    end,
    
    setPosition = function(self, x, y)
      self.x = x
      self.y = y
    end,
    
    setVelocity = function(self, vx, vy)
      self.vx = vx
      self.vy = vy
    end,
    
    distanceTo = function(self, other)
      local dx = other.x - self.x
      local dy = other.y - self.y
      return math.sqrt(dx * dx + dy * dy)
    end,
    
    collidesWith = function(self, other)
      return self:distanceTo(other) < (self.radius + other.radius)
    end
  }
end

-- Pattern: Manager with items and CRUD operations
function Mocks.patterns.manager(itemName)
  local manager = {
    items = {},
    nextId = 1
  }
  
  manager.add = function(self, item)
    item.id = item.id or self.nextId
    self.nextId = self.nextId + 1
    table.insert(self.items, item)
    Mocks.trackCall(itemName .. "_manager_add")
    return item
  end
  
  manager.remove = function(self, id)
    for i, item in ipairs(self.items) do
      if item.id == id then
        table.remove(self.items, i)
        Mocks.trackCall(itemName .. "_manager_remove")
        return item
      end
    end
    return nil
  end
  
  manager.get = function(self, id)
    for _, item in ipairs(self.items) do
      if item.id == id then
        return item
      end
    end
    return nil
  end
  
  manager.getAll = function(self)
    return self.items
  end
  
  manager.clear = function(self)
    self.items = {}
    self.nextId = 1
    Mocks.trackCall(itemName .. "_manager_clear")
  end
  
  manager.count = function(self)
    return #self.items
  end
  
  manager.update = function(self, dt)
    for _, item in ipairs(self.items) do
      if item.update then
        item:update(dt)
      end
    end
  end
  
  return manager
end

-- Pattern: Resource with loading/saving
function Mocks.patterns.resource(resourceName)
  return {
    loaded = false,
    data = nil,
    
    load = function(self, path)
      Mocks.trackCall(resourceName .. "_load")
      self.loaded = true
      self.data = "mock_" .. resourceName .. "_data"
      return true
    end,
    
    save = function(self, path, data)
      Mocks.trackCall(resourceName .. "_save")
      self.data = data
      return true
    end,
    
    isLoaded = function(self)
      return self.loaded
    end,
    
    getData = function(self)
      return self.data
    end,
    
    unload = function(self)
      Mocks.trackCall(resourceName .. "_unload")
      self.loaded = false
      self.data = nil
    end
  }
end

-- Add mock state reset function
function Mocks.resetState()
  callTracker = {}
  
  -- Reset graphics state
  if Mocks.love.graphics._state then
    Mocks.love.graphics._state = {
      color = {1, 1, 1, 1},
      font = nil,
      lineWidth = 1,
      blendMode = "alpha",
      transformStack = {},
      currentTransform = {x = 0, y = 0, rotation = 0, scaleX = 1, scaleY = 1}
    }
  end
  
  -- Reset timer state
  if Mocks.love.timer then
    Mocks.love.timer._time = 0
    Mocks.love.timer._delta = 1 / 60
  end
  
  -- Reset input state
  if Mocks.love.mouse then
    Mocks.love.mouse._pressed = {}
    Mocks.love.mouse._released = {}
  end
  if Mocks.love.keyboard then
    Mocks.love.keyboard._pressed = {}
    Mocks.love.keyboard._released = {}
  end
  
  -- Reset MockBuilder if available
  if _G.MockBuilder then
    _G.MockBuilder.reset()
  end
end

return Mocks
