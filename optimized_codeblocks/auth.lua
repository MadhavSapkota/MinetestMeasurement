-- -- Minetest: builtin/auth.lua


-- Make the auth object private, deny access to mods
local core_auth = core.auth
core.auth = nil

-- Caching frequent data
local cached_singleplayer_privileges = nil
local cached_admin_privileges = nil
local cached_default_privileges = nil

local function get_singleplayer_privileges()
    if not cached_singleplayer_privileges then
        cached_singleplayer_privileges = {}
        for priv, def in pairs(core.registered_privileges) do
            if def.give_to_singleplayer then
                cached_singleplayer_privileges[priv] = true
            end
        end
    end
    return cached_singleplayer_privileges
end

local function get_admin_privileges()
    if not cached_admin_privileges then
        cached_admin_privileges = {}
        for priv, def in pairs(core.registered_privileges) do
            if def.give_to_admin then
                cached_admin_privileges[priv] = true
            end
        end
    end
    return cached_admin_privileges
end

local function get_default_privileges()
    if not cached_default_privileges then
        cached_default_privileges = core.string_to_privs(core.settings:get("default_privs"))
    end
    return cached_default_privileges
end

local lower_name_map = {}

local function apply_privileges(target_privileges, source_privileges)
    for priv, value in pairs(source_privileges) do
        target_privileges[priv] = value
    end
end

core.builtin_auth_handler = {
    get_auth = function(name)
        assert(type(name) == "string")
        local auth_entry = core_auth.read(name)
        if not auth_entry then
            return nil
        end
        local privileges = {}
        for priv, _ in pairs(auth_entry.privileges) do
            privileges[priv] = true
        end
        if core.is_singleplayer() then
            apply_privileges(privileges, get_singleplayer_privileges())
        elseif name == core.settings:get("name") then
            apply_privileges(privileges, get_admin_privileges())
        end
        return {
            password = auth_entry.password,
            privileges = privileges,
            last_login = auth_entry.last_login,
        }
    end,
    create_auth = function(name, password)
        assert(type(name) == "string")
        assert(type(password) == "string")
        return core_auth.create({
            name = name,
            password = password,
            privileges = get_default_privileges(),
            last_login = -1,
        })
    end,
    delete_auth = function(name)
        assert(type(name) == "string")
        return core_auth.delete(name)
    end,
    set_password = function(name, password)
        assert(type(name) == "string")
        assert(type(password) == "string")
        local auth_entry = core_auth.read(name)
        if not auth_entry then
            return false
        end
        auth_entry.password = password
        core_auth.save(auth_entry)
        return true
    end,
    set_privileges = function(name, privileges)
        assert(type(name) == "string")
        assert(type(privileges) == "table")
        local auth_entry = core_auth.read(name)
        if not auth_entry then
            return false
        end
        auth_entry.privileges = privileges
        core_auth.save(auth_entry)
        return true
    end,
    reload = function()
        core_auth.reload()
        return true
    end,
    record_login = function(name)
        assert(type(name) == "string")
        local auth_entry = core_auth.read(name)
        assert(auth_entry)
        auth_entry.last_login = os.time()
        core_auth.save(auth_entry)
    end,
}

core.register_on_prejoinplayer(function(name, ip)
    if core.registered_auth_handler then
        return -- Don't do anything if custom auth handler is registered
    end
    local name_lower = name:lower()
    if lower_name_map[name_lower] then
        return string.format("\nCannot create new player called '%s'. " ..
                "Another account called '%s' is already registered. " ..
                "Please check the spelling if it's your account " ..
                "or use a different nickname.", name, name_lower)
    end
    -- Update map if not found
    lower_name_map[name_lower] = true
end)

function core.register_authentication_handler(handler)
    if core.registered_auth_handler then
        error("Add-on authentication handler already registered by "..core.registered_auth_handler_modname)
    end
    core.registered_auth_handler = handler
    core.registered_auth_handler_modname = core.get_current_modname()
    handler.mod_origin = core.registered_auth_handler_modname
end

function core.get_auth_handler()
    return core.registered_auth_handler or core.builtin_auth_handler
end

minetest.register_globalstep(function(dtime)
    -- Periodic cleanup or refresh tasks can be added here if needed
    -- This can be used for batch processing of queued updates or lazy loading mechanisms
end)

core.register_on_joinplayer(function(player)
    -- Assuming record_login is still necessary, simplified to:
    core.builtin_auth_handler.record_login(player:get_player_name())
end)
