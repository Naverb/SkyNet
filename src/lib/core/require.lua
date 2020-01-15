--[[
    This is a revamped module loading system for skynet. It more faithfully resembles the Lua `require` function. When calling require, the system loads a module into the scope of the file.

    The difference between this and vanilla require is that loaded modules are not loaded into global scope.
]]

_MODULES = _MODULES or {}

local function getFileName(path)
    local filename = fs.getName(path)
    if string.sub(filename, -4) == '.lua' then
        return string.sub(filename, 1, -5)
    else
        return filename
    end
end

local function normalizePath(path)
    if string.sub(path,1,1) == '/' then
        return string.sub(path,2)
    else
        return path
    end
end

local function loadModule(path)
    -- If the module at path is already loaded, then return a cached version. If not, load the module from storage.
    local module
    local result

    if _MODULES[path] then
        module = _MODULES[path]
    else
        -- In this case, we need to load the module from storage
        local module_env = {}

        setmetatable(module_env, {__index = getfenv() })

        local module_runner, err_loadfile = loadfile(path, module_env)
        local ok
        ok, result = pcall( module_runner )

        if not ok then
            error('Error loading module:  \n> Module: ' .. path .. '\n> Loadfile: ' .. tostring(err_loadfile) .. '\n> Init: ' .. tostring(result),0)
        else
            for k,v in pairs(module_env) do
                if k ~= '_ENV' then
                    module[k] = v
                end
            end
        end

        local filename = fs.getName(path)
        if string.sub(filename, -4) == '.lua' then
            module.__name = string.sub(filename,1,-5)
            module.__path = normalizePath(path)
        else
            module.__name = filename
            module.__path = normalizePath(path)
        end

    end

    return module,result
end

function require(module_path)
    -- Load a module (lua file) at the specified path. If that module is already loaded, return a cached version of the module to ensure code is never ran twice.
    local loaded_module, result = loadModule(module_path)
    local calling_file_env = getfenv()

    for k,_ in pairs(loaded_module) do
        if calling_file_env[k] then
            error("Tried to overwrite variable " .. k .. " with a module's verision")
        end
    end

    for k,v in pairs(loaded_module) do
        if not calling_file_env[k] then
            calling_file_env[k] = v
        end
    end

    return result
end

function clear_module_cache()
    _MODULES = {}
end
