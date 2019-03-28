local EMPTY_BOOL = nym.EMPTY_BOOL
local EMPTY_PROPERTY = nym.EMPTY_PROPERTY

-- @INTERFACE YieldingInterface
YieldingInterface = {
    isActive 				= EMPTY_BOOL,
    enabled 				= EMPTY_BOOL,
    requiredPromises 		= {},
    name 					= EMPTY_PROPERTY,

    enable                  = function() end,
    disable                 = function() end,
    run                     = function() end
}

_module = YieldingInterface
