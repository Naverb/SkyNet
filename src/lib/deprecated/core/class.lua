local tableClone = nym.tableClone

function Class(attributes)
    local new_class = {}
    local inst_mt = {}
    local class_mt = {}

    function new_class.lookupInClass(class,key)
        local val = try {
            body = function()
                local val = class[key]
                if (type(val) == 'table') then
                    return tableClone(val)
                else
                    return val
                end
            end,
            catch = function(ex)
                ex:changeType('ClassLookupException')
                ex:throw()
            end
        }
        return val
    end

    local function implementInterface(interface)
        for k, attr in pairs(interface) do
            if string.sub(k,1,2) ~= '__' then
                -- If the interface is a module, we ignore module metadata
                local val = new_class[k]
                if val == nil or type(attr) ~= type(val) then
                    local ex_msg = 'Class failed to implement ' .. tostring(k) .. '.'
                    local ex = Exception:new(ex_msg,'ClassInterfaceException')
                    ex:throw(0)
                end
            end
        end
    end

    -- Now we add the attributes to the class
    for k,attr in pairs(attributes) do
        new_class[k] = attr
    end

    if attributes.implements then
        if #attributes.implements > 0 then
            for _,interface in pairs(attributes.implements) do
                try {
                    body = implementInterface,
                    args = interface,
                    catch = function(ex)
                        ex:throw(3)
                    end
                }
            end
        else
            -- In this case, the implements table is an interface itself since it is of length zero.
            try {
                body = implementInterface,
                args = attributes.implements,
                catch = function(ex)
                    ex:throw(3)
                end
            }
        end
    end

    if attributes.metatable then
        class_mt = tableClone(attributes.metatable)
        inst_mt = tableClone(attributes.metatable)
    end

    inst_mt.__index = function(object,key)
        local val = new_class:lookupInClass(key)
        object[key] = val
        return val -- We want to make sure that we return the instance's version of the attribute 'key' NOT the class's.
    end

    if attributes.extends then
        -- Modify the __index metamethod of the class to look at the extended Class:
        class_mt.__index = function(this_class,key)
            local val = new_class.lookupInClass(attributes.extends,key)
            this_class[key] = val
            return val
        end
    end

    new_class.new = function(...)
        local newinst
        if attributes.constructor then
            newinst = attributes.constructor(...)
        else
            newinst = {}
        end

        setmetatable(newinst,inst_mt)
        return newinst
    end

    setmetatable(new_class,class_mt)
    return new_class
end

_module = module.exportFunction(Class)
return Class -- This line loads the Class API without using the Module API.
