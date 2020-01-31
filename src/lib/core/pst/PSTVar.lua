-- Skynet Persistence 2020

--- @param pstvar PSTVar
local function pstGet(pstvar,k)
    return pstvar.data[k]
    --[[
    if pstvar.links[k] ~= nil then
        return pstvar.links[k]
    else
        return pstvar.data[k]
    end
    ]]
end

--- @param pstvar PSTVar
local function pstSet(pstvar,k,v)
    --[[
    if pstvar.links[k] ~= nil then
        -- If this key points to another PSTVar, then this will call the __newindex method of that PSTVar
        pstvar.links[k] = v
    else
        pstvar.data[k] = v
        -- Now we write to storage
        pstvar:save()
    end
    ]]
    pstvar.data[k] = v
    pstvar:save()
end

local function serializePSTVar(pstvar)
    local obj = {
        ref = pstvar.ref,
        data = pstvar.data,
        links = pstvar.links
    }

    print('yeehaw ' .. tostring(pstvar.ref))
    return textutils.serialize(obj)
end

--- The reason for the odd Class structure is the metatables for PSTVar are unconventional.
--- We need a special constructor, which we wrap as `new` for notational uniformity.
--- @class PSTVar
--- @field path string
--- @field data table
--- @field links table
local PSTVar = {}

PSTVar.new = function(self,args)

    assert(type(args.ref) == 'string', 'A proper ref must be declared for every PSTVar!')
    assert(type(args.path) == 'string', 'A proper path must be declared for every PSTVar!')

    -- PSTVars have a weird construction: for each subtable, we need to create another PSTVar, hence the recursion below. ANY CIRCULAR REFERENCES WILL CRASH SKYNET. THIS IS A SERIOUS CONCERN THAT NEEDS TO BE ADDRESSED!
    local data = {}
    local links = args.links or {}
    for k,v in pairs(args.data) do
        if type(v) == 'table' then
            local subref = args.ref .. '.' .. k
            data[k] = PSTVar:new{
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
                    file.write(serialized_pstvar)
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

_module = PSTVar
