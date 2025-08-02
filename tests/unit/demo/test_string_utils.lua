-- Demo test file for Phase 4 optimization demonstration
-- Tests simple string utility functions

package.path = package.path .. ";frameworks/?.lua"

local TestFramework = require("simple_test_framework")

-- Initialize test framework
TestFramework.init()

-- Mock string utilities for testing
local StringUtils = {
    reverse = function(str) 
        if not str then return "" end
        return string.reverse(str) 
    end,
    
    upper = function(str) 
        if not str then return "" end
        return string.upper(str) 
    end,
    
    lower = function(str) 
        if not str then return "" end
        return string.lower(str) 
    end,
    
    length = function(str) 
        if not str then return 0 end
        return string.len(str) 
    end,
    
    contains = function(str, substr) 
        if not str or not substr then return false end
        return string.find(str, substr, 1, true) ~= nil 
    end,
    
    startsWith = function(str, prefix) 
        if not str or not prefix then return false end
        return string.sub(str, 1, string.len(prefix)) == prefix 
    end,
    
    endsWith = function(str, suffix) 
        if not str or not suffix then return false end
        return string.sub(str, -string.len(suffix)) == suffix 
    end,
    
    trim = function(str) 
        if not str then return "" end
        return string.match(str, "^%s*(.-)%s*$") 
    end,
    
    split = function(str, delimiter) 
        if not str then return {} end
        delimiter = delimiter or " "
        local result = {}
        local pattern = string.format("([^%s]+)", delimiter)
        for match in string.gmatch(str, pattern) do
            table.insert(result, match)
        end
        return result 
    end,
    
    join = function(array, separator) 
        if not array or #array == 0 then return "" end
        separator = separator or ""
        return table.concat(array, separator) 
    end
}

