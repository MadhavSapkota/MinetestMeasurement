
-- Improved caching mechanism with debug info control based on execution environment
local origin_cache = {}
local function get_origin(callback)
    local callback_id = tostring(callback)
    local origin = origin_cache[callback_id]
    if not origin then
        local debug_info = debug.getinfo(callback, "n")
        origin = {
            mod = core.get_current_modname() or "??",
            name = debug_info and debug_info.name or "??"
        }
        origin_cache[callback_id] = origin
    end
    return origin
end

function core.set_last_run_mod_from_cache(callback)
    local origin = get_origin(callback)
    core.set_last_run_mod(origin.mod)
end

-- Optimized single handler for all modes with reduced complexity
local function handle_callbacks(callbacks, mode, ...)
    local response, condition_met
    for i, callback in ipairs(callbacks) do
        local result = callback(...)
        if mode == 0 and i == 1 then return result end
        if mode == 1 and i == #callbacks then return result end
        if mode == 2 and not result then return result end
        if mode == 3 and result then return result end
        if mode >= 4 and result then return result end
    end
    return mode == 2 or mode == 3 and false or nil
end

function core.run_callbacks(callbacks, mode, ...)
    assert(type(callbacks) == "table", "Invalid input type for callbacks: " .. type(callbacks))
    return handle_callbacks(callbacks, mode, ...)
end

-- Unified registration function handling both direct and reverse insertion
local function make_registration(is_reverse)
    local t = {}
    local function register(func)
        if is_reverse then
            table.insert(t, 1, func) -- insert at beginning for reverse order
        else
            table.insert(t, func) -- append to end for normal order
        end
    end
    return t, register
end

builtin_shared.make_registration = function() return make_registration(false) end
builtin_shared.make_registration_reverse = function() return make_registration(true) end










