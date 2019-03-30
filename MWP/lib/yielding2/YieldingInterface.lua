local EMPTY_PROPERTY    = nym.EMPTY_PROPERTY
local EMPTY_BOOL        = nym.EMPTY_BOOL

local YieldingInterface = {

    -- Any Class that yields must notify whether it is active:
    isActive    = function() end,
    active      = EMPTY_BOOL,

    -- It must also be capable of disabling and enabling, and notifying which state it is in:
    isEnabled   = function() end,
    enabled     = EMPTY_BOOL,
    enable      = function() end,
    disable     = function() end,

    -- It must provide a way to determine which Promises it needs:
    getRequiredPromises = function() end,
    requiredPromises    = {},

    -- It must also have a name:
    name = EMPTY_PROPERTY,

    -- It should also be exectuable:
    run = function() end
}

_module = YieldingInterface
