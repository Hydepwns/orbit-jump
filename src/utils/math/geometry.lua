--[[
    Geometry Utilities for Orbit Jump
    
    This module provides collision detection and geometric calculations
    for game objects, planets, and spatial relationships.
--]]

local Vector = require("src.utils.math.vector")

local Geometry = {}

function Geometry.circleCollision(x1, y1, r1, x2, y2, r2)
    --[[
        Circle-Circle Collision Detection
        
        Determines if two circles are colliding by checking if the distance
        between their centers is less than the sum of their radii.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x1 or not y1 or not r1 or not x2 or not y2 or not r2 then
        return false
    end
    
    local distance = Vector.distance(x1, y1, x2, y2)
    return distance < (r1 + r2)
end

function Geometry.ringCollision(x, y, radius, ringX, ringY, ringRadius, ringInnerRadius)
    --[[
        Point-Ring Collision Detection
        
        Determines if a point is within a ring (annulus) by checking if it's
        within the outer radius but outside the inner radius.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not radius or not ringX or not ringY or not ringRadius or not ringInnerRadius then
        return false
    end
    
    local distance = Vector.distance(x, y, ringX, ringY)
    return distance >= ringInnerRadius and distance <= ringRadius
end

function Geometry.pointInRect(x, y, rectX, rectY, rectWidth, rectHeight)
    --[[
        Point-Rectangle Collision Detection
        
        Determines if a point is within a rectangle by checking if it's
        within the rectangle's bounds.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not rectX or not rectY or not rectWidth or not rectHeight then
        return false
    end
    
    return x >= rectX and x <= rectX + rectWidth and
           y >= rectY and y <= rectY + rectHeight
end

function Geometry.lineIntersectsCircle(lineX1, lineY1, lineX2, lineY2, circleX, circleY, circleRadius)
    --[[
        Line-Circle Intersection Detection
        
        Determines if a line segment intersects with a circle.
        Uses the closest point on the line to the circle center.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not lineX1 or not lineY1 or not lineX2 or not lineY2 or 
       not circleX or not circleY or not circleRadius then
        return false
    end
    
    -- Vector from line start to end
    local dx = lineX2 - lineX1
    local dy = lineY2 - lineY1
    
    -- Vector from line start to circle center
    local fx = circleX - lineX1
    local fy = circleY - lineY1
    
    -- Project circle center onto line
    local dot = fx * dx + fy * dy
    local lineLengthSq = dx * dx + dy * dy
    
    if lineLengthSq == 0 then
        -- Line is a point, check distance to circle center
        return Vector.distance(lineX1, lineY1, circleX, circleY) <= circleRadius
    end
    
    local t = Vector.clamp(dot / lineLengthSq, 0, 1)
    
    -- Closest point on line to circle center
    local closestX = lineX1 + t * dx
    local closestY = lineY1 + t * dy
    
    -- Check distance from closest point to circle center
    return Vector.distance(closestX, closestY, circleX, circleY) <= circleRadius
end

function Geometry.circleIntersectsRect(circleX, circleY, circleRadius, rectX, rectY, rectWidth, rectHeight)
    --[[
        Circle-Rectangle Intersection Detection
        
        Determines if a circle intersects with a rectangle by finding
        the closest point on the rectangle to the circle center.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not circleX or not circleY or not circleRadius or 
       not rectX or not rectY or not rectWidth or not rectHeight then
        return false
    end
    
    -- Find closest point on rectangle to circle center
    local closestX = Vector.clamp(circleX, rectX, rectX + rectWidth)
    local closestY = Vector.clamp(circleY, rectY, rectY + rectHeight)
    
    -- Check distance from closest point to circle center
    return Vector.distance(closestX, closestY, circleX, circleY) <= circleRadius
end

function Geometry.getCircleArea(radius)
    --[[
        Circle Area Calculation
        
        Calculates the area of a circle.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not radius then return 0 end
    return math.pi * radius * radius
end

function Geometry.getRingArea(outerRadius, innerRadius)
    --[[
        Ring Area Calculation
        
        Calculates the area of a ring (annulus).
        
        Performance: O(1) with zero allocations
    --]]
    
    if not outerRadius or not innerRadius then return 0 end
    if outerRadius <= innerRadius then return 0 end
    
    return math.pi * (outerRadius * outerRadius - innerRadius * innerRadius)
end

function Geometry.getRectArea(width, height)
    --[[
        Rectangle Area Calculation
        
        Calculates the area of a rectangle.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not width or not height then return 0 end
    return width * height
end

function Geometry.getCircleCircumference(radius)
    --[[
        Circle Circumference Calculation
        
        Calculates the circumference of a circle.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not radius then return 0 end
    return 2 * math.pi * radius
end

function Geometry.getRectPerimeter(width, height)
    --[[
        Rectangle Perimeter Calculation
        
        Calculates the perimeter of a rectangle.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not width or not height then return 0 end
    return 2 * (width + height)
end

function Geometry.isPointInPolygon(pointX, pointY, polygon)
    --[[
        Point-in-Polygon Detection (Ray Casting Algorithm)
        
        Determines if a point is inside a polygon using the ray casting algorithm.
        The polygon is defined as a table of {x, y} points.
        
        Performance: O(n) where n is the number of polygon vertices
    --]]
    
    if not pointX or not pointY or not polygon or #polygon < 3 then
        return false
    end
    
    local inside = false
    local j = #polygon
    
    for i = 1, #polygon do
        local vertexI = polygon[i]
        local vertexJ = polygon[j]
        
        if not vertexI or not vertexJ then
            return false
        end
        
        if ((vertexI.y > pointY) ~= (vertexJ.y > pointY)) and
           (pointX < (vertexJ.x - vertexI.x) * (pointY - vertexI.y) / (vertexJ.y - vertexI.y) + vertexI.x) then
            inside = not inside
        end
        
        j = i
    end
    
    return inside
end

function Geometry.getBoundingBox(points)
    --[[
        Bounding Box Calculation
        
        Calculates the bounding box (minimum and maximum coordinates)
        for a set of points.
        
        Returns: {minX, minY, maxX, maxY}
        Performance: O(n) where n is the number of points
    --]]
    
    if not points or #points == 0 then
        return {minX = 0, minY = 0, maxX = 0, maxY = 0}
    end
    
    local minX, minY = points[1].x, points[1].y
    local maxX, maxY = points[1].x, points[1].y
    
    for i = 2, #points do
        local point = points[i]
        if point then
            minX = math.min(minX, point.x)
            minY = math.min(minY, point.y)
            maxX = math.max(maxX, point.x)
            maxY = math.max(maxY, point.y)
        end
    end
    
    return {minX = minX, minY = minY, maxX = maxX, maxY = maxY}
end

function Geometry.getCircleBoundingBox(centerX, centerY, radius)
    --[[
        Circle Bounding Box Calculation
        
        Calculates the bounding box for a circle.
        
        Returns: {minX, minY, maxX, maxY}
        Performance: O(1) with zero allocations
    --]]
    
    if not centerX or not centerY or not radius then
        return {minX = 0, minY = 0, maxX = 0, maxY = 0}
    end
    
    return {
        minX = centerX - radius,
        minY = centerY - radius,
        maxX = centerX + radius,
        maxY = centerY + radius
    }
end

return Geometry 