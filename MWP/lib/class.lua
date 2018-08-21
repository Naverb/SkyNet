local module = loadfile('/MWP/lib/module.lua')()
local tableClone = module.require('/MWP/lib/notyourmomslua.lua').tableClone

-- @FUNCTION CCLASS @PARAMS {metatable, constructor, extends [, ...]}
function Class(attributes)
    local new_class = {}
    local inst_mt

    local function lookupInClass(val)
        -- If an instance of a class needs to lookup a value, let's make sure we
        -- don't modify any attributes of the class, but rather duplicate the
        -- attribute.
        if (type(val) == 'table') then
            return tableClone(val)
        else
            return val
        end
    end

    for key, attribute in pairs(attributes) do
        new_class[key] = attribute -- For any methods defined in the parameters of Class, add them to our class that we are creating.
    end

    if attributes.implements then
        if #attributes.implements > 0 then
            for _, interface in pairs(attributes.implements) do
                for key, attribute in pairs(interface) do
                    if string.sub(key,1,2) ~= '__' then -- If the interface is a module, we want to ignore module metadata.
                        if new_class[key] == nil or type(attribute) ~= type(new_class[key]) then
                            error('Class failed to implement ' .. key .. '.',2) -- Raise it up an env to the caller.
                        end
                    end
                end
            end
        else
            for key, attribute in pairs(attributes.implements) do -- If the table is of length 0, the implements table *is* an interface.
                if string.sub(key,1,2) ~= '__' then -- If the interface is a module, we want to ignore module metadata.
                    if new_class[key] == nil or type(attribute) ~= type(new_class[key]) then
                        error('Class failed to implement ' .. key .. '.',2) -- Raise it up an env to the caller.
                    end
                end
            end
        end
    end

    if attributes.extends then
        if attributes.metatable then
            class_mt = tableClone(attributes.metatable)
            class_mt.__index = function(_class,key)
                local ok, result = pcall(lookupInClass, attributes.extends[key])
                if ok then
                    _class[key] = result
                    return _class[key]
                else
                    error(result,2) --Should this be 3?
                end
            end
        else
            class_mt = { __index = function(_class,key)
                local ok, result = pcall(lookupInClass, attributes.extends[key])
                if ok then
                    _class[key] = result
                    return _class[key]
                else
                    error(result,2)
                end
            end }
        end
        setmetatable( new_class, class_mt)
    end

    if attributes.metatable then
        inst_mt = tableClone(attributes.metatable)
        inst_mt.__index = function(object,key)
            local ok, result = pcall(lookupInClass, new_class[key])
            if ok then
                object[key] = result
                return object[key]
            else
                error(result,2)
            end
        end
    else
        inst_mt = { __index = function(object,key)
			local ok, result = pcall(lookupInClass, new_class[key])
            if ok then
            	object[key] = result
				return object[key]
			else
				error(result,2)
            end
        end }
    end

    new_class.new = function(...)
        local newinst
        if attributes.constructor then
            newinst = attributes.constructor(...)
        else
            newinst = {}
        end

        setmetatable( newinst, inst_mt)
        return newinst
    end

    return new_class
end

_module = module.exportFunction(Class)
return Class -- For loadfile
