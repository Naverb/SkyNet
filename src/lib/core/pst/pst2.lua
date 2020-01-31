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

PERSISTENCE_ROOT = config.retrieve('persistence')['PERSISTENCE_ROOT']

-- This table stores all the data from persistence.
--- @type table<string,PSTVar>
local persistent_variable_cache = {}

local helper_functions = {
    --- @param var PSTVar
    --- @param k string
    get = function(var,k)
        if var.links[k] ~= nil then
            return persistent_variable_cache[var.links[k]]
        else
            return var.data[k]
        end
    end,

    --- @param var PSTVar
    ---@param k string
    ---@param v any
    set = function(var,k,v)
        if var.links[k] ~= nil then
            persistent_variable_cache[var.links[k]] = v
        else
            var.data[k] = v
            var:save()
        end
    end,

    ---@param var PSTVar
    serialize = function(var)
        local obj = {
            ref = var.ref,
            data = var.data,
            links = var.links
        }
        return textutils.serialize(obj)
    end,
    --- Remove a PSTVar from table and disk
    --- @param parent_table table<string,PSTVar>
    --- @param key string
    delete = function(parent_table, key)
        local var = parent_table[key]
        try {
            body = function ()
                parent_table[key] = nil
                -- Do we also want to destroy child tables?
                fs.delete(var.path)
            end,
            ---@param ex Exception
            catch = function (ex)
                ex:changeType('PSTVarException')
                -- Since we failed to delete the PSTVar, undo any changes we did,
                parent_table[key] = var
                ex:throw()
            end
        }
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

        local data = {}
        local links = args.links or {}
        for k,v in pairs(args.data) do
            if type(v) == 'table' then
                local child_ref = args.ref .. '.' .. k
                local wrapped_table = PSTVar:new({
                    ref = child_ref,
                    -- remove .pfs extension then change name
                    path = string.sub(args.path,1,-5) .. '.' .. k .. '.pfs',
                    data = v
                })
                links[k] = child_ref
            else
                data[k] = v
            end
        end

        local obj = {
            ref = args.ref,
            path = args.path,
            data = data,
            links = links,

            serialize = helper_functions.serialize,
            get = helper_functions.get,
            set = helper_functions.set,

            --- Save to disk
            --- @param self PSTVar
            save = function (self)
                local serialized_var = self:serialize()
                local file = fs.open(self.path,'w')

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
        obj:save()
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
        local body = try {
            body = function()
                return file.readAll()
            end,
            finally = function ()
                file.close()
            end
        }

        local contents = textutils.unserialize(body)
        local new_var = PSTVar:new({
            ref = contents.ref,
            path = PFS,
            data = contents.data,
            links = contents.links
        })

        persistent_variable_cache[contents.ref] = new_var
    end
end

--- Return a reference to the persistent_variable_cache
--- @return table
function bind()
    return setmetatable({}, {
        __index = persistent_variable_cache,
        __newindex = function(t,k,v)
            --- Since we wrapped the persistent_variable_cache, this metafunction will handle all variable assignments, not just those that don't already exist.
            if persistent_variable_cache[k] then
                -- There already exists a PSTVar at this index, so we delete it first:
                helper_functions.delete(persistent_variable_cache,k)

            end

            local new_var = PSTVar:new({
                ref = k,
                path = fs.combine(PERSISTENCE_ROOT,k .. '.pfs'),
                data = v
            })

            persistent_variable_cache[k] = new_var
        end
    })
end
