-- Artifact System for Orbit Jump
-- Collectible lore items scattered across the galaxy

local Utils = require("src.utils.utils")
local ArtifactSystem = {}

-- Artifact definitions
ArtifactSystem.artifacts = {
  {
    id = "origin_fragment_1",
    name = "Origin Fragment I",
    description =
    "The first explorers called it 'The Jump' - a technique discovered by accident when a pilot's gravity tether malfunctioned.",
    hint = "Near the center of known space",
    color = { 0.8, 0.6, 1 },
    discovered = false
  },
  {
    id = "origin_fragment_2",
    name = "Origin Fragment II",
    description =
    "They learned to harness momentum, to dance between gravity wells. Each jump became a calculated risk, a leap of faith.",
    hint = "Where ice meets the void",
    color = { 0.6, 0.8, 1 },
    discovered = false
  },
  {
    id = "origin_fragment_3",
    name = "Origin Fragment III",
    description =
    "The rings appeared first around tech planets - geometric patterns that defied explanation. Were they beacons? Or warnings?",
    hint = "In the glow of technology",
    color = { 0.2, 1, 0.8 },
    discovered = false
  },
  {
    id = "void_whisper_1",
    name = "Void Whisper I",
    description =
    "The void planets repel all matter, yet something sleeps within. The first explorer to approach one reported hearing... music?",
    hint = "Where gravity pushes away",
    color = { 0.8, 0.2, 0.8 },
    discovered = false
  },
  {
    id = "void_whisper_2",
    name = "Void Whisper II",
    description =
    "Negative space. Inverted reality. The void planets shouldn't exist, yet here they are. What force created them?",
    hint = "Deep in the purple darkness",
    color = { 0.6, 0.1, 0.6 },
    discovered = false
  },
  {
    id = "quantum_echo_1",
    name = "Quantum Echo I",
    description =
    "Reality shifts around quantum planets. Time flows differently. Some explorers report seeing themselves jump before they decide to.",
    hint = "Where reality bends",
    color = { 1, 0, 1 },
    discovered = false
  },
  {
    id = "quantum_echo_2",
    name = "Quantum Echo II",
    description =
    "The quantum teleportation isn't random. There's a pattern, a purpose. The planets are connected by invisible threads.",
    hint = "In the shifting colors",
    color = { 0.8, 0.2, 1 },
    discovered = false
  },
  {
    id = "explorer_log_1",
    name = "Explorer's Log I",
    description =
    "Day 47: The rings sing when collected in sequence. I've started mapping the melodies. There's something hidden in the harmony.",
    hint = "Near a ring constellation",
    color = { 1, 0.8, 0.2 },
    discovered = false
  },
  {
    id = "explorer_log_2",
    name = "Explorer's Log II",
    description =
    "Day 198: I've discovered warp zones - tears in space that lead to challenge dimensions. Who built these trials?",
    hint = "Beyond a secret portal",
    color = { 1, 0.5, 0 },
    discovered = false
  },
  {
    id = "final_truth",
    name = "The Final Truth",
    description =
    "The jumps, the rings, the planets - they're all connected. We're not exploring... we're remembering. This isn't space. This is—",
    hint = "Collect all other artifacts first",
    color = { 1, 1, 1 },
    discovered = false,
    requiresAll = true
  }
}

-- Active artifacts in world
ArtifactSystem.spawnedArtifacts = {}
ArtifactSystem.collectedCount = 0
ArtifactSystem.notificationQueue = {}
ArtifactSystem.notificationTimer = 0

-- Visual settings
ArtifactSystem.pulsePhase = 0
ArtifactSystem.particleTimer = 0

-- Initialize
function ArtifactSystem.init()
  -- Reset all artifacts
  for _, artifact in ipairs(ArtifactSystem.artifacts) do
    artifact.discovered = false
  end
  ArtifactSystem.spawnedArtifacts = {}
  ArtifactSystem.collectedCount = 0
  ArtifactSystem.notificationQueue = {}
  return true
end

