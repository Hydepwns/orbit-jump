-- Sound generator for Orbit Jump
-- Generates simple synthesized sounds using LÖVE2D's audio capabilities

local SoundGenerator = {}

-- Generate a sine wave
function SoundGenerator.generateSineWave(frequency, duration, sampleRate)
    sampleRate = sampleRate or 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local sample = math.sin(2 * math.pi * frequency * t)
        soundData:setSample(i, sample)
    end
    
    return soundData
end

-- Generate a square wave
function SoundGenerator.generateSquareWave(frequency, duration, sampleRate)
    sampleRate = sampleRate or 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local sample = math.sin(2 * math.pi * frequency * t) > 0 and 0.3 or -0.3
        soundData:setSample(i, sample)
    end
    
    return soundData
end

-- Generate white noise
function SoundGenerator.generateNoise(duration, sampleRate)
    sampleRate = sampleRate or 44100
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local sample = (math.random() * 2 - 1) * 0.1
        soundData:setSample(i, sample)
    end
    
    return soundData
end

-- Apply an envelope to sound data (attack, decay, sustain, release)
function SoundGenerator.applyEnvelope(soundData, attack, decay, sustain, release)
    local samples = soundData:getSampleCount()
    local sampleRate = soundData:getSampleRate()
    
    local attackSamples = math.floor(attack * sampleRate)
    local decaySamples = math.floor(decay * sampleRate)
    local releaseSamples = math.floor(release * sampleRate)
    local sustainSamples = samples - attackSamples - decaySamples - releaseSamples
    
    for i = 0, samples - 1 do
        local envelope = 1.0
        
        if i < attackSamples then
            -- Attack phase
            envelope = i / attackSamples
        elseif i < attackSamples + decaySamples then
            -- Decay phase
            local decayProgress = (i - attackSamples) / decaySamples
            envelope = 1.0 - (1.0 - sustain) * decayProgress
        elseif i < attackSamples + decaySamples + sustainSamples then
            -- Sustain phase
            envelope = sustain
        else
            -- Release phase
            local releaseProgress = (i - attackSamples - decaySamples - sustainSamples) / releaseSamples
            envelope = sustain * (1.0 - releaseProgress)
        end
        
        local sample = soundData:getSample(i) * envelope
        soundData:setSample(i, sample)
    end
    
    return soundData
end

-- Generate game sounds
function SoundGenerator.generateGameSounds()
    local sounds = {}
    
    -- Jump sound - rising pitch sweep
    local jumpData = love.sound.newSoundData(math.floor(0.3 * 44100), 44100, 16, 1)
    for i = 0, jumpData:getSampleCount() - 1 do
        local t = i / 44100
        local freq = 200 + (600 * t) -- Sweep from 200Hz to 800Hz
        local sample = math.sin(2 * math.pi * freq * t) * (1 - t) * 0.3
        jumpData:setSample(i, sample)
    end
    sounds.jump = love.audio.newSource(jumpData, "static")
    
    -- Ring collect - pleasant chime
    local ringData = love.sound.newSoundData(math.floor(0.4 * 44100), 44100, 16, 1)
    for i = 0, ringData:getSampleCount() - 1 do
        local t = i / 44100
        -- Multiple harmonics for richness
        local sample = (
            math.sin(2 * math.pi * 523.25 * t) * 0.5 +  -- C5
            math.sin(2 * math.pi * 659.25 * t) * 0.3 +  -- E5
            math.sin(2 * math.pi * 783.99 * t) * 0.2    -- G5
        ) * math.exp(-t * 3) * 0.3
        ringData:setSample(i, sample)
    end
    sounds.ring = love.audio.newSource(ringData, "static")
    
    -- Dash sound - whoosh effect
    local dashData = love.sound.newSoundData(math.floor(0.2 * 44100), 44100, 16, 1)
    for i = 0, dashData:getSampleCount() - 1 do
        local t = i / 44100
        -- Filtered noise for whoosh
        local noise = (math.random() * 2 - 1)
        local freq = 800 * (1 - t) + 200 -- Sweep down
        local sample = noise * math.sin(2 * math.pi * freq * t) * math.exp(-t * 10) * 0.2
        dashData:setSample(i, sample)
    end
    sounds.dash = love.audio.newSource(dashData, "static")
    
    -- Land on planet - soft thud
    local landData = love.sound.newSoundData(math.floor(0.15 * 44100), 44100, 16, 1)
    for i = 0, landData:getSampleCount() - 1 do
        local t = i / 44100
        -- Low frequency with quick decay
        local sample = math.sin(2 * math.pi * 80 * t) * math.exp(-t * 20) * 0.4
        landData:setSample(i, sample)
    end
    sounds.land = love.audio.newSource(landData, "static")
    
    -- Combo sound - ascending notes
    local comboData = love.sound.newSoundData(math.floor(0.3 * 44100), 44100, 16, 1)
    for i = 0, comboData:getSampleCount() - 1 do
        local t = i / 44100
        local note = math.floor(t * 4) -- 4 quick notes
        local freqs = {523.25, 587.33, 659.25, 783.99} -- C, D, E, G
        local freq = freqs[math.min(note + 1, 4)]
        local sample = math.sin(2 * math.pi * freq * t) * math.exp(-t * 2) * 0.25
        comboData:setSample(i, sample)
    end
    sounds.combo = love.audio.newSource(comboData, "static")
    
    -- Game over sound - descending tones
    local gameOverData = love.sound.newSoundData(math.floor(1.0 * 44100), 44100, 16, 1)
    for i = 0, gameOverData:getSampleCount() - 1 do
        local t = i / 44100
        local freq = 400 * math.exp(-t * 0.5) -- Exponential decay in frequency
        local sample = math.sin(2 * math.pi * freq * t) * math.exp(-t * 1) * 0.3
        gameOverData:setSample(i, sample)
    end
    sounds.gameOver = love.audio.newSource(gameOverData, "static")
    
    -- Ambient space hum
    local ambientData = love.sound.newSoundData(math.floor(2.0 * 44100), 44100, 16, 1)
    for i = 0, ambientData:getSampleCount() - 1 do
        local t = i / 44100
        -- Very low frequency with slight variation
        local sample = (
            math.sin(2 * math.pi * 50 * t) * 0.05 +
            math.sin(2 * math.pi * 75 * t) * 0.03 +
            math.sin(2 * math.pi * 100 * t + math.sin(t * 0.5)) * 0.02
        )
        ambientData:setSample(i, sample)
    end
    sounds.ambient = love.audio.newSource(ambientData, "stream")
    sounds.ambient:setLooping(true)
    sounds.ambient:setVolume(0.2)
    
    return sounds
end

return SoundGenerator