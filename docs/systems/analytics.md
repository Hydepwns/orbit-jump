# analytics system

the analytics system observes and learns from player behavior to provide personalized insights and adaptive gameplay experiences.

## overview

the analytics system is a comprehensive player observation framework that tracks behaviors, recognizes patterns, and generates actionable insights. it operates transparently and compassionately to enhance the player experience without being intrusive.

## architecture

```
player_analytics.lua (main interface)
    ├── behavior_tracker.lua (movement & action tracking)
    ├── pattern_analyzer.lua (pattern recognition)
    └── insight_generator.lua (insight generation & reporting)
```

## core components

### behavior tracker

tracks and analyzes player actions:

- **movement patterns** - jump power preferences, planning time, spatial awareness
- **exploration style** - methodical, chaotic, or balanced approaches
- **skill progression** - mastery levels and learning curves
- **risk tolerance** - conservative to adventurous playstyles

### pattern analyzer

recognizes behavioral patterns:

- **session analysis** - playtime patterns and engagement levels
- **emotional states** - mood inference from gameplay behavior
- **skill development** - tracks improvement over time
- **learning curves** - identifies when players master mechanics

### insight generator

produces actionable insights:

- **player profiles** - comprehensive behavior summaries
- **system recommendations** - difficulty adjustments and feature suggestions
- **performance metrics** - detailed gameplay statistics
- **session reports** - per-session activity summaries

## tracked metrics

### movement profile

```lua
{
    preferredJumpPower,      -- average power used (0-100)
    jumpPowerVariance,       -- consistency measure
    averageJumpDistance,     -- spatial preferences
    riskTolerance,          -- 0-1 scale
    planningTime,           -- seconds between jumps
    spatialMastery,         -- overall skill (0-1)
    totalJumps,
    efficientPaths,         -- direct routes taken
    creativePaths           -- interesting alternatives
}
```

### exploration profile

```lua
{
    explorationStyle,       -- "methodical", "chaotic", "balanced"
    newPlanetSuccesses,     -- planets discovered
    explorationEfficiency,  -- success rate
    explorationRadius,      -- typical range from start
    expansionRate,         -- territory growth speed
    comfortZoneSize        -- preferred play area
}
```

### emotional profile

```lua
{
    currentMood,           -- inferred emotional state
    moodHistory,           -- recent mood changes
    frustrationLevel,      -- 0-1 scale
    satisfactionLevel,     -- 0-1 scale
    emotionalResilience    -- bounce-back ability
}
```

## api reference

### initialization

```lua
-- initialize analytics system
PlayerAnalytics.init()

-- check if tracking is active
local isTracking = PlayerAnalytics.isTracking
```

### event tracking

```lua
-- track player jump
PlayerAnalytics.onPlayerJump(
    jumpPower,      -- 0-100
    jumpAngle,      -- radians
    startX, startY, -- origin position
    targetX, targetY, -- target position
    planningTime    -- seconds spent planning
)

-- track planet discovery
PlayerAnalytics.onPlanetDiscovered(
    planet,         -- planet object
    discoveryMethod, -- "jump", "warp", etc
    attemptsToReach -- number of attempts
)

-- track emotional event
PlayerAnalytics.onEmotionalEvent(
    eventType,      -- "success", "failure", "frustration"
    intensity,      -- 0-1 scale
    context         -- situational context
)

-- track generic event
PlayerAnalytics.trackEvent(eventName, params)

-- track gameplay metrics
PlayerAnalytics.trackGameplay({
    action = "jump",  -- or "landing", "dash", etc
    ...params
})

-- track progression
PlayerAnalytics.trackProgression({
    type = "achievement",
    value = "first_warp"
})
```

### data retrieval

```lua
-- get player profile with insights
local profile = PlayerAnalytics.getPlayerProfile()
-- returns: {
--   playstyle = "methodical",
--   skillLevel = "intermediate",
--   preferences = {...},
--   strengths = {...},
--   challenges = {...}
-- }

-- get system recommendations
local recommendations = PlayerAnalytics.getSystemRecommendations()
-- returns: {
--   difficulty = "increase",
--   features = ["advanced_mechanics"],
--   ui = ["simplify_hud"]
-- }

-- get session report
local report = PlayerAnalytics.getSessionReport()

-- get comprehensive summary
local summary = PlayerAnalytics.getSummary()
```

### persistence

```lua
-- save analytics data
PlayerAnalytics.saveAnalyticsData()

-- data is automatically restored on init
```

## integration examples

### with emotion system

```lua
-- emotion system notifies analytics of emotional events
function onPlayerFrustrated(intensity)
    PlayerAnalytics.onEmotionalEvent("frustration", intensity, "repeated_failure")
end
```

### with achievement system

```lua
-- achievements trigger analytics events
function onAchievementUnlocked(achievement)
    PlayerAnalytics.trackAchievement(achievement)
end
```

### with warp system

```lua
-- warp system uses analytics for adaptive pricing
function calculateWarpCost(distance, player, gameContext)
    -- analytics provides player skill level for cost adjustment
    local profile = PlayerAnalytics.getPlayerProfile()
    -- ... adjust cost based on profile
end
```

## privacy and ethics

the analytics system operates with these principles:

- **transparency** - players can see what's tracked
- **compassion** - data used only to improve experience
- **no judgment** - all playstyles are valid
- **local storage** - data never leaves the device
- **opt-out option** - tracking can be disabled

## performance considerations

- event batching to reduce overhead
- async saving to prevent frame drops
- memory limits on historical data
- efficient data structures for real-time analysis

## configuration

key parameters in `player_analytics.lua`:

- `trackingEnabled = true` - master enable/disable
- `sessionTimeout = 300` - seconds before new session
- `maxEventHistory = 1000` - event storage limit

## troubleshooting

**analytics not tracking**

- verify `PlayerAnalytics.init()` called at startup
- check `isTracking` status
- ensure save system is functional

**missing insights**

- minimum 10 jumps required for movement analysis
- session must be >60 seconds for meaningful data
- some insights require multiple sessions

**performance impact**

- disable in performance mode
- reduce event history limit
- increase save interval