-- Spawn artifacts based on conditions
function ArtifactSystem.spawnArtifacts(player, planets)
  -- Don't spawn if all are collected
  if ArtifactSystem.collectedCount >= #ArtifactSystem.artifacts then
    return
  end

  -- Check each artifact's spawn conditions
  for i, artifactDef in ipairs(ArtifactSystem.artifacts) do
    if not artifactDef.discovered and not ArtifactSystem.isArtifactSpawned(artifactDef.id) then
      local shouldSpawn = false
      local spawnX, spawnY = 0, 0

      -- Special spawn conditions based on hint
      if artifactDef.id == "origin_fragment_1" then
        -- Near center of space
        local distFromOrigin = math.sqrt(player.x ^ 2 + player.y ^ 2)
        if distFromOrigin < 1000 then
          shouldSpawn = math.random() < 0.01
          spawnX = math.random(-500, 500)
          spawnY = math.random(-500, 500)
        end
      elseif artifactDef.id == "origin_fragment_2" then
        -- Near ice planet far from origin
        for _, planet in ipairs(planets) do
          if planet.type == "ice" then
            local dist = Utils.distance(player.x, player.y, planet.x, planet.y)
            if dist < 1000 and math.abs(planet.x) > 2000 then
              shouldSpawn = math.random() < 0.02
              spawnX = planet.x + math.random(-200, 200)
              spawnY = planet.y + math.random(-200, 200)
              break
            end
          end
        end
      elseif artifactDef.id == "origin_fragment_3" then
        -- Near tech planet
        for _, planet in ipairs(planets) do
          if planet.type == "tech" and planet.discovered then
            shouldSpawn = math.random() < 0.02
            spawnX = planet.x + math.random(-300, 300)
            spawnY = planet.y + math.random(-300, 300)
            break
          end
        end
      elseif string.find(artifactDef.id, "void_whisper") then
        -- Near void planets
        for _, planet in ipairs(planets) do
          if planet.type == "void" and planet.discovered then
            shouldSpawn = math.random() < 0.03
            spawnX = planet.x + math.random(-400, 400)
            spawnY = planet.y + math.random(-400, 400)
            break
          end
        end
      elseif string.find(artifactDef.id, "quantum_echo") then
        -- Near quantum planets
        for _, planet in ipairs(planets) do
          if planet.type == "quantum" then
            shouldSpawn = math.random() < 0.05
            spawnX = planet.x + math.random(-200, 200)
            spawnY = planet.y + math.random(-200, 200)
            break
          end
        end
      elseif artifactDef.id == "explorer_log_1" then
        -- Random spawn far from origin
        local distFromOrigin = math.sqrt(player.x ^ 2 + player.y ^ 2)
        if distFromOrigin > 3000 then
          shouldSpawn = math.random() < 0.01
          spawnX = player.x + math.random(-1000, 1000)
          spawnY = player.y + math.random(-1000, 1000)
        end
      elseif artifactDef.id == "explorer_log_2" then
        -- Near warp zones
        local WarpZones = Utils.require("src.systems.warp_zones")
        if WarpZones and #WarpZones.activeZones > 0 then
          local zone = WarpZones.activeZones[1]
          shouldSpawn = math.random() < 0.02
          spawnX = zone.x + math.random(-300, 300)
          spawnY = zone.y + math.random(-300, 300)
        end
      elseif artifactDef.id == "final_truth" then
        -- Only spawn if all others collected
        if ArtifactSystem.collectedCount >= #ArtifactSystem.artifacts - 1 then
          shouldSpawn = true
          -- Spawn at a significant location
          spawnX = 0
          spawnY = -5000           -- Far "above" origin
        end
      end

      -- Spawn the artifact
      if shouldSpawn then
        local artifact = {
          x = spawnX,
          y = spawnY,
          id = artifactDef.id,
          definition = artifactDef,
          collected = false,
          glowRadius = 50,
          particles = {}
        }

        table.insert(ArtifactSystem.spawnedArtifacts, artifact)
        Utils.Logger.info("Artifact spawned: %s at (%.0f, %.0f)", artifactDef.name, spawnX, spawnY)
      end
    end
  end
end

-- Check if artifact is already spawned
function ArtifactSystem.isArtifactSpawned(id)
  for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
    if artifact.id == id then
      return true
    end
  end
  return false
