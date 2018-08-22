local module = loadfile('/MWP/lib/module.lua')()
local EMPTY_BOOL = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_BOOL
local EMPTY_PROPERTY = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_PROPERTY

local Class = module.require('/MWP/lib/class.lua')

local YieldingInterface = module.require('/MWP/lib/yielding/YieldingInterface.lua')

-- @CLASS LegacyEventHandler @PARAMS {name}
LegacyEventHandler = Class {
    implements = YieldingInterface,

    constructor = function(self)
        local obj = {}

        obj.name 				= 'LegacyEventHandler'
        obj.registeredOutcome 	= 'legacy_event'
        obj.enabled 			= true

        return obj
    end,

    isActive                = EMPTY_BOOL,
    enclosingTaskSequence   = {},
    name 	                = EMPTY_PROPERTY,
    index               	= EMPTY_PROPERTY,
    enabled                 = EMPTY_BOOL,
    requiredPromises        = {}, -- We do not need required promises, but we want to interface with YieldingInterface.

    registerToTaskSequence = function(self, taskSequence)
        self.enclosingTaskSequence = taskSequence
    end,

    yield = function(self)
        self.isActive = false
        return true
    end,

    terminate = function(self)
        self.isActive = false
        self.enclosingTaskSequence:unqueueTask(self)
        return true
    end,

    run = function(self)
        self.isActive = true
        local promisesToResolve = self:findPromisesToResolve()

        local data = {os.pullEventRaw()}
        local event = data[1]

        local allPromisesResolved = true
        for _,promise in pairs(promisesToResolve) do
            if not promise.kind[1] then -- The first entry in promise.kind is the event called by os.pullEvent.
                promise.answerData = data
                promise:resolve()
            elseif promise.kind[1] == event then
                promise.answerData = data
                promise:resolve()
            else
                allPromisesResolved = false
            end
        end

        if allPromisesResolved then
            return self:terminate()
        else
            return self:yield()
        end
    end,

    findPromisesToResolve = function(self)
        local promisesToResolve = {}
        for _,promise in pairs(self.enclosingTaskSequence.resolvablePromises) do
            if not promise:reserved() then
                for _, kind in pairs(promise.kind) do
                    if (kind == self.registeredOutcome) then
                        table.insert(promisesToResolve, promise)
                        break
                    end
                end
            end
        end
        return promisesToResolve
    end,

    disable = function(self)
        self.enabled = false
    end,

    enable = function(self)
        self.enabled = true
    end
}

_module = LegacyEventHandler
