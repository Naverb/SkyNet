local module = loadfile('/MWP/lib/module.lua')()
local EMPTY_BOOL = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_BOOL
local EMPTY_PROPERTY = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_PROPERTY

local Class = module.require('/MWP/lib/class.lua')

local YieldingInterface = module.require('/MWP/lib/yielding/YieldingInterface.lua')

-- @CLASS OSEventHandler @PARAMS {name}
OSEventHandler = Class {
    implements = YieldingInterface,

    constructor = function(self)
        local obj = {}

        obj.name 				= 'OSEventHandler'
        obj.registeredOutcome 	= 'os_pullEvent'
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
        print('Attempted to terminate an OSEventHandler. You cannot do that.')
    end,

    run = function(self)
        self.isActive = true
        local promisesToResolve = self:findPromisesToResolve()

        local data = {os.pullEventRaw()}
        local event = data[1]

        local allPromisesResolved = true
        for _,promise in pairs(promisesToResolve) do
            if promise.kind == 'os_pullEvent' then
                if not promise.questionData[1] then
                    promise.answerData = data
                    promise.resolved = true
                elseif promise.questionData[1] == event then
                    promise.answerData = data
                    promise.resolved = true
                else
                    allPromisesResolved = false
                end
            end
        end

        if allPromisesResolved then
            self.enclosingTaskSequence:unqueueTask(self)
        end
        return self:yield()
    end,

    findPromisesToResolve = function(self)
        local promisesToResolve = {}
        for _,promise in pairs(self.enclosingTaskSequence.resolvablePromises) do
            if promise.kind == self.registeredOutcome then
                table.insert(promisesToResolve, promise)
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

_module = OSEventHandler
