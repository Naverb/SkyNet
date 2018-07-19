-- @FUNCTION CLASS @PARAMS {metatable, constructor, extends}
function Class(attributes)
    local new_class = {}

    if attributes.metatable then
        local inst_mt = attributes.metatable
        inst_mt.__index = new_class
    else
        local inst_mt = { __index = new_class }
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


    if attributes.extends then
        if attributes.metatable then
            class_mt = attributes.metatable
            class_mt.__index = attributes.extends
        else
            class_mt = { __index = attributes.extends}
        end
        setmetatable( new_class, class_mt)
    end
    return new_class
end
----------------------------------------------
-- Helper function to implement inheritance --
----------------------------------------------
function extends( baseClass, constructor )
    -- Create the table and metatable representing the class.
    local new_class = {}
    local class_mt = { __index = new_class }

    -- Note that this function uses class_mt as an upvalue, so every instance
    -- of the class will share the same metatable.

    function new_class:new()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    -- The following is the key to implementing inheritance:
        -- The __index member of the new class's metatable references the
        -- base class.  This implies that all methods of the base class will
        -- be exposed to the sub-class, and that the sub-class can override
        -- any of these methods.

    if baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    return new_class
end
