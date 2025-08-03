--[[
    ═══════════════════════════════════════════════════════════════════════════
    Statistical Tools - Mathematical Analysis Utilities
    ═══════════════════════════════════════════════════════════════════════════
    
    This module provides statistical analysis tools for the feedback analysis
    pipeline, including hypothesis testing, descriptive statistics, and
    effect size calculations.
--]]

local Utils = require("src.utils.utils")

local StatisticalTools = {}

-- Configuration
StatisticalTools.config = {
    confidence_level = 0.95,
    min_sample_size = 30,
    effect_size_thresholds = {
        small = 0.2,
        medium = 0.5,
        large = 0.8
    }
}

-- Descriptive Statistics
function StatisticalTools.mean(data)
    if not data or #data == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(data) do 
        sum = sum + v 
    end
    return sum / #data
end

function StatisticalTools.variance(data, mean_val)
    if not data or #data < 2 then return 0 end
    local sum = 0
    for _, v in ipairs(data) do 
        sum = sum + (v - mean_val)^2 
    end
    return sum / (#data - 1)
end

function StatisticalTools.standardDeviation(data, mean_val)
    return math.sqrt(StatisticalTools.variance(data, mean_val))
end

function StatisticalTools.median(data)
    if not data or #data == 0 then return 0 end
    
    local sorted = {}
    for i, v in ipairs(data) do sorted[i] = v end
    table.sort(sorted)
    
    local n = #sorted
    if n % 2 == 0 then
        return (sorted[n/2] + sorted[n/2 + 1]) / 2
    else
        return sorted[math.ceil(n/2)]
    end
end

function StatisticalTools.percentile(data, p)
    if not data or #data == 0 then return 0 end
    if p < 0 or p > 1 then return 0 end
    
    local sorted = {}
    for i, v in ipairs(data) do sorted[i] = v end
    table.sort(sorted)
    
    local n = #sorted
    local index = p * (n - 1) + 1
    local lower = math.floor(index)
    local upper = math.ceil(index)
    
    if lower == upper then
        return sorted[lower]
    else
        local weight = index - lower
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    end
end

-- Hypothesis Testing

-- Chi-square test for goodness of fit
function StatisticalTools.chiSquareTest(observed, expected)
    if not observed or not expected or #observed ~= #expected then
        return {error = "Invalid input data"}
    end
    
    local chiSquare = 0
    local df = #observed - 1
    
    for i = 1, #observed do
        if expected[i] > 0 then
            chiSquare = chiSquare + ((observed[i] - expected[i])^2) / expected[i]
        end
    end
    
    -- Simplified p-value calculation (would use proper lookup table in production)
    local pValue = chiSquare > 3.841 and 0.05 or 0.1 -- Rough approximation
    
    return {
        chi_square = chiSquare,
        degrees_of_freedom = df,
        p_value = pValue,
        significant = pValue < 0.05
    }
end

-- T-test for comparing means
function StatisticalTools.tTest(sample1, sample2)
    if not sample1 or not sample2 or #sample1 < 2 or #sample2 < 2 then
        return {error = "Insufficient sample size"}
    end
    
    local mean1, mean2 = StatisticalTools.mean(sample1), StatisticalTools.mean(sample2)
    local var1, var2 = StatisticalTools.variance(sample1, mean1), StatisticalTools.variance(sample2, mean2)
    local n1, n2 = #sample1, #sample2
    
    local pooledVar = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
    local standardError = math.sqrt(pooledVar * (1/n1 + 1/n2))
    local tStatistic = (mean1 - mean2) / standardError
    
    -- Simplified significance test
    local significant = math.abs(tStatistic) > 2.0
    
    return {
        t_statistic = tStatistic,
        p_value = significant and 0.04 or 0.2, -- Rough approximation
        significant = significant,
        effect_size = math.abs(mean1 - mean2) / math.sqrt(pooledVar)
    }
end

-- Correlation analysis
function StatisticalTools.correlation(x, y)
    if not x or not y or #x ~= #y or #x < 2 then
        return {error = "Invalid input data"}
    end
    
    local meanX, meanY = StatisticalTools.mean(x), StatisticalTools.mean(y)
    local sumXY = 0
    local sumX2 = 0
    local sumY2 = 0
    
    for i = 1, #x do
        local dx = x[i] - meanX
        local dy = y[i] - meanY
        sumXY = sumXY + dx * dy
        sumX2 = sumX2 + dx * dx
        sumY2 = sumY2 + dy * dy
    end
    
    if sumX2 == 0 or sumY2 == 0 then
        return {correlation = 0, strength = "none"}
    end
    
    local correlation = sumXY / math.sqrt(sumX2 * sumY2)
    
    local strength = "weak"
    if math.abs(correlation) > 0.7 then strength = "strong"
    elseif math.abs(correlation) > 0.3 then strength = "moderate"
    end
    
    return {
        correlation = correlation,
        strength = strength,
        significant = math.abs(correlation) > 0.3 -- Simplified significance
    }
end

-- Effect Size Analysis
function StatisticalTools.cohensD(sample1, sample2)
    if not sample1 or not sample2 then return 0 end
    
    local mean1, mean2 = StatisticalTools.mean(sample1), StatisticalTools.mean(sample2)
    local var1, var2 = StatisticalTools.variance(sample1, mean1), StatisticalTools.variance(sample2, mean2)
    local n1, n2 = #sample1, #sample2
    
    local pooledVar = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
    local pooledSD = math.sqrt(pooledVar)
    
    if pooledSD == 0 then return 0 end
    
    local cohensD = math.abs(mean1 - mean2) / pooledSD
    
    local magnitude = "small"
    if cohensD > StatisticalTools.config.effect_size_thresholds.large then
        magnitude = "large"
    elseif cohensD > StatisticalTools.config.effect_size_thresholds.medium then
        magnitude = "medium"
    end
    
    return {
        cohens_d = cohensD,
        magnitude = magnitude
    }
end

-- Confidence Interval Calculation
function StatisticalTools.confidenceInterval(data, confidence)
    if not data or #data < 2 then
        return {error = "Insufficient data"}
    end
    
    confidence = confidence or StatisticalTools.config.confidence_level
    
    local mean = StatisticalTools.mean(data)
    local stdError = StatisticalTools.standardDeviation(data, mean) / math.sqrt(#data)
    
    -- Simplified critical value (would use proper t-distribution in production)
    local criticalValue = 1.96 -- Approximate for 95% confidence
    
    local marginOfError = criticalValue * stdError
    
    return {
        mean = mean,
        lower_bound = mean - marginOfError,
        upper_bound = mean + marginOfError,
        margin_of_error = marginOfError,
        confidence_level = confidence
    }
end

-- Sample Size Calculation
function StatisticalTools.calculateSampleSize(marginOfError, confidence, populationStdDev)
    confidence = confidence or StatisticalTools.config.confidence_level
    populationStdDev = populationStdDev or 1 -- Default to 1 if unknown
    
    -- Simplified critical value
    local criticalValue = 1.96 -- Approximate for 95% confidence
    
    local sampleSize = math.ceil((criticalValue * populationStdDev / marginOfError)^2)
    
    return math.max(sampleSize, StatisticalTools.config.min_sample_size)
end

-- Data Validation
function StatisticalTools.validateData(data, minSize)
    minSize = minSize or StatisticalTools.config.min_sample_size
    
    if not data then
        return false, "Data is nil"
    end
    
    if type(data) ~= "table" then
        return false, "Data is not a table"
    end
    
    if #data < minSize then
        return false, string.format("Insufficient sample size: %d < %d", #data, minSize)
    end
    
    -- Check for non-numeric values
    for i, value in ipairs(data) do
        if type(value) ~= "number" or value ~= value then -- Check for NaN
            return false, string.format("Invalid value at index %d: %s", i, tostring(value))
        end
    end
    
    return true, "Valid data"
end

-- Outlier Detection
function StatisticalTools.detectOutliers(data, method)
    method = method or "iqr" -- Interquartile Range method
    
    if method == "iqr" then
        local q1 = StatisticalTools.percentile(data, 0.25)
        local q3 = StatisticalTools.percentile(data, 0.75)
        local iqr = q3 - q1
        local lowerBound = q1 - 1.5 * iqr
        local upperBound = q3 + 1.5 * iqr
        
        local outliers = {}
        for i, value in ipairs(data) do
            if value < lowerBound or value > upperBound then
                table.insert(outliers, {index = i, value = value})
            end
        end
        
        return outliers
    end
    
    return {}
end

return StatisticalTools 