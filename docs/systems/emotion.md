# emotion system

the emotion system transforms mechanical interactions into emotionally resonant experiences through adaptive feedback and mood management.

## overview

the emotion system creates joy by recognizing player achievements, building emotional momentum, and providing layered multisensory feedback. it remembers special moments and adapts its responses to create a personalized emotional journey.

## architecture

```
emotional_feedback.lua (main facade)
    ├── emotion_core.lua (state & transitions)
    ├── feedback_renderer.lua (visual/audio/haptic)
    └── emotion_analytics.lua (pattern tracking)
```

## core concepts

### emotional state

tracks the player's current emotional trajectory:

- **confidence** (0-1) - how confident the player feels
- **momentum** (-1 to 1) - current emotional direction
- **achievement streak** - recent successes in a row
- **flow state duration** - uninterrupted play time
- **surprise cooldown** - prevents feedback fatigue

### mood system

dynamic mood states that influence feedback:

- **neutral** - baseline state
- **excited** - after discoveries or achievements
- **triumphant** - major accomplishments
- **powerful** - successful emergency maneuvers
- **determined** - after setbacks
- **perfect** - flawless execution
- **smooth** - graceful gameplay
- **intense** - high-stakes moments
- **energetic** - active play periods

### emotional memory

remembers significant player moments:

- first successful jump
- longest combo chains
- highest speeds achieved
- perfect landings count
- dramatic saves
- exploration milestones

## api reference

### initialization

```lua
-- initialize emotion system
EmotionalFeedback.init()
```

### event processing

```lua
-- process emotional events
EmotionalFeedback.processEvent(eventType, params)
-- eventTypes: "landing", "jump", "dash", "achievement", 
--            "failure", "combo", "near_miss", "discovery"

-- example: landing event
EmotionalFeedback.processEvent("landing", {
    player = player,
    planet = planet,
    speed = landingSpeed,
    isGentle = speed < 100
})

-- example: achievement event
EmotionalFeedback.processEvent("achievement", {
    type = "first_warp"
})
```

### specific event handlers

```lua
-- track jump with emotional feedback
local intensity = EmotionalFeedback.onJump(
    pullPower,    -- 0-1 scale
    jumpSuccess,  -- boolean
    isFirstJump   -- boolean
)

-- track landing quality
local intensity = EmotionalFeedback.onLanding(
    player,       -- player object
    planet,       -- planet object
    landingSpeed, -- pixels/second
    isGentle      -- boolean
)

-- track dash maneuver
local intensity = EmotionalFeedback.onDash(
    isEmergency,  -- boolean
    dashSuccess   -- boolean
)

-- handle failure gracefully
local intensity = EmotionalFeedback.onFailure(
    failureType   -- "jump_blocked", "dash_failed", etc
)
```

### special celebrations

```lua
-- trigger milestone celebration
EmotionalFeedback.triggerSpecialCelebration(achievementType)
-- types: "first_jump", "perfect_landing", "discovery"
```

### state access

```lua
-- get current emotional state
local state = EmotionalFeedback.getEmotionalState()
-- returns: {
--   confidence = 0.75,
--   momentum = 0.3,
--   streak = 5,
--   flow_duration = 120.5
-- }

-- get emotional memory
local memory = EmotionalFeedback.getEmotionalMemory()

-- get current mood
local mood = EmotionalFeedback.currentMood
-- returns: { type = "excited", intensity = 0.8 }
```

### update loop

```lua
-- update emotion systems (call each frame)
EmotionalFeedback.update(dt)
```

## feedback layers

### visual feedback

- particle effects scaled to emotional intensity
- screen effects (shake, flash, bloom)
- color shifts based on mood
- celebration bursts for special moments

### audio feedback

- dynamic pitch adjustment
- layered sound effects
- musical stingers for achievements
- ambient mood reinforcement

### haptic feedback

- controller vibration patterns
- intensity matched to actions
- special patterns for perfect execution

### camera feedback

- smooth zooms for focus moments
- dramatic angles for achievements
- shake for intense moments
- slow motion for perfect timing

## configuration

key parameters in `emotion_core.lua`:

### action configurations

```lua
jump = {
    baseIntensity = 0.3,
    powerMultiplier = 0.7,
    maxIntensity = 1.0
}

landing = {
    baseIntensity = 0.4,
    speedMultiplier = 0.6,
    perfectBonus = 0.3,
    gentleBonus = 0.2
}

dash = {
    baseIntensity = 0.6,
    emergencyBonus = 0.4
}
```

### decay rates

- `CONFIDENCE_DECAY = 0.1/sec` - return to neutral
- `MOMENTUM_DECAY = 0.8/sec` - emotional settling
- `MOOD_DECAY = 0.2/sec` - mood intensity fade

## integration points

### with analytics

```lua
-- analytics tracks emotional patterns
PlayerAnalytics.onEmotionalEvent(
    "success",    -- event type
    0.8,         -- intensity
    "perfect_landing" -- context
)
```

### with achievements

```lua
-- achievements trigger celebrations
function onAchievementUnlocked(achievement)
    EmotionalFeedback.processEvent("achievement", {
        type = achievement.id
    })
end
```

### with warp system

```lua
-- warp detects emergency situations
local emergencyFactor = detectEmergency(gameContext)
if emergencyFactor > 0.5 then
    -- emotion system provides compassionate response
end
```

## design philosophy

1. **layered feedback** - multiple channels reinforce emotions
2. **progressive intensity** - better actions feel more satisfying
3. **emotional memory** - system remembers and builds on achievements
4. **surprise and delight** - unexpected positive moments
5. **flow protection** - never interrupt player focus
6. **gentle failures** - disappointment without punishment

## performance considerations

- pre-allocated feedback configurations
- object pooling for particles
- throttled celebration frequency
- efficient mood transitions
- minimal allocations during gameplay

## troubleshooting

**no emotional feedback**

- verify `EmotionalFeedback.init()` called
- check event processing is active
- ensure update loop running

**feedback fatigue**

- surprise cooldown prevents spam
- celebration throttling active
- mood decay brings balance

**mood stuck**

- check update loop dt values
- verify mood decay rates
- ensure state transitions firing
