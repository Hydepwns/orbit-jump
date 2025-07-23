-- Constants for Orbit Jump
local Constants = {}

Constants.GAME = {
    STARTING_SCORE = 0,
    MAX_COMBO = 100,
    RING_VALUE = 10,
    JUMP_POWER = 300,
    DASH_POWER = 500,
    GRAVITY = 15000,
    COMBO_TIMEOUT = 3.0
}

Constants.UI = {
    FONT_SIZE_REGULAR = 16,
    FONT_SIZE_BOLD = 16,
    FONT_SIZE_LIGHT = 16,
    FONT_SIZE_EXTRA_BOLD = 24,
    MAX_PULL_DISTANCE = 150
}

Constants.COLORS = {
    BACKGROUND = {0.05, 0.05, 0.1},
    WHITE = {1, 1, 1},
    RED = {1, 0, 0},
    GREEN = {0, 1, 0},
    BLUE = {0, 0, 1}
}

Constants.PERFORMANCE = {
    PARTICLE_LIMIT = 1000,
    SPATIAL_GRID_SIZE = 100,
    OBJECT_POOL_SIZE = 50
}

return Constants