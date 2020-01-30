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
PSTVar = module.require('/lib/core/pst/PSTVar.lua')

local persistent_variable_cache = {}
setmetatable(persistent_variable_cache,{
    __newindex = function(t,k,v)
        t[label] = PSTVar:new {
            ref = k,
            path = fs.combine(PERSISTENCE_ROOT,k .. '.pfs'),
            data = v
        }
    end
})

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

--- Run this function at startup to initialize the persistence filesystem.
function generate()
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

        local new_pstvar = PSTVar:new {
            ref = contents.ref,
            path = PFS,
            data = contents.data,
            links = contents.links
        }

        persistent_variable_cache[contents.ref] = new_pstvar
    end

    -- Now that all PFS files have been loaded, we reconstruct the topological structure.

    for _,var in pairs(persistent_variable_cache) do
        if var.links ~= {} then
            for key,target_ref in pairs(var.links) do
                var[key] = persistent_variable_cache[target_ref]
            end
        end
    end
end

--- Return a reference to the persistent_variable_cache
--- @return table
function bind()
    return persistent_variable_cache
end


--- Delete the persistence variable with label "key"
--- If an Exception is caught during deletion, do not remove the persistent variable from cache.
--- @param key string
function delete(parent_table,key)
    local pstvar = parent_table[key]
    try {
        body = function ()
            parent_table[key] = nil
            fs.delete(pstvar.path)
        end,
        ---@param ex Exception
        catch = function(ex)
            ex:changeType('PersistenceVarException')
            -- Since we failed to delete the persistent_variable, do not delete.
            parent_table[key] = pstvar
            ex:throw()
        end
    }
end
