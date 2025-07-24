-- Phase 6: Cross-Platform Testing
-- Tests platform-specific behaviors, input handling, and compatibility

local TestFramework = require("tests.phase6_test_framework")
local TestSuite = TestFramework.TestSuite
local TestCase = TestFramework.TestCase
local Assert = TestFramework.Assert
local Mock = TestFramework.Mock

-- Mock the game environment
local game = Mock.new()
local player = Mock.new()
local world = Mock.new()
local input = Mock.new()
local audio = Mock.new()
local renderer = Mock.new()
local save = Mock.new()

-- Test suite for cross-platform testing
local CrossPlatformTests = TestSuite.new("Cross-Platform Tests")

-- Cross-Platform Test 1: Platform Detection
CrossPlatformTests:addTest("Platform Detection", function()
    local platforms = {
        "windows", "mac", "linux", "android", "ios", "web", "unknown"
    }
    
    for i, platform in ipairs(platforms) do
        local detected = game.detectPlatform(platform)
        Assert.isNotNil(detected, "Should detect platform: " .. platform)
        Assert.isTrue(type(detected) == "string", "Platform detection should return string")
    end
end)

-- Cross-Platform Test 2: Input Device Compatibility
CrossPlatformTests:addTest("Input Device Compatibility", function()
    local inputDevices = {
        {type = "keyboard", platform = "windows"},
        {type = "keyboard", platform = "mac"},
        {type = "keyboard", platform = "linux"},
        {type = "touch", platform = "android"},
        {type = "touch", platform = "ios"},
        {type = "mouse", platform = "windows"},
        {type = "mouse", platform = "mac"},
        {type = "mouse", platform = "linux"},
        {type = "gamepad", platform = "windows"},
        {type = "gamepad", platform = "mac"},
        {type = "gamepad", platform = "linux"}
    }
    
    for i, device in ipairs(inputDevices) do
        local compatible = input.isCompatible(device.type, device.platform)
        Assert.isNotNil(compatible, "Should check compatibility for " .. device.type .. " on " .. device.platform)
        Assert.isTrue(type(compatible) == "boolean", "Compatibility should return boolean")
    end
end)

-- Cross-Platform Test 3: Screen Resolution Handling
CrossPlatformTests:addTest("Screen Resolution Handling", function()
    local resolutions = {
        {width = 1920, height = 1080, platform = "windows"},
        {width = 2560, height = 1440, platform = "mac"},
        {width = 1366, height = 768, platform = "linux"},
        {width = 1080, height = 1920, platform = "android"},
        {width = 1125, height = 2436, platform = "ios"},
        {width = 800, height = 600, platform = "web"}
    }
    
    for i, resolution in ipairs(resolutions) do
        local result = renderer.setResolution(resolution.width, resolution.height, resolution.platform)
        Assert.isNotNil(result, "Should handle resolution " .. resolution.width .. "x" .. resolution.height .. " on " .. resolution.platform)
        
        local uiScale = renderer.calculateUIScale(resolution.width, resolution.height)
        Assert.isNotNil(uiScale, "Should calculate UI scale for resolution")
        Assert.isTrue(uiScale > 0, "UI scale should be positive")
    end
end)

-- Cross-Platform Test 4: Audio System Compatibility
CrossPlatformTests:addTest("Audio System Compatibility", function()
    local audioFormats = {
        {format = "mp3", platform = "windows"},
        {format = "mp3", platform = "mac"},
        {format = "mp3", platform = "linux"},
        {format = "wav", platform = "android"},
        {format = "aac", platform = "ios"},
        {format = "ogg", platform = "web"}
    }
    
    for i, audioFormat in ipairs(audioFormats) do
        local supported = audio.isFormatSupported(audioFormat.format, audioFormat.platform)
        Assert.isNotNil(supported, "Should check audio format support for " .. audioFormat.format .. " on " .. audioFormat.platform)
        Assert.isTrue(type(supported) == "boolean", "Audio support should return boolean")
    end
end)

-- Cross-Platform Test 5: File System Paths
CrossPlatformTests:addTest("File System Paths", function()
    local pathTests = {
        {platform = "windows", path = "C:\\Games\\OrbitJump\\save.dat"},
        {platform = "mac", path = "/Users/player/Library/Application Support/OrbitJump/save.dat"},
        {platform = "linux", path = "/home/player/.local/share/orbitjump/save.dat"},
        {platform = "android", path = "/data/data/com.orbitjump/files/save.dat"},
        {platform = "ios", path = "/var/mobile/Containers/Data/Application/OrbitJump/Documents/save.dat"},
        {platform = "web", path = "localStorage://orbitjump_save.dat"}
    }
    
    for i, test in ipairs(pathTests) do
        local normalized = save.normalizePath(test.path, test.platform)
        Assert.isNotNil(normalized, "Should normalize path for " .. test.platform)
        Assert.isTrue(type(normalized) == "string", "Normalized path should be string")
        
        local valid = save.isValidPath(normalized, test.platform)
        Assert.isNotNil(valid, "Should validate path for " .. test.platform)
    end
end)

