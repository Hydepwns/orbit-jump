#!/usr/bin/env lua

-- Orbit Jump Installation Script
-- This script helps install Orbit Jump either via LuaRocks or manually

local function printUsage()
    print("Orbit Jump Installation Script")
    print("Usage: lua install.lua [option]")
    print("")
    print("Options:")
    print("  --luarocks    Install via LuaRocks (recommended)")
    print("  --manual      Manual installation instructions")
    print("  --test        Run tests after installation")
    print("  --help        Show this help message")
    print("")
    print("Examples:")
    print("  lua install.lua --luarocks")
    print("  lua install.lua --manual")
end

local function installViaLuaRocks()
    print("Installing Orbit Jump via LuaRocks...")
    
    -- Check if LuaRocks is available
    local luarocks_available = os.execute("luarocks --version > /dev/null 2>&1")
    if not luarocks_available then
        print("Error: LuaRocks is not installed or not in PATH")
        print("Please install LuaRocks first: https://luarocks.org/")
        return false
    end
    
    -- Install the package
    local success = os.execute("luarocks install orbit-jump-1.0.0-1.rockspec")
    if success then
        print("✅ Orbit Jump installed successfully via LuaRocks!")
        print("You can now run the game with: love orbit-jump")
        return true
    else
        print("❌ Installation failed. Please check the error messages above.")
        return false
    end
end

local function showManualInstallation()
    print("Manual Installation Instructions:")
    print("")
    print("1. Ensure you have LÖVE2D installed:")
    print("   - macOS: brew install love")
    print("   - Linux: sudo apt install love2d")
    print("   - Windows: Download from https://love2d.org/")
    print("")
    print("2. Clone the repository:")
    print("   git clone https://github.com/Hydepwns/orbit-jump.git")
    print("   cd orbit-jump")
    print("")
    print("3. Run the game:")
    print("   love .")
    print("")
    print("4. Run tests (optional):")
    print("   ./run_tests.sh")
end

local function runTests()
    print("Running tests...")
    local success = os.execute("./run_tests.sh")
    if success then
        print("✅ All tests passed!")
    else
        print("❌ Some tests failed. Please check the output above.")
    end
    return success
end

-- Main execution
local args = {...}

if #args == 0 or args[1] == "--help" then
    printUsage()
elseif args[1] == "--luarocks" then
    installViaLuaRocks()
elseif args[1] == "--manual" then
    showManualInstallation()
elseif args[1] == "--test" then
    runTests()
else
    print("Unknown option: " .. args[1])
    printUsage()
end 