-- Test suite
TestFramework.describe("String Utilities", function()
    
    TestFramework.it("should reverse strings correctly", function()
        TestFramework.assert.equal("cba", StringUtils.reverse("abc"), "reverse('abc') should equal 'cba'")
        TestFramework.assert.equal("", StringUtils.reverse(""), "reverse('') should equal ''")
        TestFramework.assert.equal("a", StringUtils.reverse("a"), "reverse('a') should equal 'a'")
        TestFramework.assert.equal("", StringUtils.reverse(nil), "reverse(nil) should equal ''")
    end)
    
    TestFramework.it("should convert to uppercase correctly", function()
        TestFramework.assert.equal("HELLO", StringUtils.upper("hello"), "upper('hello') should equal 'HELLO'")
        TestFramework.assert.equal("WORLD", StringUtils.upper("World"), "upper('World') should equal 'WORLD'")
        TestFramework.assert.equal("", StringUtils.upper(""), "upper('') should equal ''")
        TestFramework.assert.equal("", StringUtils.upper(nil), "upper(nil) should equal ''")
    end)
    
    TestFramework.it("should convert to lowercase correctly", function()
        TestFramework.assert.equal("hello", StringUtils.lower("HELLO"), "lower('HELLO') should equal 'hello'")
        TestFramework.assert.equal("world", StringUtils.lower("World"), "lower('World') should equal 'world'")
        TestFramework.assert.equal("", StringUtils.lower(""), "lower('') should equal ''")
        TestFramework.assert.equal("", StringUtils.lower(nil), "lower(nil) should equal ''")
    end)
    
    TestFramework.it("should calculate string length correctly", function()
        TestFramework.assert.equal(5, StringUtils.length("hello"), "length('hello') should equal 5")
        TestFramework.assert.equal(0, StringUtils.length(""), "length('') should equal 0")
        TestFramework.assert.equal(0, StringUtils.length(nil), "length(nil) should equal 0")
        TestFramework.assert.equal(1, StringUtils.length("a"), "length('a') should equal 1")
    end)
    
    TestFramework.it("should check if string contains substring", function()
        TestFramework.assert.isTrue(StringUtils.contains("hello world", "world"), "'hello world' should contain 'world'")
        TestFramework.assert.isTrue(StringUtils.contains("hello world", "hello"), "'hello world' should contain 'hello'")
        TestFramework.assert.isFalse(StringUtils.contains("hello world", "xyz"), "'hello world' should not contain 'xyz'")
        TestFramework.assert.isFalse(StringUtils.contains("", "test"), "empty string should not contain 'test'")
        TestFramework.assert.isFalse(StringUtils.contains(nil, "test"), "nil should not contain 'test'")
    end)
    
    TestFramework.it("should check if string starts with prefix", function()
        TestFramework.assert.isTrue(StringUtils.startsWith("hello world", "hello"), "'hello world' should start with 'hello'")
        TestFramework.assert.isFalse(StringUtils.startsWith("hello world", "world"), "'hello world' should not start with 'world'")
        TestFramework.assert.isTrue(StringUtils.startsWith("hello", "hello"), "'hello' should start with 'hello'")
        TestFramework.assert.isFalse(StringUtils.startsWith("", "test"), "empty string should not start with 'test'")
        TestFramework.assert.isFalse(StringUtils.startsWith(nil, "test"), "nil should not start with 'test'")
    end)
    
    TestFramework.it("should check if string ends with suffix", function()
        TestFramework.assert.isTrue(StringUtils.endsWith("hello world", "world"), "'hello world' should end with 'world'")
        TestFramework.assert.isFalse(StringUtils.endsWith("hello world", "hello"), "'hello world' should not end with 'hello'")
        TestFramework.assert.isTrue(StringUtils.endsWith("hello", "hello"), "'hello' should end with 'hello'")
        TestFramework.assert.isFalse(StringUtils.endsWith("", "test"), "empty string should not end with 'test'")
        TestFramework.assert.isFalse(StringUtils.endsWith(nil, "test"), "nil should not end with 'test'")
    end)
    
    TestFramework.it("should trim whitespace correctly", function()
        TestFramework.assert.equal("hello", StringUtils.trim("  hello  "), "trim('  hello  ') should equal 'hello'")
        TestFramework.assert.equal("world", StringUtils.trim("world"), "trim('world') should equal 'world'")
        TestFramework.assert.equal("", StringUtils.trim("   "), "trim('   ') should equal ''")
        TestFramework.assert.equal("", StringUtils.trim(""), "trim('') should equal ''")
        TestFramework.assert.equal("", StringUtils.trim(nil), "trim(nil) should equal ''")
    end)
    
    TestFramework.it("should split strings correctly", function()
        local result1 = StringUtils.split("hello world", " ")
        TestFramework.assert.equal(2, #result1, "split('hello world', ' ') should have 2 elements")
        TestFramework.assert.equal("hello", result1[1], "First element should be 'hello'")
        TestFramework.assert.equal("world", result1[2], "Second element should be 'world'")
        
        local result2 = StringUtils.split("a,b,c", ",")
        TestFramework.assert.equal(3, #result2, "split('a,b,c', ',') should have 3 elements")
        TestFramework.assert.equal("a", result2[1], "First element should be 'a'")
        TestFramework.assert.equal("b", result2[2], "Second element should be 'b'")
        TestFramework.assert.equal("c", result2[3], "Third element should be 'c'")
        
        local result3 = StringUtils.split("", " ")
        TestFramework.assert.equal(0, #result3, "split('', ' ') should have 0 elements")
        
        local result4 = StringUtils.split(nil, " ")
        TestFramework.assert.equal(0, #result4, "split(nil, ' ') should have 0 elements")
    end)
    
    TestFramework.it("should join arrays correctly", function()
        local array1 = {"hello", "world"}
        TestFramework.assert.equal("hello world", StringUtils.join(array1, " "), "join(['hello', 'world'], ' ') should equal 'hello world'")
        
        local array2 = {"a", "b", "c"}
        TestFramework.assert.equal("a,b,c", StringUtils.join(array2, ","), "join(['a', 'b', 'c'], ',') should equal 'a,b,c'")
        
        local array3 = {}
        TestFramework.assert.equal("", StringUtils.join(array3, " "), "join([], ' ') should equal ''")
        
        TestFramework.assert.equal("", StringUtils.join(nil, " "), "join(nil, ' ') should equal ''")
    end)
    
end)

-- Print test summary
TestFramework.print_summary() 