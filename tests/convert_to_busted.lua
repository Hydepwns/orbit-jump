#!/usr/bin/env lua
-- Helper script to convert legacy tests to Busted-style format
-- Usage: lua convert_to_busted.lua <input_test_file> <output_test_file>

local Utils = require("src.utils.utils")

local function convertTest(inputFile, outputFile)
    local input = io.open(inputFile, "r")
    if not input then
        error("Cannot open input file: " .. inputFile)
    end
    
    local content = input:read("*all")
    input:close()
    
    -- Extract the test suite name from the file
    local suiteName = content:match('TestFramework%.runSuite%("([^"]+)"')
    if not suiteName then
        suiteName = "Converted Tests"
    end
    
    -- Start building the new test file
    local output = {}
    table.insert(output, "-- Converted to Busted-style test")
    table.insert(output, 'package.path = package.path .. ";../../?.lua"\n')
    table.insert(output, 'Utils.require("tests.busted")')
    
    -- Extract requires
    for line in content:gmatch("local%s+(%w+)%s*=%s*require%s*%(.-%)") do
        if line ~= "TestFramework" then
            table.insert(output, content:match("(local%s+" .. line .. "%s*=%s*require%s*%(.-%))"))
        end
    end
    
    table.insert(output, "\n")
    table.insert(output, string.format('describe("%s", function()', suiteName))
    
    -- Convert test functions
    local tests = content:match("local%s+tests%s*=%s*{(.-)}")
    if tests then
        -- Extract individual test functions
        for testName, testBody in tests:gmatch('(%[?"?[%w%s]+"?%]?)%s*=%s*function%(%)(.-)end,?') do
            -- Clean up test name
            testName = testName:gsub('[%[%]"]', '')
            
            -- Convert assertions
            local convertedBody = testBody
            
            -- Convert TestFramework.utils.assertEqual to assert.equals
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertEqual%(([^,]+),%s*([^,]+),%s*"([^"]+)"',
                'assert.equals(%1, %2, "%3"'
            )
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertEqual%(([^,]+),%s*([^,]+)%)',
                'assert.equals(%1, %2)'
            )
            
            -- Convert assertTrue/assertFalse
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertTrue%(([^,]+),%s*"([^"]+)"',
                'assert.is_true(%1, "%2"'
            )
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertTrue%(([^)]+)%)',
                'assert.is_true(%1)'
            )
            
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertFalse%(([^,]+),%s*"([^"]+)"',
                'assert.is_false(%1, "%2"'
            )
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertFalse%(([^)]+)%)',
                'assert.is_false(%1)'
            )
            
            -- Convert assertNil/assertNotNil
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertNil%(([^,]+),%s*"([^"]+)"',
                'assert.is_nil(%1, "%2"'
            )
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertNil%(([^)]+)%)',
                'assert.is_nil(%1)'
            )
            
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertNotNil%(([^,]+),%s*"([^"]+)"',
                'assert.is_not_nil(%1, "%2"'
            )
            convertedBody = convertedBody:gsub(
                'TestFramework%.utils%.assertNotNil%(([^)]+)%)',
                'assert.is_not_nil(%1)'
            )
            
            -- Add the test
            table.insert(output, string.format('    it("should %s", function()%s    end)\n', 
                testName:lower():gsub("_", " "), convertedBody))
        end
    end
    
    table.insert(output, "end)")
    
    -- Write output file
    local out = io.open(outputFile, "w")
    if not out then
        error("Cannot create output file: " .. outputFile)
    end
    
    out:write(table.concat(output, "\n"))
    out:close()
    
    Utils.Logger.info("Converted %s to %s", inputFile, outputFile)
end

-- Main
local args = {...}
if #args ~= 2 then
    Utils.Logger.info("Usage: lua convert_to_busted.lua <input_test_file> <output_test_file>")
    os.exit(1)
end

convertTest(args[1], args[2])