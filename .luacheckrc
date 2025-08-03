-- Luacheck configuration for Orbit Jump
-- Standard Lua 5.3+ with LÖVE2D support

std = "lua53+love"

-- Allow globals used by the game
globals = {
    "Game",
    "GameState", 
    "GameCamera",
    "Utils",
    "Config",
    "love",
    "_G",
    "TestFramework",  -- For tests
    "Mocks"          -- For tests
}

-- Read-only globals (standard Lua + LÖVE2D)
read_globals = {
    "require",
    "pcall",
    "xpcall",
    "error",
    "assert",
    "pairs",
    "ipairs",
    "next",
    "tostring",
    "tonumber",
    "type",
    "setmetatable",
    "getmetatable",
    "rawset",
    "rawget",
    "table",
    "string",
    "math",
    "os",
    "io",
    "coroutine",
    "debug",
    "package"
}

-- Test-specific configuration
files["tests/"] = {
    std = "+busted",
    globals = {
        "describe",
        "it", 
        "before_each",
        "after_each",
        "setup",
        "teardown",
        "pending",
        "spy",
        "mock",
        "stub"
    }
}

-- Ignore certain warnings
ignore = {
    "211",  -- Unused local variable
    "212",  -- Unused argument
    "213",  -- Unused loop variable
    "311",  -- Value assigned to a local variable is unused
    "542"   -- Empty if branch
}

-- But don't ignore these in certain files
files["src/core/"] = {
    ignore = {}  -- No ignores for core files
}

-- Project-specific settings
max_line_length = 120
max_code_line_length = 100
max_string_line_length = 120
max_comment_line_length = 120

-- Allow trailing whitespace in comments
allow_defined_top = true

-- Cache results for performance
cache = true