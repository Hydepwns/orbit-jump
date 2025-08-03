-- Sound Manager for Orbit Jump
local Utils = require("src.utils.utils")
local SoundManager = {}
SoundManager.__index = SoundManager
function SoundManager:new()
    local self = setmetatable({}, SoundManager)
    self.sounds = {}
    self.enabled = true
    self.volume = 1.0
    return self
end
function SoundManager:load()
    local SoundGenerator = Utils.require("src.audio.sound_generator")
    self.sounds = SoundGenerator.generateGameSounds()
    -- Start ambient sound
    if self.sounds.ambient then
        self.sounds.ambient:play()
    end
end
function SoundManager:play(soundName, volume, pitch)
    if not self.enabled or not self.sounds[soundName] then
        return
    end
    -- Check config for audio feedback level
    local Config = require("src.utils.config")
    local feedbackScale = Config and Config.getAudioFeedbackScale() or 1.0
    local sound = self.sounds[soundName]
    -- Clone for concurrent playback
    if sound:isPlaying() then
        sound = sound:clone()
    end
    sound:setVolume((volume or 1.0) * self.volume * feedbackScale)
    sound:setPitch(pitch or 1.0)
    sound:play()
    return sound
end
function SoundManager:playJump()
    self:play("jump", 0.7)
end
function SoundManager:playRingCollect(combo)
    -- Higher pitch for higher combos
    local pitch = 1.0 + (combo * 0.1)
    self:play("ring", 0.8, math.min(pitch, 2.0))
    -- Play combo sound on milestones
    if combo > 0 and combo % 5 == 0 then
        self:play("combo", 0.6)
    end
end
function SoundManager:playDash()
    self:play("dash", 0.6)
end
function SoundManager:playLand()
    self:play("land", 0.5)
end
function SoundManager:playGameOver()
    self:play("gameOver", 0.8)
    -- Stop ambient sound
    if self.sounds.ambient then
        self.sounds.ambient:stop()
    end
end
function SoundManager:playEventWarning()
    -- Use the combo sound at a lower pitch for warnings
    self:play("combo", 0.9, 0.7)
end
function SoundManager:restartAmbient()
    if self.sounds.ambient and not self.sounds.ambient:isPlaying() then
        self.sounds.ambient:play()
    end
end
-- Addiction Features Sound Effects
function SoundManager:playLevelUp(level)
    -- Play ascending fanfare based on level importance
    local pitch = 1.0 + (level % 10) * 0.05 -- Slight pitch variation every 10 levels
    self:play("levelUp", 0.9, pitch)
    -- Major milestones get extra celebration
    if level % 10 == 0 then
        self:play("levelUpMajor", 0.8, 1.0)
    end
end
function SoundManager:playPerfectLanding(streakCount)
    -- Pitch scales with streak count for building tension
    local pitch = math.min(1.0 + (streakCount * 0.02), 2.0)
    self:play("perfectLanding", 0.7, pitch)
end
function SoundManager:playStreakMilestone(milestone)
    -- Different sounds for different milestone tiers
    if milestone >= 100 then
        self:play("streakLegendary", 1.0) -- Ultimate milestone
    elseif milestone >= 50 then
        self:play("streakEpic", 0.9) -- Epic milestone
    elseif milestone >= 25 then
        self:play("streakMajor", 0.8) -- Major milestone
    else
        self:play("streakMinor", 0.7) -- Minor milestone
    end
end
function SoundManager:playStreakBreak(brokenStreak)
    -- More dramatic sound for higher broken streaks
    local volume = math.min(0.5 + (brokenStreak * 0.01), 1.0)
    self:play("streakBreak", volume)
end
function SoundManager:playGracePeriod()
    -- Heartbeat-style urgent pulses
    self:play("gracePeriod", 0.6, 1.0)
end
function SoundManager:playStreakSaved()
    -- Relief and celebration sound
    self:play("streakSaved", 0.8, 1.0)
end
function SoundManager:playMysteryBoxSpawn()
    -- Anticipation buildup
    self:play("mysteryBoxSpawn", 0.7, 1.0)
end
function SoundManager:playMysteryBoxOpen(rarity)
    -- Different sounds for different box rarities
    if rarity == "legendary" then
        self:play("mysteryBoxLegendary", 1.0)
    elseif rarity == "gold" then
        self:play("mysteryBoxGold", 0.9)
    elseif rarity == "silver" then
        self:play("mysteryBoxSilver", 0.8)
    else
        self:play("mysteryBoxBronze", 0.7)
    end
end
function SoundManager:playRandomEvent(eventType)
    -- Event-specific audio signatures
    if eventType == "ring_rain" then
        self:play("eventRingRain", 0.8)
    elseif eventType == "gravity_well" then
        self:play("eventGravityWell", 0.8)
    elseif eventType == "time_dilation" then
        self:play("eventTimeDilation", 0.8)
    end
end
function SoundManager:playXPGain(amount, importance)
    -- Different sounds based on XP importance
    local volume = importance == "high" and 0.8 or (importance == "medium" and 0.6 or 0.4)
    local pitch = importance == "high" and 1.2 or (importance == "medium" and 1.1 or 1.0)
    self:play("xpGain", volume, pitch)
end
function SoundManager:setEnabled(enabled)
    self.enabled = enabled
    if not enabled then
        -- Stop all sounds
        for _, sound in pairs(self.sounds) do
            sound:stop()
        end
    elseif self.sounds.ambient then
        self.sounds.ambient:play()
    end
end
function SoundManager:setVolume(volume)
    self.volume = math.max(0, math.min(1, volume))
    -- Update ambient volume
    if self.sounds.ambient then
        self.sounds.ambient:setVolume(0.2 * self.volume)
    end
end
function SoundManager:update(dt)
    -- Could add sound queue management here if needed
end
return SoundManager