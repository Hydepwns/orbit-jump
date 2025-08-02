-- Test file for Asset Loader
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Get AssetLoader
local AssetLoader = Utils.require("src.utils.asset_loader")

-- Test suite
local tests = {
    ["test asset loader initialization"] = function()
        local success = AssetLoader.init()
        
        TestFramework.assert.isTrue(success, "Should initialize successfully")
        TestFramework.assert.notNil(AssetLoader.images, "Should have images table")
        TestFramework.assert.notNil(AssetLoader.sounds, "Should have sounds table")
        TestFramework.assert.notNil(AssetLoader.fonts, "Should have fonts table")
        TestFramework.assert.notNil(AssetLoader.shaders, "Should have shaders table")
    end,
    
    ["test get asset list"] = function()
        local assetList = AssetLoader.getAssetList()
        
        TestFramework.assert.notNil(assetList, "Should return asset list")
        TestFramework.assert.notNil(assetList.images, "Should have images list")
        TestFramework.assert.notNil(assetList.sounds, "Should have sounds list")
        TestFramework.assert.greaterThan(0, #assetList.images, "Should have image assets defined")
    end,
    
    ["test loading state"] = function()
        AssetLoader.init()
        
        TestFramework.assert.isFalse(AssetLoader.isLoading, "Should not be loading initially")
        TestFramework.assert.equal(0, AssetLoader.loadProgress, "Progress should start at 0")
        TestFramework.assert.equal(0, AssetLoader.totalAssets, "Total assets should be 0")
        TestFramework.assert.equal(0, AssetLoader.loadedAssets, "Loaded assets should be 0")
        TestFramework.assert.equal("", AssetLoader.currentAsset, "Current asset should be empty")
    end,
    
    ["test asset structure"] = function()
        local assetList = AssetLoader.getAssetList()
        
        -- Check image asset structure
        if assetList.images and #assetList.images > 0 then
            local firstImage = assetList.images[1]
            TestFramework.assert.notNil(firstImage.name, "Image should have name")
            TestFramework.assert.notNil(firstImage.path, "Image should have path")
        end
        
        -- Check sound asset structure
        if assetList.sounds and #assetList.sounds > 0 then
            local firstSound = assetList.sounds[1]
            TestFramework.assert.notNil(firstSound.name, "Sound should have name")
            TestFramework.assert.notNil(firstSound.path, "Sound should have path")
        end
    end,
    
    ["test asset categories"] = function()
        local assetList = AssetLoader.getAssetList()
        
        -- Check for expected asset categories
        local hasUIImages = false
        local hasGameSprites = false
        local hasBackgrounds = false
        
        for _, asset in ipairs(assetList.images or {}) do
            if asset.name == "button" or asset.name == "panel" then
                hasUIImages = true
            elseif asset.name == "player" or asset.name == "ring" then
                hasGameSprites = true
            elseif asset.name == "stars" or asset.name == "nebula" then
                hasBackgrounds = true
            end
        end
        
        TestFramework.assert.isTrue(hasUIImages, "Should have UI images")
        TestFramework.assert.isTrue(hasGameSprites, "Should have game sprites")
        TestFramework.assert.isTrue(hasBackgrounds, "Should have background images")
    end,
    
    ["test sound assets"] = function()
        local assetList = AssetLoader.getAssetList()
        
        -- Check for expected sound effects
        local hasJumpSound = false
        
        for _, asset in ipairs(assetList.sounds or {}) do
            if asset.name == "jump" then
                hasJumpSound = true
                TestFramework.assert.match(asset.path, "%.ogg$", "Sound should be in OGG format")
            end
        end
        
        TestFramework.assert.isTrue(hasJumpSound, "Should have jump sound effect")
    end,
    
    ["test asset paths"] = function()
        local assetList = AssetLoader.getAssetList()
        
        -- Check that all paths follow expected structure
        for _, asset in ipairs(assetList.images or {}) do
            TestFramework.assert.match(asset.path, "^assets/images/", "Image paths should start with assets/images/")
            TestFramework.assert.match(asset.path, "%.png$", "Images should be PNG format")
        end
        
        for _, asset in ipairs(assetList.sounds or {}) do
            -- Allow both sounds and music directories
            local isValidPath = string.match(asset.path, "^assets/sounds/") or string.match(asset.path, "^assets/music/")
            TestFramework.assert.isTrue(isValidPath, "Sound/music paths should start with assets/sounds/ or assets/music/")
        end
    end,
    
    ["test empty asset storage after init"] = function()
        AssetLoader.init()
        
        TestFramework.assert.isEmpty(AssetLoader.images, "Images should be empty after init")
        TestFramework.assert.isEmpty(AssetLoader.sounds, "Sounds should be empty after init")
        TestFramework.assert.isEmpty(AssetLoader.fonts, "Fonts should be empty after init")
        TestFramework.assert.isEmpty(AssetLoader.shaders, "Shaders should be empty after init")
    end,
    
    ["test asset list consistency"] = function()
        local list1 = AssetLoader.getAssetList()
        local list2 = AssetLoader.getAssetList()
        
        -- Asset list should be consistent between calls
        TestFramework.assert.equal(#list1.images, #list2.images, "Image count should be consistent")
        if list1.sounds and list2.sounds then
            TestFramework.assert.equal(#list1.sounds, #list2.sounds, "Sound count should be consistent")
        end
    end,
    
    ["test unique asset names"] = function()
        local assetList = AssetLoader.getAssetList()
        local names = {}
        
        -- Check for duplicate names in images
        for _, asset in ipairs(assetList.images or {}) do
            TestFramework.assert.isNil(names[asset.name], "Asset name '" .. asset.name .. "' should be unique")
            names[asset.name] = true
        end
        
        -- Reset for sounds (names can be reused across categories)
        names = {}
        for _, asset in ipairs(assetList.sounds or {}) do
            TestFramework.assert.isNil(names[asset.name], "Sound name '" .. asset.name .. "' should be unique")
            names[asset.name] = true
        end
    end
}

-- Test runner
local function run()
    Utils.Logger.info("Running Asset Loader Tests")
    Utils.Logger.info("==================================================")
    return TestFramework.runTests(tests)
end

return {run = run}