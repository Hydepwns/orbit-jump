-- Asset Loader for Orbit Jump
-- Preloads all game assets to avoid runtime stutters
local AssetLoader = {}
-- Asset storage
AssetLoader.images = {}
AssetLoader.sounds = {}
AssetLoader.fonts = {}
AssetLoader.shaders = {}
-- Loading state
AssetLoader.isLoading = false
AssetLoader.loadProgress = 0
AssetLoader.totalAssets = 0
AssetLoader.loadedAssets = 0
AssetLoader.currentAsset = ""
-- Initialize the asset loader
function AssetLoader.init()
    AssetLoader.images = {}
    AssetLoader.sounds = {}
    AssetLoader.fonts = {}
    AssetLoader.shaders = {}
    return true
end
-- Define all assets to load
function AssetLoader.getAssetList()
    return {
        images = {
            -- UI images
            {name = "logo", path = "assets/images/logo.png"},
            {name = "button", path = "assets/images/ui/button.png"},
            {name = "panel", path = "assets/images/ui/panel.png"},
            -- Game sprites
            {name = "player", path = "assets/images/player.png"},
            {name = "ring", path = "assets/images/ring.png"},
            {name = "meteor", path = "assets/images/meteor.png"},
            {name = "shield", path = "assets/images/shield.png"},
            -- Backgrounds
            {name = "stars", path = "assets/images/bg/stars.png"},
            {name = "nebula", path = "assets/images/bg/nebula.png"}
        },
        sounds = {
            -- Sound effects
            {name = "jump", path = "assets/sounds/jump.ogg"},
            {name = "land", path = "assets/sounds/land.ogg"},
            {name = "collect_ring", path = "assets/sounds/collect_ring.ogg"},
            {name = "powerup", path = "assets/sounds/powerup.ogg"},
            {name = "hit", path = "assets/sounds/hit.ogg"},
            {name = "shield_break", path = "assets/sounds/shield_break.ogg"},
            {name = "warp", path = "assets/sounds/warp.ogg"},
            -- Music
            {name = "menu_music", path = "assets/music/menu.ogg", stream = true},
            {name = "game_music", path = "assets/music/game.ogg", stream = true},
            {name = "boss_music", path = "assets/music/boss.ogg", stream = true}
        },
        fonts = {
            -- UI fonts
            {name = "small", path = "assets/fonts/main.ttf", size = 14},
            {name = "medium", path = "assets/fonts/main.ttf", size = 18},
            {name = "large", path = "assets/fonts/main.ttf", size = 24},
            {name = "title", path = "assets/fonts/title.ttf", size = 48}
        },
        shaders = {
            -- Visual effects
            {name = "bloom", path = "assets/shaders/bloom.glsl"},
            {name = "chromatic", path = "assets/shaders/chromatic.glsl"},
            {name = "wave", path = "assets/shaders/wave.glsl"}
        }
    }
