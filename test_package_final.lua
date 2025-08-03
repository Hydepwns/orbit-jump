#!/usr/bin/env lua

-- Final test script for Orbit Jump LuaRocks package validation
-- This script validates the package structure and documentation

local function testFileExists(filePath)
    local file = io.open(filePath, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function testFileContent(filePath, requiredContent)
    local file = io.open(filePath, "r")
    if not file then
        return false, "File not found"
    end
    
    local content = file:read("*all")
    file:close()
    
    for _, pattern in ipairs(requiredContent) do
        if not content:match(pattern) then
            return false, "Missing required content: " .. pattern
        end
    end
    
    return true
end

print("Orbit Jump LuaRocks Package Validation")
print("======================================")
print("")

-- Test essential files for LuaRocks publishing
print("1. Testing Essential Files:")
local essentialFiles = {
    "main.lua",
    "README.md",
    "LICENSE",
    "orbit-jump-1.0.0-1.rockspec"
}

local allEssentialFilesExist = true
for _, file in ipairs(essentialFiles) do
    if testFileExists(file) then
        print("✅ " .. file)
    else
        print("❌ " .. file .. " - Missing essential file")
        allEssentialFilesExist = false
    end
end

print("")

-- Test rockspec content
print("2. Testing Rockspec Content:")
local rockspecContent = {
    "package = \"orbit%-jump\"",
    "version = \"1%.0%.0%-1\"",
    "description = {",
    "summary =",
    "homepage =",
    "license = \"MIT\"",
    "dependencies = {",
    "lua >= 5%.3",
    "love2d >= 11%.0",
    "build = {",
    "type = \"builtin\"",
    "modules = {"
}

local rockspecValid = testFileContent("orbit-jump-1.0.0-1.rockspec", rockspecContent)
if rockspecValid then
    print("✅ Rockspec contains all required fields")
else
    print("❌ Rockspec validation failed: " .. tostring(rockspecValid))
end

print("")

-- Test README content
print("3. Testing README Content:")
local readmeContent = {
    "Orbit Jump",
    "Installation",
    "Features",
    "Requirements",
    "LÖVE2D"
}

local readmeValid = testFileContent("README.md", readmeContent)
if readmeValid then
    print("✅ README contains essential information")
else
    print("❌ README validation failed: " .. tostring(readmeValid))
end

print("")

-- Test LICENSE content
print("4. Testing LICENSE Content:")
local licenseContent = {
    "MIT License",
    "Copyright",
    "Permission is hereby granted",
    "THE SOFTWARE IS PROVIDED \"AS IS\""
}

local licenseValid = testFileContent("LICENSE", licenseContent)
if licenseValid then
    print("✅ LICENSE file is valid")
else
    print("❌ LICENSE validation failed: " .. tostring(licenseValid))
end

print("")

-- Test core module files
print("5. Testing Core Module Files:")
local coreModules = {
    "src/core/game.lua",
    "src/core/game_state.lua",
    "src/core/system_orchestrator.lua",
    "src/utils/utils.lua",
    "src/utils/config.lua",
    "src/utils/constants.lua",
    "libs/json.lua"
}

local allCoreModulesExist = true
for _, file in ipairs(coreModules) do
    if testFileExists(file) then
        print("✅ " .. file)
    else
        print("❌ " .. file .. " - Missing core module")
        allCoreModulesExist = false
    end
end

print("")

-- Test installation script
print("6. Testing Installation Script:")
if testFileExists("install.lua") then
    local installContent = testFileContent("install.lua", {"Orbit Jump", "Installation", "luarocks"})
    if installContent then
        print("✅ Installation script is complete")
    else
        print("❌ Installation script validation failed")
    end
else
    print("❌ Installation script missing")
end

print("")

-- Final validation
print("Final Package Validation:")
print("=========================")

local allTestsPassed = allEssentialFilesExist and rockspecValid and readmeValid and licenseValid and allCoreModulesExist

if allTestsPassed then
    print("🎉 SUCCESS: All package validation tests passed!")
    print("")
    print("Your Orbit Jump package is ready for LuaRocks publishing!")
    print("")
    print("Next steps:")
    print("1. Create a git tag: git tag v1.0.0")
    print("2. Push the tag: git push origin v1.0.0")
    print("3. Upload to LuaRocks: luarocks upload orbit-jump-1.0.0-1.rockspec")
    print("4. Verify installation: luarocks install orbit-jump")
else
    print("❌ FAILED: Some validation tests failed.")
    print("Please fix the issues above before publishing.")
end

print("")
print("Package validation completed!") 