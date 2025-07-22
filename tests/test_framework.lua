-- Simple test framework for LÖVE2D
local TestFramework = {}
TestFramework.__index = TestFramework

function TestFramework:new()
    local self = setmetatable({}, TestFramework)
    self.tests = {}
    self.passed = 0
    self.failed = 0
    self.assertions = 0
    return self
end

function TestFramework:describe(name, fn)
    table.insert(self.tests, {name = name, fn = fn})
end

function TestFramework:assertEquals(actual, expected, message)
    self.assertions = self.assertions + 1
    if actual ~= expected then
        error(string.format("%s\nExpected: %s\nActual: %s", 
            message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

function TestFramework:assertAlmostEquals(actual, expected, tolerance, message)
    self.assertions = self.assertions + 1
    tolerance = tolerance or 0.001
    if math.abs(actual - expected) > tolerance then
        error(string.format("%s\nExpected: %s (±%s)\nActual: %s", 
            message or "Assertion failed", tostring(expected), tostring(tolerance), tostring(actual)))
    end
end

function TestFramework:assertTrue(value, message)
    self.assertions = self.assertions + 1
    if not value then
        error(message or "Expected true, got false")
    end
end

function TestFramework:assertFalse(value, message)
    self.assertions = self.assertions + 1
    if value then
        error(message or "Expected false, got true")
    end
end

function TestFramework:assertNotNil(value, message)
    self.assertions = self.assertions + 1
    if value == nil then
        error(message or "Expected non-nil value")
    end
end

function TestFramework:assertTableEquals(actual, expected, message)
    self.assertions = self.assertions + 1
    if type(actual) ~= "table" or type(expected) ~= "table" then
        error(string.format("%s\nExpected table, got %s", 
            message or "Assertion failed", type(actual)))
    end
    
    for k, v in pairs(expected) do
        if actual[k] ~= v then
            error(string.format("%s\nKey '%s': Expected %s, got %s", 
                message or "Assertion failed", k, tostring(v), tostring(actual[k])))
        end
    end
    
    for k, v in pairs(actual) do
        if expected[k] == nil then
            error(string.format("%s\nUnexpected key '%s' with value %s", 
                message or "Assertion failed", k, tostring(v)))
        end
    end
end

function TestFramework:run()
    print("Running tests...\n")
    
    for _, test in ipairs(self.tests) do
        local success, err = pcall(test.fn, self)
        if success then
            self.passed = self.passed + 1
            print(string.format("✓ %s", test.name))
        else
            self.failed = self.failed + 1
            print(string.format("✗ %s", test.name))
            print(string.format("  Error: %s\n", err))
        end
    end
    
    print(string.format("\nTests: %d passed, %d failed, %d total", 
        self.passed, self.failed, self.passed + self.failed))
    print(string.format("Assertions: %d", self.assertions))
    
    return self.failed == 0
end

return TestFramework