end
-- Load all assets
function AssetLoader.loadAll(onProgress, onComplete)
    AssetLoader.isLoading = true
    AssetLoader.loadProgress = 0
    AssetLoader.loadedAssets = 0
    local assets = AssetLoader.getAssetList()
    -- Count total assets
    AssetLoader.totalAssets = 0
    for _, category in pairs(assets) do
        AssetLoader.totalAssets = AssetLoader.totalAssets + #category
    end
    -- Create coroutine for async loading
    local loadCoroutine = coroutine.create(function()
        -- Load images
        for _, asset in ipairs(assets.images) do
            AssetLoader.currentAsset = asset.name
            if love.filesystem.getInfo(asset.path) then
                local success, img = pcall(love.graphics.newImage, asset.path)
                if success then
                    AssetLoader.images[asset.name] = img
                else
                    print("Failed to load image: " .. asset.path)
                end
            end
            AssetLoader.loadedAssets = AssetLoader.loadedAssets + 1
            AssetLoader.loadProgress = AssetLoader.loadedAssets / AssetLoader.totalAssets
            if onProgress then onProgress(AssetLoader.loadProgress, AssetLoader.currentAsset) end
            coroutine.yield()
        end
        -- Load sounds
        for _, asset in ipairs(assets.sounds) do
            AssetLoader.currentAsset = asset.name
            if love.filesystem.getInfo(asset.path) then
                local success, sound
                if asset.stream then
                    success, sound = pcall(love.audio.newSource, asset.path, "stream")
                else
                    success, sound = pcall(love.audio.newSource, asset.path, "static")
                end
                if success then
                    AssetLoader.sounds[asset.name] = sound
                else
                    print("Failed to load sound: " .. asset.path)
                end
            end
            AssetLoader.loadedAssets = AssetLoader.loadedAssets + 1
            AssetLoader.loadProgress = AssetLoader.loadedAssets / AssetLoader.totalAssets
            if onProgress then onProgress(AssetLoader.loadProgress, AssetLoader.currentAsset) end
            coroutine.yield()
        end
        -- Load fonts
        for _, asset in ipairs(assets.fonts) do
            AssetLoader.currentAsset = asset.name
            if love.filesystem.getInfo(asset.path) then
                local success, font = pcall(love.graphics.newFont, asset.path, asset.size)
                if success then
                    AssetLoader.fonts[asset.name] = font
                else
                    -- Fallback to default font
                    AssetLoader.fonts[asset.name] = love.graphics.newFont(asset.size)
                end
            else
                -- Use default font if file not found
                AssetLoader.fonts[asset.name] = love.graphics.newFont(asset.size)
            end
            AssetLoader.loadedAssets = AssetLoader.loadedAssets + 1
            AssetLoader.loadProgress = AssetLoader.loadedAssets / AssetLoader.totalAssets
            if onProgress then onProgress(AssetLoader.loadProgress, AssetLoader.currentAsset) end
            coroutine.yield()
        end
        -- Load shaders
        for _, asset in ipairs(assets.shaders) do
            AssetLoader.currentAsset = asset.name
            if love.filesystem.getInfo(asset.path) then
                local shaderCode = love.filesystem.read(asset.path)
                if shaderCode then
                    local success, shader = pcall(love.graphics.newShader, shaderCode)
                    if success then
                        AssetLoader.shaders[asset.name] = shader
                    else
                        print("Failed to compile shader: " .. asset.path)
                    end
                end
            end
            AssetLoader.loadedAssets = AssetLoader.loadedAssets + 1
            AssetLoader.loadProgress = AssetLoader.loadedAssets / AssetLoader.totalAssets
            if onProgress then onProgress(AssetLoader.loadProgress, AssetLoader.currentAsset) end
            coroutine.yield()
        end
        -- Loading complete
        AssetLoader.isLoading = false
        if onComplete then onComplete() end
    end)
    -- Return the coroutine for manual stepping if needed
    return loadCoroutine
end
-- Get an image asset
function AssetLoader.getImage(name)
    return AssetLoader.images[name]
end
-- Get a sound asset
function AssetLoader.getSound(name)
    return AssetLoader.sounds[name]
end
-- Get a font asset
function AssetLoader.getFont(name)
    return AssetLoader.fonts[name] or love.graphics.getFont()
end
-- Get a shader asset
function AssetLoader.getShader(name)
    return AssetLoader.shaders[name]
end
-- Play a sound
function AssetLoader.playSound(name, volume, pitch)
    local sound = AssetLoader.sounds[name]
    if sound then
        sound:setVolume(volume or 1)
        sound:setPitch(pitch or 1)
        sound:play()
    end
end
-- Clear all loaded assets
function AssetLoader.clear()
    -- Stop all sounds
    for _, sound in pairs(AssetLoader.sounds) do
        sound:stop()
    end
    -- Clear tables
    AssetLoader.images = {}
    AssetLoader.sounds = {}
    AssetLoader.fonts = {}
    AssetLoader.shaders = {}
    -- Reset state
    AssetLoader.isLoading = false
    AssetLoader.loadProgress = 0
    AssetLoader.loadedAssets = 0
    AssetLoader.totalAssets = 0
end
-- Check if asset storage is empty
function AssetLoader.isEmpty()
    local imageCount = 0
    local soundCount = 0
    local fontCount = 0
    local shaderCount = 0
    for _ in pairs(AssetLoader.images) do
        imageCount = imageCount + 1
    end
    for _ in pairs(AssetLoader.sounds) do
        soundCount = soundCount + 1
    end
    for _ in pairs(AssetLoader.fonts) do
        fontCount = fontCount + 1
    end
    for _ in pairs(AssetLoader.shaders) do
        shaderCount = shaderCount + 1
    end
    return imageCount == 0 and soundCount == 0 and fontCount == 0 and shaderCount == 0
end
return AssetLoader