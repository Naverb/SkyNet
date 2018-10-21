--[[
    A module loading system for computercraft that is loosely based on Node.JS's module.js
]]

module_cache = module_cache or {} -- This module_cache appears to persist across program runs. Perhaps we want to clear this on boot?

function clear_module_cache()
    module_cache = {}
end

function exportFunction(func)
    local wrappedFunc = function(t,...)
        return func(...)
    end
    local wrappingTable = {func = func}
    local mt = { __call = wrappedFunc } -- The first parameter is the table being called.
    setmetatable(wrappingTable,mt)

    return wrappingTable
end

function require(file)
-- Load a module from a filepath.
    local module

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

    local function loadFromStorage(file)
        -- The file exists, let's load it.
        local module = {}
        local module_env = {}

        setmetatable(module_env, { __index = getfenv() })

        local module_func, err_loadfile = loadfile(file, module_env)

        local ok, err_pcall = pcall( module_func )

        if not ok then
            error('Error loading module:  \n> Module: ' .. file .. '\n> Loadfile: ' .. tostring(err_loadfile) .. '\n> Init: ' .. tostring(err_pcall),0)
        else

            if module_env._module then
                -- If the _module variable is defined, we load that as the module.
                module = module_env._module
            else
                -- If the _module variable is not defined, load all global
                -- variables into the module.
                for k,v in pairs(module_env) do
                    if k ~= '_ENV' then
                        module[k] = v
                    end
                end
            end

            local filename = fs.getName(file)
            if string.sub(filename, -4) == '.lua' then
                module.__name = string.sub(filename,1,-5)
                module.__path = normalizePath(file)
            else
                module.__name = filename
                module.__path = normalizePath(file)
            end

            return module
        end
        error('Unable to load module ' .. file .. ' from storage.',0)
    end

    local function loadFromSystem(file)
        if not fs.exists(file) then
            error('Unable to find module ' .. file ..'.',0)
        else
            -- A file of name file exists, so let's load it.
            module = loadFromStorage(file)
            return module
        end
        error('Unknown error loading module ' .. file .. '.',0)
    end

    local function process(path,addToCache)
        if not module_cache[path] then
            module = loadFromSystem(path)
            if addToCache then
                module_cache[module.__path] = module
            end
        else
            -- Load the module from module_cache
            module = module_cache[path]
        end

        return module
    end

    local function ignoreThisFile(file)
        if string.sub(file,1,1) == '.' then
            return true
        elseif string.sub(file,-4) == '.doc' then
            return true
        elseif string.sub(file,1,2) == '__' then
            return true
        else
            return false
        end
    end

    local function processTree(path,addToCache)
        if not module_cache[path] then
            if fs.isDir(path) then
                local package = {}
                foundFiles = fs.find(path .. '/*')
                for _,fileTreeElement in ipairs(foundFiles) do
                    local filename = fs.getName(fileTreeElement)
                    if not ignoreThisFile(filename) then
                        filename = getFileName(fileTreeElement)
                        -- We check if the file is a hidden file that should not
                        -- be loaded.
                        local item = processTree(fileTreeElement,true) -- Is there any reason we should not add to cache?
                        package[filename] = item
                    end
                end

                local filename = getFileName(path)
                package.__name = filename
                package.__path = normalizePath(path)

                if addToCache then
                    module_cache[package.__path] = package
                end
                return package
            else
                --[[
                    To ensure that we don't load the same module twice, we
                    normalize the format of the path to prevent slight formatting
                    differences to inhibit the module APIs ability to identify
                    already loaded modules.

                    I.e.

                    lib/foo and /lib/foo are the same path, so if lib/foo is
                    loaded, then /lib/foo is loaded.
                ]]
                return process(normalizePath(path),addToCache)
            end
        else
            return module_cache[path]
        end
    end

    if type(file) ~= 'string' then
        error('loadmodule requires a string as argument.',2)
    end

    local ok, data = pcall(processTree, file, true)

    if not ok then
        error(data, 2)
    else
        return data
    end
end

if IS_LOADER then
    print('> Skynet loader detected. Modifying module.require environment.')
    setfenv(require, getfenv(1)) -- Layer 1 is the calling function (the skynet loader).
else
    print('No skynet loader detected.')
end

return {
    require = require,
    clear_module_cache = clear_module_cache,
    exportFunction = exportFunction
}
