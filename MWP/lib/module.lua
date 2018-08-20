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

    local function getFileName(path)
        local filename = fs.getName(path)
        if string.sub(filename, -4) == '.lua' then
            return string.sub(filename, 1, -5)
        else
            return filename
        end
    end

    local function loadFromStorage(file)
        -- The file exists, let's load it.
        local module = {}
        local module_env = {}
        setmetatable(module_env, { __index = _G })
        local filename = fs.getName(file)
        if string.sub(filename, -4) == '.lua' then
            module.__name = string.sub(filename,1,-5)
            module.__path = file
        else
            module.__name = filename
            module.__path = file
        end

        local module_func, err_loadfile = loadfile(file, module_env)

        local ok, err_pcall = pcall( module_func )

        if not ok then
            error('Error in pcall, module_func: \n -->' .. tostring(err_loadfile) .. '\n -->' .. tostring(err_pcall))
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

    local function processTree(path,addToCache)
        if not module_cache[path] then
            if fs.isDir(path) then
                local package = {}
                foundFiles = fs.find(path .. '/*')
                for _,fileTreeElement in ipairs(foundFiles) do
                    local filename = getFileName(fileTreeElement)
                    if string.sub(filename,1,1) ~= '.' then
                        -- We check if the file is a hidden file that should not
                        -- be loaded.
                        local item = processTree(fileTreeElement,false)
                        package[filename] = item
                    end
                end

                local filename = getFileName(path)
                package.__name = filename
                package.__path = path

                if addToCache then
                    module_cache[package.__path] = package
                end
                return package
            else
                return process(path,addToCache)
            end
        else
            return module_cache[path]
        end
    end

    if type(file) ~= 'string' then
        error('loadmodule requires a string as argument.')
    end

    return processTree(file, true)
end

return {
    require = require,
    clear_module_cache = clear_module_cache
}