-- Cross-Platform Test 6: Performance Expectations
CrossPlatformTests:addTest("Performance Expectations", function()
    local performanceProfiles = {
        {platform = "windows", expectedFPS = 60},
        {platform = "mac", expectedFPS = 60},
        {platform = "linux", expectedFPS = 60},
        {platform = "android", expectedFPS = 30},
        {platform = "ios", expectedFPS = 60},
        {platform = "web", expectedFPS = 30}
    }
    
    for i, profile in ipairs(performanceProfiles) do
        local actualFPS = game.measurePerformance(profile.platform)
        Assert.isNotNil(actualFPS, "Should measure performance for " .. profile.platform)
        Assert.isTrue(actualFPS > 0, "FPS should be positive")
        
        local acceptable = actualFPS >= profile.expectedFPS * 0.8 -- Allow 20% tolerance
        Assert.isTrue(acceptable, "Performance should meet expectations for " .. profile.platform)
    end
end)

-- Cross-Platform Test 7: Memory Constraints
CrossPlatformTests:addTest("Memory Constraints", function()
    local memoryLimits = {
        {platform = "windows", limit = 2048}, -- 2GB
        {platform = "mac", limit = 2048},
        {platform = "linux", limit = 1024},   -- 1GB
        {platform = "android", limit = 512},  -- 512MB
        {platform = "ios", limit = 1024},     -- 1GB
        {platform = "web", limit = 256}       -- 256MB
    }
    
    for i, limit in ipairs(memoryLimits) do
        local usage = game.measureMemoryUsage(limit.platform)
        Assert.isNotNil(usage, "Should measure memory usage for " .. limit.platform)
        Assert.isTrue(usage > 0, "Memory usage should be positive")
        
        local withinLimit = usage <= limit.limit
        Assert.isTrue(withinLimit, "Memory usage should be within limits for " .. limit.platform)
    end
end)

-- Cross-Platform Test 8: Touch Input Handling
CrossPlatformTests:addTest("Touch Input Handling", function()
    local touchEvents = {
        {type = "touchstart", x = 100, y = 200, platform = "android"},
        {type = "touchmove", x = 150, y = 250, platform = "android"},
        {type = "touchend", x = 200, y = 300, platform = "android"},
        {type = "touchstart", x = 100, y = 200, platform = "ios"},
        {type = "touchmove", x = 150, y = 250, platform = "ios"},
        {type = "touchend", x = 200, y = 300, platform = "ios"}
    }
    
    for i, event in ipairs(touchEvents) do
        local result = input.processTouchEvent(event.type, event.x, event.y, event.platform)
        Assert.isNotNil(result, "Should process touch event " .. event.type .. " on " .. event.platform)
        
        local converted = input.convertTouchToGameInput(event.x, event.y, event.platform)
        Assert.isNotNil(converted, "Should convert touch to game input for " .. event.platform)
    end
end)

-- Cross-Platform Test 9: Keyboard Layout Differences
CrossPlatformTests:addTest("Keyboard Layout Differences", function()
    local keyboardLayouts = {
        {layout = "qwerty", platform = "windows"},
        {layout = "qwerty", platform = "mac"},
        {layout = "qwerty", platform = "linux"},
        {layout = "azerty", platform = "windows"},
        {layout = "dvorak", platform = "mac"},
        {layout = "colemak", platform = "linux"}
    }
    
    for i, layout in ipairs(keyboardLayouts) do
        local mapping = input.getKeyMapping(layout.layout, layout.platform)
        Assert.isNotNil(mapping, "Should get key mapping for " .. layout.layout .. " on " .. layout.platform)
        Assert.isTrue(type(mapping) == "table", "Key mapping should be table")
        
        local key = input.translateKey("w", layout.layout, layout.platform)
        Assert.isNotNil(key, "Should translate key for " .. layout.layout .. " on " .. layout.platform)
    end
end)

-- Cross-Platform Test 10: Graphics API Compatibility
CrossPlatformTests:addTest("Graphics API Compatibility", function()
    local graphicsAPIs = {
        {api = "opengl", platform = "windows"},
        {api = "opengl", platform = "mac"},
        {api = "opengl", platform = "linux"},
        {api = "vulkan", platform = "windows"},
        {api = "metal", platform = "mac"},
        {api = "webgl", platform = "web"}
    }
    
    for i, api in ipairs(graphicsAPIs) do
        local supported = renderer.isAPISupported(api.api, api.platform)
        Assert.isNotNil(supported, "Should check API support for " .. api.api .. " on " .. api.platform)
        Assert.isTrue(type(supported) == "boolean", "API support should return boolean")
        
        if supported then
            local initialized = renderer.initializeAPI(api.api, api.platform)
            Assert.isNotNil(initialized, "Should initialize " .. api.api .. " on " .. api.platform)
        end
    end
end)

