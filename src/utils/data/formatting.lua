--[[
    Formatting Utilities for Orbit Jump
    
    This module provides formatting functions for numbers, time, text,
    and other data types for display purposes.
--]]

local Formatting = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Number Formatting: Human-Readable Numbers
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Formatting.formatNumber(num)
    --[[
        Format Number with Suffixes
        
        Formats large numbers with K, M, B suffixes for readability.
        Perfect for displaying scores, currency, and large values.
        
        Parameters:
        - num: The number to format
        
        Returns: Formatted string
        Performance: O(1) with zero allocations
    --]]
    
    if not num or type(num) ~= "number" then
        return "0"
    end
    
    if num < 1000 then
        return tostring(math.floor(num))
    elseif num < 1000000 then
        return string.format("%.1fK", num / 1000)
    elseif num < 1000000000 then
        return string.format("%.1fM", num / 1000000)
    else
        return string.format("%.1fB", num / 1000000000)
    end
end

function Formatting.formatNumberWithCommas(num)
    --[[
        Format Number with Commas
        
        Adds comma separators to numbers for better readability.
        Perfect for displaying large numbers without suffixes.
        
        Parameters:
        - num: The number to format
        
        Returns: Formatted string with commas
        Performance: O(log n) where n is the number
    --]]
    
    if not num or type(num) ~= "number" then
        return "0"
    end
    
    local str = tostring(math.floor(num))
    local result = ""
    local count = 0
    
    for i = #str, 1, -1 do
        result = str:sub(i, i) .. result
        count = count + 1
        if count % 3 == 0 and i > 1 then
            result = "," .. result
        end
    end
    
    return result
end

function Formatting.formatCurrency(amount, currency)
    --[[
        Format Currency
        
        Formats numbers as currency with appropriate symbols.
        
        Parameters:
        - amount: The amount to format
        - currency: Currency symbol (default: "$")
        
        Returns: Formatted currency string
        Performance: O(1) with zero allocations
    --]]
    
    if not amount or type(amount) ~= "number" then
        return "0"
    end
    
    currency = currency or "$"
    
    if amount < 1000 then
        return string.format("%s%.2f", currency, amount)
    else
        return string.format("%s%s", currency, Formatting.formatNumber(amount))
    end
end

