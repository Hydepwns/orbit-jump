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
    -- Generate addiction feature sounds
    SoundGenerator.generateAddictionSounds(sounds)
    return sounds
end
-- Generate addiction feature sounds
function SoundGenerator.generateAddictionSounds(sounds)
    -- Level Up - Triumphant fanfare
    local levelUpData = love.sound.newSoundData(math.floor(1.0 * 44100), 44100, 16, 1)
    for i = 0, levelUpData:getSampleCount() - 1 do
        local t = i / 44100
        -- Ascending chord progression: C-E-G-C
        local phase = t * 4 -- 4 notes over 1 second
        local noteIndex = math.min(math.floor(phase), 3)
        local freqs = {523.25, 659.25, 783.99, 1046.50} -- C5, E5, G5, C6
        local freq = freqs[noteIndex + 1]
        -- Add harmonics for richness
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.4 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.2 +
            math.sin(2 * math.pi * freq * 3 * t) * 0.1
        ) * math.exp(-t * 1.5) * 0.5
        levelUpData:setSample(i, sample)
    end
    sounds.levelUp = love.audio.newSource(levelUpData, "static")
    -- Level Up Major - Extended celebration
    local levelUpMajorData = love.sound.newSoundData(math.floor(1.5 * 44100), 44100, 16, 1)
    for i = 0, levelUpMajorData:getSampleCount() - 1 do
        local t = i / 44100
        -- Full major chord with arpeggios
        local phase = t * 6 -- 6 notes over 1.5 seconds
        local noteIndex = math.min(math.floor(phase), 5)
        local freqs = {523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98} -- C-E-G-C-E-G
        local freq = freqs[noteIndex + 1]
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.5 +
            math.sin(2 * math.pi * freq * 1.5 * t) * 0.25
        ) * math.exp(-t * 1.0) * 0.4
        levelUpMajorData:setSample(i, sample)
    end
    sounds.levelUpMajor = love.audio.newSource(levelUpMajorData, "static")
    -- Perfect Landing - Satisfying ding with pitch scaling
    local perfectLandingData = love.sound.newSoundData(math.floor(0.5 * 44100), 44100, 16, 1)
    for i = 0, perfectLandingData:getSampleCount() - 1 do
        local t = i / 44100
        -- Bell-like sound with harmonics
        local fundamental = 800
        local sample = (
            math.sin(2 * math.pi * fundamental * t) * 0.6 +
            math.sin(2 * math.pi * fundamental * 2 * t) * 0.3 +
            math.sin(2 * math.pi * fundamental * 3 * t) * 0.1
        ) * math.exp(-t * 6) * 0.4
        perfectLandingData:setSample(i, sample)
    end
    sounds.perfectLanding = love.audio.newSource(perfectLandingData, "static")
    -- Streak Milestone Sounds
    -- Minor milestone (5-20 streak)
    local streakMinorData = love.sound.newSoundData(math.floor(0.6 * 44100), 44100, 16, 1)
    for i = 0, streakMinorData:getSampleCount() - 1 do
        local t = i / 44100
        local freq = 659.25 -- E5
        local sample = math.sin(2 * math.pi * freq * t) * math.exp(-t * 4) * 0.4
        streakMinorData:setSample(i, sample)
    end
    sounds.streakMinor = love.audio.newSource(streakMinorData, "static")
    -- Major milestone (25-45 streak)
    local streakMajorData = love.sound.newSoundData(math.floor(0.8 * 44100), 44100, 16, 1)
    for i = 0, streakMajorData:getSampleCount() - 1 do
        local t = i / 44100
        -- Two-note celebration
        local phase = t * 3
        local freq = phase < 1.5 and 659.25 or 783.99 -- E5 then G5
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.5 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.2
        ) * math.exp(-t * 3) * 0.45
        streakMajorData:setSample(i, sample)
    end
    sounds.streakMajor = love.audio.newSource(streakMajorData, "static")
    -- Epic milestone (50-95 streak)
    local streakEpicData = love.sound.newSoundData(math.floor(1.0 * 44100), 44100, 16, 1)
    for i = 0, streakEpicData:getSampleCount() - 1 do
        local t = i / 44100
        -- Three-note ascending celebration
        local phase = t * 4
        local noteIndex = math.min(math.floor(phase), 2)
        local freqs = {659.25, 783.99, 1046.50} -- E5-G5-C6
        local freq = freqs[noteIndex + 1]
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.6 +
            math.sin(2 * math.pi * freq * 1.5 * t) * 0.3
        ) * math.exp(-t * 2) * 0.5
        streakEpicData:setSample(i, sample)
    end
    sounds.streakEpic = love.audio.newSource(streakEpicData, "static")
    -- Legendary milestone (100+ streak)
    local streakLegendaryData = love.sound.newSoundData(math.floor(1.5 * 44100), 44100, 16, 1)
    for i = 0, streakLegendaryData:getSampleCount() - 1 do
        local t = i / 44100
        -- Full orchestral-style celebration
        local phase = t * 6
        local noteIndex = math.min(math.floor(phase), 5)
        local freqs = {523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98}
        local freq = freqs[noteIndex + 1]
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.7 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.4 +
            math.sin(2 * math.pi * freq * 3 * t) * 0.2
        ) * math.exp(-t * 1.2) * 0.6
        streakLegendaryData:setSample(i, sample)
    end
    sounds.streakLegendary = love.audio.newSource(streakLegendaryData, "static")
    -- Streak Break - Dramatic descending sound
    local streakBreakData = love.sound.newSoundData(math.floor(1.2 * 44100), 44100, 16, 1)
    for i = 0, streakBreakData:getSampleCount() - 1 do
        local t = i / 44100
        -- Descending chromatic sequence with dissonance
        local freq = 600 * math.exp(-t * 2) -- Exponential frequency decay
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.6 +
            math.sin(2 * math.pi * freq * 1.1 * t) * 0.3 -- Slight dissonance
        ) * (1 - math.exp(-t * 8)) * math.exp(-t * 0.8) * 0.5
        streakBreakData:setSample(i, sample)
    end
    sounds.streakBreak = love.audio.newSource(streakBreakData, "static")
    -- Grace Period - Heartbeat-style urgent pulses
    local gracePeriodData = love.sound.newSoundData(math.floor(0.8 * 44100), 44100, 16, 1)
    for i = 0, gracePeriodData:getSampleCount() - 1 do
        local t = i / 44100
        -- Double pulse like heartbeat
        local pulseRate = 2.5 -- Heartbeat-like rhythm
        local pulse = math.sin(2 * math.pi * pulseRate * t)
        pulse = pulse > 0 and (pulse ^ 0.3) or 0 -- Sharp attack, quick decay
        local freq = 200 + pulse * 400 -- Frequency modulation
        local sample = math.sin(2 * math.pi * freq * t) * pulse * 0.4
        gracePeriodData:setSample(i, sample)
    end
    sounds.gracePeriod = love.audio.newSource(gracePeriodData, "static")
    -- Streak Saved - Relief and celebration
    local streakSavedData = love.sound.newSoundData(math.floor(0.8 * 44100), 44100, 16, 1)
    for i = 0, streakSavedData:getSampleCount() - 1 do
        local t = i / 44100
        -- Rising then settling melody
        local freq = 400 + 400 * math.sin(t * 3) * math.exp(-t * 1.5)
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.5 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.25
        ) * math.exp(-t * 2) * 0.45
        streakSavedData:setSample(i, sample)
    end
    sounds.streakSaved = love.audio.newSource(streakSavedData, "static")
    -- Mystery Box Spawn - Anticipation buildup
    local mysteryBoxSpawnData = love.sound.newSoundData(math.floor(1.0 * 44100), 44100, 16, 1)
    for i = 0, mysteryBoxSpawnData:getSampleCount() - 1 do
        local t = i / 44100
        -- Rising tension with sparkle effect
        local freq = 300 + t * 200 -- Rising frequency
        local sparkle = math.sin(2 * math.pi * 2000 * t) * math.exp(-t * 3) * 0.1
        local sample = (
            math.sin(2 * math.pi * freq * t) * (t * 2) * 0.4 + sparkle
        ) * 0.5
        mysteryBoxSpawnData:setSample(i, sample)
    end
    sounds.mysteryBoxSpawn = love.audio.newSource(mysteryBoxSpawnData, "static")
    -- Mystery Box Opening Sounds (by rarity)
    -- Bronze
    local bronzeData = love.sound.newSoundData(math.floor(0.6 * 44100), 44100, 16, 1)
    for i = 0, bronzeData:getSampleCount() - 1 do
        local t = i / 44100
        local freq = 440 -- A4
        local sample = math.sin(2 * math.pi * freq * t) * math.exp(-t * 4) * 0.4
        bronzeData:setSample(i, sample)
    end
    sounds.mysteryBoxBronze = love.audio.newSource(bronzeData, "static")
    -- Silver - richer sound
    local silverData = love.sound.newSoundData(math.floor(0.7 * 44100), 44100, 16, 1)
    for i = 0, silverData:getSampleCount() - 1 do
        local t = i / 44100
        local freq = 523.25 -- C5
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.6 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.2
        ) * math.exp(-t * 3.5) * 0.45
        silverData:setSample(i, sample)
    end
    sounds.mysteryBoxSilver = love.audio.newSource(silverData, "static")
    -- Gold - even richer with harmonics
    local goldData = love.sound.newSoundData(math.floor(0.8 * 44100), 44100, 16, 1)
    for i = 0, goldData:getSampleCount() - 1 do
        local t = i / 44100
        local freq = 659.25 -- E5
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.6 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.3 +
            math.sin(2 * math.pi * freq * 3 * t) * 0.1
        ) * math.exp(-t * 3) * 0.5
        goldData:setSample(i, sample)
    end
    sounds.mysteryBoxGold = love.audio.newSource(goldData, "static")
    -- Legendary - majestic fanfare
    local legendaryData = love.sound.newSoundData(math.floor(1.2 * 44100), 44100, 16, 1)
    for i = 0, legendaryData:getSampleCount() - 1 do
        local t = i / 44100
        -- Complex chord progression
        local phase = t * 4
        local noteIndex = math.min(math.floor(phase), 3)
        local freqs = {523.25, 659.25, 783.99, 1046.50}
        local freq = freqs[noteIndex + 1]
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.7 +
            math.sin(2 * math.pi * freq * 1.5 * t) * 0.4 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.3
        ) * math.exp(-t * 1.5) * 0.6
        legendaryData:setSample(i, sample)
    end
    sounds.mysteryBoxLegendary = love.audio.newSource(legendaryData, "static")
    -- Random Event Sounds
    -- Ring Rain - cascading chimes
    local ringRainData = love.sound.newSoundData(math.floor(0.8 * 44100), 44100, 16, 1)
    for i = 0, ringRainData:getSampleCount() - 1 do
        local t = i / 44100
        -- Multiple overlapping bell tones
        local sample = 0
        for j = 1, 5 do
            local freq = 800 + j * 200
            local delay = (j - 1) * 0.1
            if t > delay then
                sample = sample + math.sin(2 * math.pi * freq * (t - delay)) *
                         math.exp(-(t - delay) * 8) * 0.2
            end
        end
        ringRainData:setSample(i, sample * 0.8)
    end
    sounds.eventRingRain = love.audio.newSource(ringRainData, "static")
    -- Gravity Well - deep pulsing
    local gravityWellData = love.sound.newSoundData(math.floor(1.0 * 44100), 44100, 16, 1)
    for i = 0, gravityWellData:getSampleCount() - 1 do
        local t = i / 44100
        -- Deep thrumming with harmonic overtones
        local freq = 60 -- Very low frequency
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.8 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.4 +
            math.sin(2 * math.pi * freq * 4 * t) * 0.2
        ) * (1 - math.exp(-t * 3)) * math.exp(-t * 0.8) * 0.6
        gravityWellData:setSample(i, sample)
    end
    sounds.eventGravityWell = love.audio.newSource(gravityWellData, "static")
    -- Time Dilation - ethereal sweep
    local timeDilationData = love.sound.newSoundData(math.floor(1.2 * 44100), 44100, 16, 1)
    for i = 0, timeDilationData:getSampleCount() - 1 do
        local t = i / 44100
        -- Sweeping frequency with reverb-like effect
        local freq = 400 + 800 * math.sin(t * 0.5) -- Slow frequency modulation
        local sample = math.sin(2 * math.pi * freq * t) *
                      math.sin(2 * math.pi * freq * t * 1.01) * -- Slight detuning for chorus effect
                      (1 - math.exp(-t * 2)) * math.exp(-t * 0.6) * 0.5
        timeDilationData:setSample(i, sample)
    end
    sounds.eventTimeDilation = love.audio.newSource(timeDilationData, "static")
    -- XP Gain - satisfying chime
    local xpGainData = love.sound.newSoundData(math.floor(0.3 * 44100), 44100, 16, 1)
    for i = 0, xpGainData:getSampleCount() - 1 do
        local t = i / 44100
        -- Simple but satisfying bell tone
        local freq = 1000
        local sample = (
            math.sin(2 * math.pi * freq * t) * 0.6 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.2
        ) * math.exp(-t * 8) * 0.4
        xpGainData:setSample(i, sample)
    end
    sounds.xpGain = love.audio.newSource(xpGainData, "static")
end
return SoundGenerator