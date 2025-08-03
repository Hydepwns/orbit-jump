#!/usr/bin/env lua
-- Dependency Analysis Script for Orbit Jump
local function extractDependencies(filename)
    local file = io.open(filename, "r")
    if not file then return {} end
    local content = file:read("*all")
    file:close()
    local deps = {}
    local module_name = filename:match("src/(.+)%.lua$")
    if not module_name then return {} end
    -- Extract require() patterns
    for dep in content:gmatch('require%("([^"]+)"%)') do
        if dep:match("^src/") then
            table.insert(deps, dep:gsub("^src/", ""):gsub("/", "."))
        end
    end
    -- Extract Utils.require() patterns
    for dep in content:gmatch('Utils%.require%("([^"]+)"%)') do
        if dep:match("^src/") then
            table.insert(deps, dep:gsub("^src/", ""):gsub("/", "."))
        end
    end
    return {
        module = module_name:gsub("/", "."),
        dependencies = deps
    }
end
-- Find all Lua files in src directory
local function findLuaFiles(dir)
    local files = {}
    local handle = io.popen("find " .. dir .. " -name '*.lua'")
    for file in handle:lines() do
        table.insert(files, file)
    end
    handle:close()
    return files
end
-- Analyze dependencies
local modules = {}
local files = findLuaFiles("src")
for _, file in ipairs(files) do
    local info = extractDependencies(file)
    if info.module then
        modules[info.module] = info.dependencies
    end
end
-- Print dependency analysis
print("=== MODULE DEPENDENCY ANALYSIS ===")
print()
-- Find modules with high coupling (many dependencies)
print("HIGH COUPLING MODULES (>5 dependencies):")
for module, deps in pairs(modules) do
    if #deps > 5 then
        print(string.format("  %s (%d deps): %s", module, #deps, table.concat(deps, ", ")))
    end
end
print()
-- Find modules that are heavily depended upon
local dependents = {}
for module, deps in pairs(modules) do
    for _, dep in ipairs(deps) do
        dependents[dep] = dependents[dep] or {}
        table.insert(dependents[dep], module)
    end
end
print("HEAVILY DEPENDED UPON MODULES (>5 dependents):")
for module, deps in pairs(dependents) do
    if #deps > 5 then
        print(string.format("  %s (%d dependents): %s", module, #deps, table.concat(deps, ", ")))
    end
end
print()
-- Look for potential circular dependencies
print("POTENTIAL CIRCULAR DEPENDENCIES:")
local function checkCircular(module, path, visited)
    if visited[module] then
        return path
    end
    visited[module] = true
    local deps = modules[module] or {}
    for _, dep in ipairs(deps) do
        for _, pathModule in ipairs(path) do
            if dep == pathModule then
                local cycle = {}
                local inCycle = false
                for _, m in ipairs(path) do
                    if m == dep then inCycle = true end
                    if inCycle then table.insert(cycle, m) end
                end
                table.insert(cycle, dep)
                return cycle
            end
        end
        local newPath = {}
        for _, m in ipairs(path) do table.insert(newPath, m) end
        table.insert(newPath, module)
        local result = checkCircular(dep, newPath, {})
        if result then return result end
    end
    return nil
end
local checkedModules = {}
for module, _ in pairs(modules) do
    if not checkedModules[module] then
        local cycle = checkCircular(module, {}, {})
        if cycle then
            print(string.format("  %s", table.concat(cycle, " -> ")))
            for _, m in ipairs(cycle) do
                checkedModules[m] = true
            end
        end
    end
end
print()
-- GameState analysis
print("GAMESTATE DEPENDENCY ANALYSIS:")
local gameStateDeps = dependents["core.game_state"] or {}
print(string.format("  GameState is required by %d modules:", #gameStateDeps))
for _, dep in ipairs(gameStateDeps) do
    print(string.format("    - %s", dep))
end
print()
-- Utils analysis
print("UTILS DEPENDENCY ANALYSIS:")
local utilsDeps = dependents["utils.utils"] or {}
print(string.format("  Utils is required by %d modules:", #utilsDeps))
if #utilsDeps > 10 then
    print("    (showing first 10)")
    for i = 1, 10 do
        print(string.format("    - %s", utilsDeps[i]))
    end
    print(string.format("    ... and %d more", #utilsDeps - 10))
else
    for _, dep in ipairs(utilsDeps) do
        print(string.format("    - %s", dep))
    end
end
print()
print("=== ARCHITECTURAL RECOMMENDATIONS ===")
print()
-- Check if SystemOrchestrator is used
local orchestratorDeps = dependents["core.system_orchestrator"] or {}
if #orchestratorDeps == 0 then
    print("⚠️  SystemOrchestrator exists but is not used!")
    print("   Recommendation: Integrate SystemOrchestrator to manage dependencies")
end
-- Utils overuse
if #utilsDeps > 30 then
    print("⚠️  Utils module is used by many modules - potential god object")
    print("   Recommendation: Split Utils into focused utilities")
end
-- GameState overuse
if #gameStateDeps > 15 then
    print("⚠️  GameState is accessed by many modules - high coupling")
    print("   Recommendation: Use dependency injection or event system")
end