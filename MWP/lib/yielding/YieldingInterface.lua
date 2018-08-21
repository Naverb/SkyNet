local module = loadfile('/MWP/lib/module.lua')()
local EMPTY_BOOL = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_BOOL
local EMPTY_PROPERTY = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_PROPERTY

-- @INTERFACE YieldingInterface
YieldingInterface = {
    isActive 				= EMPTY_BOOL,
    enabled 				= EMPTY_BOOL,
    enclosingTaskSequence 	= {},
    requiredPromises 		= {},
    name 					= EMPTY_PROPERTY,

    registerToTaskSequence  = function() end,
    enable                  = function() end,
    disable                 = function() end,
    run                     = function() end
}

_module = YieldingInterface