end

-- Update artifacts
function ArtifactSystem.update(dt, player, planets)
  -- Update visual effects
  ArtifactSystem.pulsePhase = ArtifactSystem.pulsePhase + dt * 2
  ArtifactSystem.particleTimer = ArtifactSystem.particleTimer + dt

  -- Spawn new artifacts occasionally
  if math.random() < dt * 0.1 then   -- Check every ~10 seconds
    ArtifactSystem.spawnArtifacts(player, planets)
  end

  -- Update spawned artifacts
  for i = #ArtifactSystem.spawnedArtifacts, 1, -1 do
    local artifact = ArtifactSystem.spawnedArtifacts[i]

    if not artifact.collected then
      -- Check collection
      local dist = Utils.distance(player.x, player.y, artifact.x, artifact.y)
      if dist < artifact.glowRadius then
        ArtifactSystem.collectArtifact(artifact, i)
      end

      -- Update particles
      if ArtifactSystem.particleTimer > 0.1 then
        -- Add new particle
        local angle = math.random() * math.pi * 2
        local speed = math.random(20, 50)
        local particle = {
          x = artifact.x,
          y = artifact.y,
          vx = math.cos(angle) * speed,
          vy = math.sin(angle) * speed,
          life = 1.0,
          size = math.random(2, 4)
        }
        table.insert(artifact.particles, particle)
      end

      -- Update existing particles
      for j = #artifact.particles, 1, -1 do
        local p = artifact.particles[j]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt

        if p.life <= 0 then
          table.remove(artifact.particles, j)
        end
      end
    end
  end

  -- Reset particle timer
  if ArtifactSystem.particleTimer > 0.1 then
    ArtifactSystem.particleTimer = 0
  end

  -- Update notifications
  if #ArtifactSystem.notificationQueue > 0 then
    ArtifactSystem.notificationTimer = ArtifactSystem.notificationTimer - dt
    if ArtifactSystem.notificationTimer <= 0 then
      table.remove(ArtifactSystem.notificationQueue, 1)
      ArtifactSystem.notificationTimer = 5       -- Show each for 5 seconds
    end
  end
end

-- Collect an artifact
function ArtifactSystem.collectArtifact(artifact, index)
  artifact.collected = true
  artifact.definition.discovered = true
  ArtifactSystem.collectedCount = ArtifactSystem.collectedCount + 1

  -- Remove from spawned list
  table.remove(ArtifactSystem.spawnedArtifacts, index)

  -- Add to notification queue
  table.insert(ArtifactSystem.notificationQueue, {
    artifact = artifact.definition,
    time = love.timer.getTime()
  })
  ArtifactSystem.notificationTimer = 5

  -- Grant points
  local GameState = Utils.require("src.core.game_state")
  local UpgradeSystem = Utils.require("src.systems.upgrade_system")
  GameState.addScore(1000)
  UpgradeSystem.addCurrency(100)

  -- Achievement
  local AchievementSystem = Utils.require("src.systems.achievement_system")
  if AchievementSystem.onArtifactCollected then
    AchievementSystem.onArtifactCollected(artifact.id)
  end

  -- Play collection sound
  local soundManager = Utils.require("src.audio.sound_manager")
  if soundManager and soundManager.playEventWarning then
    soundManager:playEventWarning()
  end

  -- Check if all collected
  if ArtifactSystem.collectedCount >= #ArtifactSystem.artifacts then
    AchievementSystem.onAllArtifactsCollected()
  end

  Utils.Logger.info("Artifact collected: %s", artifact.definition.name)
end

