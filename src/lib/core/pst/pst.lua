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

local PERSISTENCE_ROOT = config.retrieve('persistence')['PERSISTENCE_ROOT']

-- This table stores all the data from persistence.
--- @type table<string,PSTVar>
local persistent_variable_cache = {}
--[[
    TODO: Should we have a table that stores all the pointers of already loaded PSTVars. This allows us to track if data was already loaded into the persistent filesystem and prevent duplication i.e. preserve reference topology.
    local already_loaded_tables = {
        pointer = {
            ref = pstvar_ref,
            connections = [integer]
        }
        pointer.connections tracks the number of times this variable is referenced. When it is zero, the pstvar is an orphan, so it should be deleted.
}
]]


local helper_functions = {
    --- @param var PSTVar
    --- @param k string
    get = function(var,k)
        if var.__links[k] ~= nil then
            return persistent_variable_cache[var.__links[k]]
        else
            return var.__data[k]
        end
    end,

    --- @param var PSTVar
    --- @param k string
    --- @param v any
    set = function(var,k,v)
        var.__data[k] = v
        var:__save()
    end,

    ---@param var PSTVar
    serialize = function(var)
        local obj = {
            ref = var.__ref,
            data = var.__data,
            links = var.__links
        }
        return textutils.serialize(obj)
    end
}

--- The reason for the odd Class structure is the metatables for PSTVar are unconventional.
--- We need a special constructor, which we wrap as `new` for notational uniformity.
--- @class PSTVar
--- @field path string
--- @field data table
--- @field links table
PSTVar = {
    --- args contains `ref`,`path`,`[data, links]`
    new = function(self,args)
        assert(type(args.ref) == 'string', 'A proper ref must be declared for every PSTVar!')
        assert(type(args.path) == 'string', 'A proper path must be declared for every PSTVar!')

        -- PSTVars have a weird construction: for each subtable, we need to create another PSTVar, hence the recursion below. ANY CIRCULAR REFERENCES WILL CRASH SKYNET. THIS IS A SERIOUS CONCERN THAT NEEDS TO BE ADDRESSED!

        local links = args.links or {}
        for k,v in pairs(args.data) do
            -- It would probably be bad if we put a PSTVar in args.data.
            -- The naive solution would be to serialize the PSTVar first to strip any function metadata, leaving just the data needed to reconstruct said PSTVar.
            if type(v) == 'table' then
                args.data[k] = nil
                local child_ref = args.ref .. '.' .. tostring(k)
                local wrapped_table = PSTVar:new({
                    ref = child_ref,
                    -- remove .pfs extension then change name
                    path = string.sub(args.path,1,-5) .. '.' .. tostring(k) .. '.pfs',
                    data = v
                })
                links[k] = child_ref
                persistent_variable_cache[child_ref] = wrapped_table
            else
                args.data[k] = v
            end
        end

        local obj = {
            __ref = args.ref,
            __path = args.path,
            __data = args.data,
            __links = links,

            --- Save to disk
            --- @param self PSTVar
            __save = function (self)
                local serialized_var = tostring(self)
                local file = fs.open(self.__path,'w')

                try {
                    body = function ()
                        file.write(serialized_var)
                    end,
                    finally = function ()
                        file.close()
                    end
                }
            end
        }

        setmetatable(obj,{
            __index = helper_functions.get,
            __newindex = helper_functions.set,
            __tostring = helper_functions.serialize
        })

        -- Save to disk
        -- Ideally we wouldn't re-write the .PFS if it already exists. Fix this later.
        obj:__save()
        return obj
    end
}

local function findPFSs(start_dir)
    local PFSs = {}
    local children = fs.list(start_dir)

    for _,child in ipairs(children) do
        if not fs.isDir(fs.combine(start_dir,child)) then
            if string.find(child,'%.pfs$') then
                -- child is not a directory, and it has extension .pfs
                table.insert(PFSs,fs.combine(start_dir,child))
            end
        else
            -- child is directory, recursively find PFSs in child.
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
            end,
            --- @param ex Exception
            catch = function(ex)
                ex:changeType('PSTRootMissingException')
                ex:throw()
            end
        }
    end

    local PFSs = findPFSs(PERSISTENCE_ROOT)

    for _,PFS in ipairs(PFSs) do
        local file = fs.open(PFS,'r')
        local raw_contents = try {
            body = function()
                return file.readAll()
            end,
            finally = function ()
                file.close()
            end
        }

        local contents = textutils.unserialize(raw_contents)
        local new_var = PSTVar:new({
            ref = contents.ref,
            path = PFS,
            data = contents.data,
            links = contents.links
        })

        persistent_variable_cache[contents.ref] = new_var
    end
end

--- Remove a PSTVar from cache and disk
--- @param key string
function delete(key)
    -- first check if such a PSTVar exists
    if persistent_variable_cache[key] then
        local var = persistent_variable_cache[key]
        try {
            body = function ()
                for _,child_ref in pairs(var.__links) do
                    delete(child_ref)
                end
                persistent_variable_cache[key] = nil
                -- Do we also want to destroy child tables?
                fs.delete(var.__path)
            end,
            ---@param ex Exception
            catch = function (ex)
                ex:changeType('PSTVarException')
                -- Since we failed to delete the PSTVar, undo any changes we did,
                persistent_variable_cache[key] = var
                ex:throw()
            end
        }
    else
        print('Attempted to delete nonexistent PSTVar: ' .. tostring(key))
    end
end

--- Return a reference to the persistent_variable_cache
--- @return table
function bind()
    return setmetatable({}, {
        __index = persistent_variable_cache,
        __newindex = function(_,key,value)
            --- Since we wrapped the persistent_variable_cache, this metafunction will handle all variable assignments, not just those that don't already exist.
            if persistent_variable_cache[key] then
                -- There already exists a PSTVar at this index, so we delete it first:
                delete(key)
            end
            local new_var = PSTVar:new({
                ref = key,
                path = fs.combine(PERSISTENCE_ROOT,key .. '.pfs'),
                data = value
            })
            persistent_variable_cache[key] = new_var
        end
    })
end
