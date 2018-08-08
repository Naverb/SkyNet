-- @FUNCTION CCLASS @PARAMS {metatable, constructor, extends [, ...]}
function Class(attributes)
    local new_class = {}
    local inst_mt

    local function tableClone(tbl)
        newTbl = {}

        if type(tbl) == 'table' then
            for k,v in pairs(tbl) do
                newTbl[k] = v
            end
        else
            print('Attempted to clone empty table!')
        end
        return newTbl
    end

    for key, attribute in pairs(attributes) do
		new_class[key] = attribute -- For any methods defined in the parameters of Class, add them to our class that we are creating.
    end

    if attributes.implements then
        for _, interface in pairs (attributes.implements) do
            for key, attribute in pairs(interface) do
                if new_class[key] == nil or type(attribute) ~= type(new_class[key]) then
                    error('Class failed to implement ' .. key .. '.',2) -- Raise it up an env to the caller.
                end
            end
        end
    end

    if attributes.extends then
        if attributes.metatable then
            class_mt = tableClone(attributes.metatable)
            class_mt.__index = attributes.extends
        else
            class_mt = { __index = attributes.extends}
        end
        setmetatable( new_class, class_mt)
    end

    if attributes.metatable then
        inst_mt = tableClone(attributes.metatable)
        inst_mt.__index = new_class
    else
        inst_mt = { __index = new_class }
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

return Class -- For loadfile