-- Draw artifacts
function ArtifactSystem.draw()
  for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
    if not artifact.collected then
      local pulse = math.sin(ArtifactSystem.pulsePhase) * 0.2 + 1

      -- Draw glow
      Utils.setColor(artifact.definition.color, 0.2)
      love.graphics.circle("fill", artifact.x, artifact.y, artifact.glowRadius * pulse)

      -- Draw particles
      for _, p in ipairs(artifact.particles) do
        Utils.setColor(artifact.definition.color, p.life * 0.5)
        love.graphics.circle("fill", p.x, p.y, p.size * p.life)
      end

      -- Draw core
      Utils.setColor(artifact.definition.color, 0.8)
      love.graphics.push()
      love.graphics.translate(artifact.x, artifact.y)
      love.graphics.rotate(ArtifactSystem.pulsePhase)

      -- Crystal shape
      local size = 15 * pulse
      love.graphics.polygon("line",
        0, -size,
        size * 0.7, 0,
        0, size,
        -size * 0.7, 0
      )

      -- Inner crystal
      Utils.setColor(artifact.definition.color, 0.4)
      love.graphics.polygon("fill",
        0, -size * 0.6,
        size * 0.4, 0,
        0, size * 0.6,
        -size * 0.4, 0
      )

      love.graphics.pop()
    end
  end
end

-- Draw UI notifications
function ArtifactSystem.drawUI()
  if #ArtifactSystem.notificationQueue > 0 then
    local notification = ArtifactSystem.notificationQueue[1]
    local artifact = notification.artifact

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Fade in/out
    local alpha = 1.0
    if ArtifactSystem.notificationTimer > 4 then
      alpha = (5 - ArtifactSystem.notificationTimer)
    elseif ArtifactSystem.notificationTimer < 1 then
      alpha = ArtifactSystem.notificationTimer
    end

    -- Background box
    local boxWidth = 600
    local boxHeight = 200
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = 100

    Utils.setColor({ 0, 0, 0 }, 0.8 * alpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10)

    Utils.setColor(artifact.color, alpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10)

    -- Title
    Utils.setColor({ 1, 1, 1 }, alpha)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("ARTIFACT DISCOVERED", boxX, boxY + 20, boxWidth, "center")

    -- Name
    Utils.setColor(artifact.color, alpha)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf(artifact.name, boxX, boxY + 50, boxWidth, "center")

    -- Description
    Utils.setColor({ 0.8, 0.8, 0.8 }, alpha)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf(artifact.description, boxX + 20, boxY + 90, boxWidth - 40, "center")

    -- Progress
    Utils.setColor({ 0.5, 0.5, 0.5 }, alpha * 0.8)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf(
      ArtifactSystem.collectedCount .. " / " .. #ArtifactSystem.artifacts .. " Artifacts Collected",
      boxX, boxY + boxHeight - 30, boxWidth, "center"
    )
  end

  -- Collection progress (always visible)
  local progressY = 50
  Utils.setColor({ 1, 1, 1 }, 0.8)
  love.graphics.setFont(love.graphics.newFont(12))
  love.graphics.printf(
    "Artifacts: " .. ArtifactSystem.collectedCount .. "/" .. #ArtifactSystem.artifacts,
    love.graphics.getWidth() - 150, progressY, 140, "right"
  )
end

-- Get artifact by ID
function ArtifactSystem.getArtifact(id)
  for _, artifact in ipairs(ArtifactSystem.artifacts) do
    if artifact.id == id then
      return artifact
    end
  end
  return nil
end

-- Get all discovered artifacts
function ArtifactSystem.getDiscoveredArtifacts()
  local discovered = {}
  for _, artifact in ipairs(ArtifactSystem.artifacts) do
    if artifact.discovered then
      table.insert(discovered, artifact)
    end
  end
  return discovered
end

-- Show artifacts on map
function ArtifactSystem.drawOnMap(camera, mapCenterX, mapCenterY, scale, alpha)
  -- Draw spawned artifacts on map
  for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
    if not artifact.collected then
      local mapX = mapCenterX + (artifact.x - camera.x) * scale
      local mapY = mapCenterY + (artifact.y - camera.y) * scale

      -- Pulsing icon
      local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 1
      Utils.setColor(artifact.definition.color, 0.8 * alpha)

      -- Draw artifact marker
      love.graphics.push()
      love.graphics.translate(mapX, mapY)
      love.graphics.rotate(love.timer.getTime())
      love.graphics.polygon("line",
        0, -8 * pulse,
        6 * pulse, 0,
        0, 8 * pulse,
        -6 * pulse, 0
      )
      love.graphics.pop()
    end
  end
end

return ArtifactSystem
