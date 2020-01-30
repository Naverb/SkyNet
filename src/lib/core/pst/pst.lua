--[[

    ======================================================================
    ===================== SKYNET PERSISTENCE LIBRARY =====================
    ======================================================================

    When the persistence system initializes, it will scan the computer for
    .pfs files in order to assemble the topological structure of the
    persistent file system. As .pst files are loaded, this program will
    assign pointers to references *(REF) found in the .pst files. Finally,
    this program will create the interface to read the persistence data and
    to write to the system.
]]

PERSISTENCE_ROOT = config.findConfiguration('persistence')['PERSISTENCE_ROOT']

local persistent_variable_cache
local links = {}
local paths = {}

local function findPFSs(start_dir)
    local PFSs = {}

    local children = fs.list(start_dir)
    for _,child in ipairs(children) do
        if not fs.isDir(fs.combine(start_dir,child)) and not string.find(child,'%.pfs$') then
            -- If the above evaluates to true, then child is not a directory,
            -- and it ends with the extension .pfs
            table.insert(PFSs,fs.combine(start_dir,child))
        else
            -- In this case, child is a directory
            for _,PFS in ipairs(findPFSs(fs.combine(start_dir,child))) do
                table.insert(PFSs,PFS)
            end
        end
    end

    return PFSs
end

--- Run this function at startup to initialize the persistence filesystem, setting the persistent variable cache to whatever table is passed to `target_cache`
--- @param target_cache table
function generate(target_cache)
    persistent_variable_cache = target_cache or {}
    if not fs.exists(PERSISTENCE_ROOT) then
        try {
            body = function()
                fs.makeDir(PERSISTENCE_ROOT)
            end
        }
    end

    local PFSs = findPFSs(PERSISTENCE_ROOT)

    for _, PFS in ipairs(PFSs) do
        local file = fs.open(PFS,'r')
        local body = try {
            body = function ()
                return file.readAll()
            end,
            finally = function ()
                file.close()
            end
        }
        local contents = textutils.unserialize(body)

        persistent_variable_cache[contents.ref] = contents.data
        links[contents.ref] = contents.links
        paths[contents.ref] = PFS
    end

    -- Now that all PFS files have been loaded, we reconstruct the topological structure.

    for ref,var in pairs(persistent_variable_cache) do
        if links[ref] ~= nil then
            for key,target_ref in pairs(links[ref]) do
                var[key] = persistent_variable_cache[target_ref]
            end
        end
    end
end

--- Get the value of the persistent variable with label "key"
function get(key)
    local varpath = fs.combine(PERSISTENCE_ROOT,key)
    if fs.exists(varpath) then
        local file = fs.open(varpath,"r")

        local value = try {
            body = function ()
                local results = file.readAll()
                return results
            end,
            catch = function (ex)
                Exception:new('Failed to read the value of the persistence variable ' .. key):throw()
            end,
            finally = function()
                file.close()
            end
        }

        value = textutils.unserialize(value)
        return value
    else
        return nil
    end
end

--- Set the value of the persistence variable with label "key" and value "var"
function set(key,value)

    -- We first test whether the value we are about to write is not too complicated for the persistence filesystem.
    local serialized_value = textutils.serialize(value)
    local varpath = fs.combine(PERSISTENCE_ROOT,key)
    local file = fs.open(varpath,"w")
    try {
        body = function()
            file.write(serialized_value)
        end,
        finally = function()
            file.close()
        end
    }
end

--- Delete the persistence variable with label "key"
--- If an Exception is caught during deletion, do not remove the persistent variable from cache.
--- @param key string
function delete(key)

    local data = persistent_variable_cache[key]
    local linked_data = links[key]
    local varpath = paths[key]


    try {
        body = function ()
            persistent_variable_cache[key] = nil
            paths[key] = nil
            links[key] = nil
            fs.delete(varpath)
        end,
        ---@param ex Exception
        catch = function(ex)
            ex:changeType('PersistenceVarException')

            -- Since we failed to delete the persistent_variable, do not delete.
            persistent_variable_cache[key] = data
            links[key] = linked_data
            paths[key] = varpath

            ex:throw()
        end
    }
end
