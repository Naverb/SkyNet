local function pstGet(pstvar,k)
    print('Woah')
    if pstvar.links[k] ~= nil then
        return pstvar.links[k]
    else
        return pstvar.data[k]
    end
end

local function pstSet(pstvar,k,v)
    if pstvar.links[k] ~= nil then
        -- If this key points to another PSTVar, then this will call the __newindex method of that PSTVar
        pstvar.links[k] = v
    else
        pstvar.data[k] = v
        -- Now we write to storage
        pstvar:save()
    end
end

-- Skynet Persistence 2020
--- @class PSTVar:Class
--- @field path string
--- @field data table
--- @field links table
local PSTVar = Class {
    constructor = function(self,args)
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

        local obj = {}
        obj.ref = args.ref
        obj.path = args.path
        obj.data = data
        obj.links = links

        -- Save to disk
        -- Ideally we wouldn't re-write the .PFS if it already exists. Fix this later.
        PSTVar.save(obj)

        return obj
    end,
    get = pstGet,
    set = pstSet,
    --- Save to disk
    --- @param self PSTVar
    save = function(self)
        local serialized_links = {}
        for k,linked_pstvar in pairs(self.links) do
            serialized_links[k] = linked_pstvar.ref
        end

        local serialized_pstvar = textutils.serialize({
            data = self.data,
            links = serialized_links
        })

        local file = fs.open(self.path,'w')

        try {
            body = function ()
                file.write(serialized_pstvar)
            end,
            finally = function ()
                file.close()
            end
        }
    end,
    metatable = {
        __index = pstGet,
        __newindex = pstSet
    }
}

_module = PSTVar
