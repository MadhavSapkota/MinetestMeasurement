
-- Localize functions for faster access
local setmetatable = setmetatable
local sqrt = math.sqrt
local assert = assert
local type = type
local tonumber = tonumber
local string_match = string.match
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local math_sin = math.sin
local math_cos = math.cos
local math_atan2 = math.atan2
local format = string.format

local vector = {}
local metatable = {}

local xyz = {x = "x", y = "y", z = "z"}

function metatable.__index(v, key)
    return v[xyz[key]] or vector[key]
end

function metatable.__newindex(v, key, value)
    v[xyz[key] or key] = value
end

local function new_vector(x, y, z)
    return setmetatable({x = x, y = y, z = z}, metatable)
end

-- Vector construction functions
function vector.new(a, b, c)
    if type(a) == "table" then
        return new_vector(a.x, a.y, a.z)
    elseif a and b and c then
        return new_vector(a, b, c)
    else
        return new_vector(0, 0, 0)
    end
end

function vector.zero()
    return new_vector(0, 0, 0)
end

function vector.copy(v)
    return new_vector(v.x, v.y, v.z)
end

function vector.from_string(s)
    local x, y, z = string_match(s, "%s*%(%s*([^%s,]+)%s*,%s*([^%s,]+)%s*,%s*([^%s,]+)%s*%)")
    return new_vector(tonumber(x), tonumber(y), tonumber(z))
end

function vector.to_string(v)
    return format("(%g, %g, %g)", v.x, v.y, v.z)
end

metatable.__tostring = vector.to_string
metatable.__eq = function(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

-- Unary operations
function vector.length(v)
    return sqrt(v.x^2 + v.y^2 + v.z^2)
end

function vector.normalize(v)
    local len = vector.length(v)
    if len == 0 then
        return vector.zero()
    end
    return vector.divide(v, len)
end

function vector.floor(v)
    return new_vector(math_floor(v.x), math_floor(v.y), math_floor(v.z))
end

-- Apply a function to all components of a vector
function vector.apply(v, func)
    return new_vector(func(v.x), func(v.y), func(v.z))
end

-- Binary operations
function vector.add(a, b)
    if type(b) == "table" then
        return new_vector(a.x + b.x, a.y + b.y, a.z + b.z)
    else
        return new_vector(a.x + b, a.y + b, a.z + b)
    end
end

function vector.subtract(a, b)
    if type(b) == "table" then
        return new_vector(a.x - b.x, a.y - b.y, a.z - b.z)
    else
        return new_vector(a.x - b, a.y - b, a.z - b)
    end
end

function vector.multiply(a, b)
    if type(b) == "table" then
        return new_vector(a.x * b.x, a.y * b.y, a.z * b.z)
    else
        return new_vector(a.x * b, a.y * b, a.z * b)
    end
end

function vector.divide(a, b)
    if type(b) == "table" then
        return new_vector(a.x / b.x, a.y / b.y, a.z / b.z)
    else
        return new_vector(a.x / b, a.y / b, a.z / b)
    end
end

-- Adding metatable operations
metatable.__add = vector.add
metatable.__sub = vector.subtract
metatable.__mul = vector.multiply
metatable.__div = vector.divide
metatable.__unm = function(v)
    return new_vector(-v.x, -v.y, -v.z)
end

return vector
