--[[
    A module loading system for computercraft that is loosely based on Node.JS's module.js
    (C) Anthony D'Arienzo
]]

module_cache = module_cache or {} -- This module_cache appears to persist across program runs. Perhaps we want to clear this on boot?

function clear_module_cache()
    module_cache = {}
end

function require(file)
-- Load a module from a filepath.
    local module

    local function loadFromStorage(file)
        -- The file exists, let's load it.
        local module = {}
        local module_env = {}
        setmetatable(module_env, { __index = _G })
        filename = fs.getName(file)
        if string.sub(filename, -4) == '.lua' then
            module.__name = string.sub(filename,1,-5)
            module.__path = file
        else
            module.__name = filename
            module.__path = file
        end

        module_func = loadfile(file, module_env)

        local ok, err = pcall( module_func )

        if not ok then
            error('Error in pcall, module_func')
        else
            for k,v in pairs(module_env) do
                if k ~= '_ENV' then
                    module[k] = v
                end
            end

            return module
        end
        error('Unable to load module ' .. file .. ' from storage.')
    end

    local function loadFromSystem(file)
        if not fs.exists(file) then
            error('Unable to find module ' .. file ..'.')
        else
            -- A file of name file exists, so let's load it.
            module = loadFromStorage(file)
            return module
        end
        error('Unknown error loading module ' .. file .. '.')
    end

    if type(file) ~= 'string' then
        error('loadmodule requires a string as argument.')
    end

    if not module_cache[file] then
        module = loadFromSystem(file)
        module_cache[module.__path] = module
    else
        -- Load the module from module_cache
        module = module_cache[file]
    end

    return module
end

return {
    require = require,
    clear_module_cache = clear_module_cache
}
