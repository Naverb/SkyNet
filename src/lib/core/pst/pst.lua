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

local persistent_variable_cache = {}

--- @param pstvar PSTVar
local function pstGet(pstvar,k)
    print('Received request for ' .. k ..' from ' .. pstvar.ref)
    if pstvar.links[k] ~= nil then
        local dest = pstvar.links[k]
        print('Routing request ' .. k .. ' to ' .. dest)
        return persistent_variable_cache[dest]
    else
        return pstvar.data[k]
    end
end

--- @param pstvar PSTVar
local function pstSet(pstvar,k,v)
    if pstvar.links[k] ~= nil then
        -- If this key points to another PSTVar, then this will call the __newindex method of that PSTVar
        persistent_variable_cache[pstvar.links[k]] = v
    else
        pstvar.data[k] = v
        -- Now we write to storage
        pstvar:save()
    end
end

local function serializePSTVar(pstvar)
    local obj = {
        ref = pstvar.ref,
        data = pstvar.data,
        links = pstvar.links
    }
    return textutils.serialize(obj)
end

--- The reason for the odd Class structure is the metatables for PSTVar are unconventional.
--- We need a special constructor, which we wrap as `new` for notational uniformity.
--- @class PSTVar
--- @field path string
--- @field data table
--- @field links table
PSTVar = {}
PSTVar.new = function(self,args)

    assert(type(args.ref) == 'string', 'A proper ref must be declared for every PSTVar!')
    assert(type(args.path) == 'string', 'A proper path must be declared for every PSTVar!')

    -- PSTVars have a weird construction: for each subtable, we need to create another PSTVar, hence the recursion below. ANY CIRCULAR REFERENCES WILL CRASH SKYNET. THIS IS A SERIOUS CONCERN THAT NEEDS TO BE ADDRESSED!
    local data = {}
    local links = args.links or {}
    for k,v in pairs(args.data) do
        if type(v) == 'table' then
            local subref = args.ref .. '.' .. k
            persistent_variable_cache[subref] = PSTVar:new{
                ref = subref,
                -- drop the .pfs extension
                path = string.sub(args.path,1,-5) .. '.' .. k .. '.pfs',
                data = v,
            }
            links[k] = subref
        else
            data[k] = v
        end
    end

    local obj = {
        ref = args.ref,
        path = args.path,
        data = data,
        links = links,

        get = pstGet,
        set = pstSet,

        --- Save to disk
        --- @param self PSTVar
        save = function (self)
            local serialized_links = {}
            for k,linked_pstvar in pairs(self.links) do
                serialized_links[k] = linked_pstvar.ref
            end

            local serialized_pstvar = tostring(self)

            local file = fs.open(self.path,'w')

            try {
                body = function ()
                    print(file == nil)
                    file.write(serialized_pstvar)
                end,
                --- @param ex Exception
                catch = function (ex)
                    print('Hey check this out!')
                    error(ex:serialize())
                end,
                finally = function ()
                    file.close()
                end
            }
        end
    }

    setmetatable(obj,{
        __index = pstGet,
        __newindex = pstSet,
        __tostring = serializePSTVar
    })

    -- Save to disk
    -- Ideally we wouldn't re-write the .PFS if it already exists. Fix this later.
    obj:save()

    return obj
end

setmetatable(persistent_variable_cache,{
    __index = function(t,k)
        local ex = Exception:new('Attempted to access nonexist PSTVar ' .. tostring(k),'PSTAccessException')
        ex:throw()
    end,
    __newindex = function(t,k,v)
        rawset(t,k,PSTVar:new {
            ref = k,
            path = fs.combine(PERSISTENCE_ROOT,k .. '.pfs'),
            data = v
        })
    end
})

local function findPFSs(start_dir)
    local PFSs = {}

    local children = fs.list(start_dir)
    for _,child in ipairs(children) do
        if not fs.isDir(fs.combine(start_dir,child)) then
            if string.find(child,'%.pfs$') then
                -- If the above evaluates to true, then child is not a directory,
                -- and it ends with the extension .pfs
                table.insert(PFSs,fs.combine(start_dir,child))
            end
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

        rawset(persistent_variable_cache,contents.ref, new_pstvar)
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
    return setmetatable({},{
        __index = persistent_variable_cache,
        __newindex = function(t,k,v)
            rawset(persistent_variable_cache,k,PSTVar:new {
                ref = k,
                path = fs.combine(PERSISTENCE_ROOT,k .. '.pfs'),
                data = v
            })
        end
    })
    --return persistent_variable_cache
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
