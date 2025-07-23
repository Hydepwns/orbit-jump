-- Sound Manager for Orbit Jump
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
    local SoundGenerator = Utils.Utils.require("src.audio.sound_generator")
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
    
    local sound = self.sounds[soundName]
    
    -- Clone for concurrent playback
    if sound:isPlaying() then
        sound = sound:clone()
    end
    
    sound:setVolume((volume or 1.0) * self.volume)
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