function Formatting.formatPercentage(value, total, decimals)
    --[[
        Format Percentage
        
        Formats a value as a percentage of a total.
        
        Parameters:
        - value: The value to format
        - total: The total value (default: 100)
        - decimals: Number of decimal places (default: 1)
        
        Returns: Formatted percentage string
        Performance: O(1) with zero allocations
    --]]
    
    if not value or type(value) ~= "number" then
        return "0%"
    end
    
    total = total or 100
    decimals = decimals or 1
    
    if total == 0 then
        return "0%"
    end
    
    local percentage = (value / total) * 100
    return string.format("%." .. decimals .. "f%%", percentage)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Time Formatting: Duration and Timestamps
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Formatting.formatTime(seconds)
    --[[
        Format Time Duration
        
        Formats seconds into a human-readable time format.
        Shows hours, minutes, and seconds as appropriate.
        
        Parameters:
        - seconds: Time in seconds
        
        Returns: Formatted time string
        Performance: O(1) with zero allocations
    --]]
    
    if not seconds or type(seconds) ~= "number" then
        return "0:00"
    end
    
    seconds = math.floor(seconds)
    
    if seconds < 60 then
        return string.format("0:%02d", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        return string.format("%d:%02d", minutes, remainingSeconds)
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local remainingSeconds = seconds % 60
        return string.format("%d:%02d:%02d", hours, minutes, remainingSeconds)
    end
end

function Formatting.formatTimeShort(seconds)
    --[[
        Format Time Duration (Short)
        
        Formats seconds into a compact time format.
        Shows only the most significant units.
        
        Parameters:
        - seconds: Time in seconds
        
        Returns: Short formatted time string
        Performance: O(1) with zero allocations
    --]]
    
    if not seconds or type(seconds) ~= "number" then
        return "0s"
    end
    
    seconds = math.floor(seconds)
    
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        return string.format("%dm", minutes)
    else
        local hours = math.floor(seconds / 3600)
        return string.format("%dh", hours)
    end
end

function Formatting.formatTimestamp(timestamp)
    --[[
        Format Timestamp
        
        Formats a Unix timestamp into a readable date/time.
        
        Parameters:
        - timestamp: Unix timestamp
        
        Returns: Formatted date/time string
        Performance: O(1) with zero allocations
    --]]
    
    if not timestamp or type(timestamp) ~= "number" then
        return "Invalid"
    end
    
    -- Simple timestamp formatting (for more complex needs, use os.date)
    local days = math.floor(timestamp / 86400)
    local hours = math.floor((timestamp % 86400) / 3600)
    local minutes = math.floor((timestamp % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Text Formatting: String Manipulation
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Formatting.capitalize(str)
    --[[
        Capitalize String
        
        Capitalizes the first letter of a string.
        
        Parameters:
        - str: The string to capitalize
        
        Returns: Capitalized string
        Performance: O(1) with zero allocations
    --]]
    
    if not str or type(str) ~= "string" then
        return ""
    end
    
    if #str == 0 then
        return str
    end
    
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

function Formatting.capitalizeWords(str)
    --[[
        Capitalize Words
        
        Capitalizes the first letter of each word in a string.
        
        Parameters:
        - str: The string to capitalize
        
        Returns: String with capitalized words
        Performance: O(n) where n is the length of the string
    --]]
    
    if not str or type(str) ~= "string" then
        return ""
    end
    
    local result = ""
    local capitalizeNext = true
    
    for i = 1, #str do
        local char = str:sub(i, i)
        
        if char:match("%s") then
            capitalizeNext = true
            result = result .. char
        else
            if capitalizeNext then
                result = result .. char:upper()
                capitalizeNext = false
            else
                result = result .. char:lower()
            end
        end
    end
    
    return result
end

function Formatting.truncateText(str, maxLength, suffix)
    --[[
        Truncate Text
        
        Truncates text to a maximum length with optional suffix.
        
        Parameters:
        - str: The string to truncate
        - maxLength: Maximum length
        - suffix: Suffix to add when truncated (default: "...")
        
        Returns: Truncated string
        Performance: O(1) with zero allocations
    --]]
    
    if not str or type(str) ~= "string" then
        return ""
    end
    
    suffix = suffix or "..."
    
    if #str <= maxLength then
        return str
    end
    
    return str:sub(1, maxLength - #suffix) .. suffix
end

function Formatting.wrapText(str, maxWidth, font)
    --[[
        Wrap Text
        
        Wraps text to fit within a maximum width.
        
        Parameters:
        - str: The string to wrap
        - maxWidth: Maximum width in pixels
        - font: Font to use for measurement
        
        Returns: Array of wrapped lines
        Performance: O(n) where n is the length of the string
    --]]
    
    if not str or type(str) ~= "string" then
        return {}
    end
    
    if not font then
        font = love.graphics.getFont()
    end
    
    local lines = {}
    local currentLine = ""
    local words = {}
    
    -- Split into words
    for word in str:gmatch("%S+") do
        table.insert(words, word)
    end
    
    for i, word in ipairs(words) do
        local testLine = currentLine .. (currentLine ~= "" and " " or "") .. word
        local width = font:getWidth(testLine)
        
        if width <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
                currentLine = word
            else
                -- Word is too long, force it on its own line
                table.insert(lines, word)
                currentLine = ""
            end
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return lines
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Score Formatting: Game-Specific Formatting
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Formatting.formatScore(score)
    --[[
        Format Score
        
        Formats a game score with appropriate formatting.
        
        Parameters:
        - score: The score to format
        
        Returns: Formatted score string
        Performance: O(1) with zero allocations
    --]]
    
    if not score or type(score) ~= "number" then
        return "0"
    end
    
    if score < 1000 then
        return tostring(score)
    else
        return Formatting.formatNumber(score)
    end
end

function Formatting.formatHighScore(score, rank)
    --[[
        Format High Score
        
        Formats a high score with rank information.
        
        Parameters:
        - score: The score to format
        - rank: The rank position
        
        Returns: Formatted high score string
        Performance: O(1) with zero allocations
    --]]
    
    if not score or type(score) ~= "number" then
        return "0"
    end
    
    local scoreStr = Formatting.formatScore(score)
    
    if rank then
        return string.format("#%d: %s", rank, scoreStr)
    else
        return scoreStr
    end
end

function Formatting.formatLevel(level)
    --[[
        Format Level
        
        Formats a level number with appropriate prefix.
        
        Parameters:
        - level: The level number
        
        Returns: Formatted level string
        Performance: O(1) with zero allocations
    --]]
    
    if not level or type(level) ~= "number" then
        return "Level 1"
    end
    
    return string.format("Level %d", level)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions: Helper Methods
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Formatting.padLeft(str, length, char)
    --[[
        Pad String Left
        
        Pads a string to the left with a character.
        
        Parameters:
        - str: The string to pad
        - length: Target length
        - char: Character to pad with (default: " ")
        
        Returns: Padded string
        Performance: O(1) with zero allocations
    --]]
    
    if not str then str = "" end
    char = char or " "
    
    while #str < length do
        str = char .. str
    end
    
    return str
end

function Formatting.padRight(str, length, char)
    --[[
        Pad String Right
        
        Pads a string to the right with a character.
        
        Parameters:
        - str: The string to pad
        - length: Target length
        - char: Character to pad with (default: " ")
        
        Returns: Padded string
        Performance: O(1) with zero allocations
    --]]
    
    if not str then str = "" end
    char = char or " "
    
    while #str < length do
        str = str .. char
    end
    
    return str
end

function Formatting.centerText(str, width, char)
    --[[
        Center Text
        
        Centers text within a specified width.
        
        Parameters:
        - str: The string to center
        - width: Target width
        - char: Character to pad with (default: " ")
        
        Returns: Centered string
        Performance: O(1) with zero allocations
    --]]
    
    if not str then str = "" end
    char = char or " "
    
    local padding = width - #str
    if padding <= 0 then
        return str
    end
    
    local leftPadding = math.floor(padding / 2)
    local rightPadding = padding - leftPadding
    
    return string.rep(char, leftPadding) .. str .. string.rep(char, rightPadding)
end

return Formatting 