-- Cross-Platform Test 11: Network Protocol Compatibility
CrossPlatformTests:addTest("Network Protocol Compatibility", function()
    local networkProtocols = {
        {protocol = "tcp", platform = "windows"},
        {protocol = "tcp", platform = "mac"},
        {protocol = "tcp", platform = "linux"},
        {protocol = "udp", platform = "android"},
        {protocol = "websocket", platform = "web"},
        {protocol = "http", platform = "ios"}
    }
    
    for i, protocol in ipairs(networkProtocols) do
        local supported = game.isNetworkProtocolSupported(protocol.protocol, protocol.platform)
        Assert.isNotNil(supported, "Should check network protocol support for " .. protocol.protocol .. " on " .. protocol.platform)
        Assert.isTrue(type(supported) == "boolean", "Protocol support should return boolean")
        
        if supported then
            local connected = game.testNetworkConnection(protocol.protocol, protocol.platform)
            Assert.isNotNil(connected, "Should test network connection for " .. protocol.protocol .. " on " .. protocol.platform)
        end
    end
end)

-- Cross-Platform Test 12: Localization Support
CrossPlatformTests:addTest("Localization Support", function()
    local locales = {
        {locale = "en_US", platform = "windows"},
        {locale = "en_GB", platform = "mac"},
        {locale = "de_DE", platform = "linux"},
        {locale = "ja_JP", platform = "android"},
        {locale = "zh_CN", platform = "ios"},
        {locale = "es_ES", platform = "web"}
    }
    
    for i, locale in ipairs(locales) do
        local supported = game.isLocaleSupported(locale.locale, locale.platform)
        Assert.isNotNil(supported, "Should check locale support for " .. locale.locale .. " on " .. locale.platform)
        Assert.isTrue(type(supported) == "boolean", "Locale support should return boolean")
        
        if supported then
            local loaded = game.loadLocalization(locale.locale, locale.platform)
            Assert.isNotNil(loaded, "Should load localization for " .. locale.locale .. " on " .. locale.platform)
            
            local text = game.getLocalizedText("menu.start", locale.locale)
            Assert.isNotNil(text, "Should get localized text for " .. locale.locale)
        end
    end
end)

-- Cross-Platform Test 13: Accessibility Features
CrossPlatformTests:addTest("Accessibility Features", function()
    local accessibilityFeatures = {
        {feature = "screen_reader", platform = "windows"},
        {feature = "voice_over", platform = "mac"},
        {feature = "high_contrast", platform = "linux"},
        {feature = "large_text", platform = "android"},
        {feature = "reduce_motion", platform = "ios"},
        {feature = "color_blind", platform = "web"}
    }
    
    for i, feature in ipairs(accessibilityFeatures) do
        local supported = game.isAccessibilitySupported(feature.feature, feature.platform)
        Assert.isNotNil(supported, "Should check accessibility support for " .. feature.feature .. " on " .. feature.platform)
        Assert.isTrue(type(supported) == "boolean", "Accessibility support should return boolean")
        
        if supported then
            local enabled = game.enableAccessibility(feature.feature, feature.platform)
            Assert.isNotNil(enabled, "Should enable accessibility for " .. feature.feature .. " on " .. feature.platform)
        end
    end
end)

-- Cross-Platform Test 14: Security Features
CrossPlatformTests:addTest("Security Features", function()
    local securityFeatures = {
        {feature = "sandbox", platform = "windows"},
        {feature = "gatekeeper", platform = "mac"},
        {feature = "apparmor", platform = "linux"},
        {feature = "selinux", platform = "android"},
        {feature = "app_sandbox", platform = "ios"},
        {feature = "csp", platform = "web"}
    }
    
    for i, feature in ipairs(securityFeatures) do
        local supported = game.isSecurityFeatureSupported(feature.feature, feature.platform)
        Assert.isNotNil(supported, "Should check security feature support for " .. feature.feature .. " on " .. feature.platform)
        Assert.isTrue(type(supported) == "boolean", "Security feature support should return boolean")
        
        if supported then
            local enabled = game.enableSecurityFeature(feature.feature, feature.platform)
            Assert.isNotNil(enabled, "Should enable security feature for " .. feature.feature .. " on " .. feature.platform)
        end
    end
end)

-- Cross-Platform Test 15: Update System Compatibility
CrossPlatformTests:addTest("Update System Compatibility", function()
    local updateSystems = {
        {system = "steam", platform = "windows"},
        {system = "app_store", platform = "mac"},
        {system = "package_manager", platform = "linux"},
        {system = "google_play", platform = "android"},
        {system = "app_store", platform = "ios"},
        {system = "web_update", platform = "web"}
    }
    
    for i, updateSystem in ipairs(updateSystems) do
        local supported = game.isUpdateSystemSupported(updateSystem.system, updateSystem.platform)
        Assert.isNotNil(supported, "Should check update system support for " .. updateSystem.system .. " on " .. updateSystem.platform)
        Assert.isTrue(type(supported) == "boolean", "Update system support should return boolean")
        
        if supported then
            local available = game.checkForUpdates(updateSystem.system, updateSystem.platform)
            Assert.isNotNil(available, "Should check for updates using " .. updateSystem.system .. " on " .. updateSystem.platform)
        end
    end
end)

-- Return the test suite for external execution
return CrossPlatformTests 