local module = loadfile('/MWP/lib/module.lua')()
local EMPTY_BOOL = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_BOOL
local EMPTY_PROPERTY = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_PROPERTY

local Class = module.require('/MWP/lib/class.lua')

local YieldingInterface = module.require('/MWP/lib/yielding/YieldingInterface.lua')
local Promise = module.require('/MWP/lib/yielding/Promise.lua')

-- @CLASS Task @PARAMS {name,procedure [,registeredOutcome, condition]}
Task = Class {
    implements = YieldingInterface,
    constructor = function(self, params)

        local obj = {}
        obj.enabled = true
        obj.name = assert(params.name, "Attempted to create a task without specifying a name!")
        obj.registeredOutcome = params.registeredOutcome or EMPTY_PROPERTY
        obj.procedure = assert(params.procedure, "Attempted to create a task without specifying a procedure!")
        obj.condition = params.condition or nil
        obj.action = coroutine.create(obj.procedure)

        obj.env_mt = { __index = _G }
        obj.procedure_env = { thisTask = obj }
        setmetatable(obj.procedure_env, obj.env_mt)
        setfenv(obj.procedure, obj.procedure_env) -- This creates a global variable within the scope of the procedure - thisTask -  that references the current task (self)

        return obj
    end,

    isActive                = EMPTY_BOOL,
    enabled                 = EMPTY_BOOL,
    patient                 = EMPTY_BOOL, -- If patient, this task waits until all its promises are resolved before resuming.
    enclosingTaskSequence   = {},
    requiredPromises        = {},
    name                    = EMPTY_PROPERTY,
    index                   = EMPTY_PROPERTY,
    registeredOutcome       = EMPTY_PROPERTY,
    procedure               = EMPTY_PROPERTY,
    action                  = EMPTY_PROPERTY,
    condition               = function() return true end,

	registerToTaskSequence = function(self, taskSequence)
		self.enclosingTaskSequence = taskSequence
    end,

    unqueueFromTaskSequence = function(self)
        self.enclosingTaskSequence:unqueueTask(self)
    end,

    checkCondition = function(self)
        if self.enabled then
            return self:condition()
        else
            return false
        end
    end,

    yield = function(self, requiredPromises)
        self.isActive = false
        self.requiredPromises = requiredPromises or {}
        return true, coroutine.yield()
    end,

    yieldUntilResolved = function(self, requiredPromises)
        self.patient = true
        return self:yield(requiredPromises)
    end,

    terminate = function(self, finalData)
        self.isActive = false
        self:unqueueFromTaskSequence()
        return true, finalData
    end,

    run = function(self)
        if self:checkCondition() then
            self.isActive = true

            if self.patient then
                -- Check if all promises are resolved.
                local allPromisesResolved = true
                for _,promise in pairs(self.requiredPromises) do
                    if not promise:resolved() then
                        allPromisesResolved = false
                        break
                    end
                end

                if not allPromisesResolved then
                    -- Return here, we are done running the task for now.
                    self.isActive = false
                    return true
                end
            end

            local returnedData

            if not self.requiredPromises['legacy_event'] then
                -- This code is run if the task last yielded by calling self:yield()
                returnedData = {coroutine.resume(self.action)}
            else
                -- This code is run if the task last yielded by calling coroutine.yield.
                legacy_event_promise = self.requiredPromises['legacy_event'] -- The os_event_promise handles situations where the task calls coroutine.yield() without calling self:yield(). I.e. when rednet yields or gps... etc...
                if legacy_event_promise:resolved() then
                    legacy_event_promise.dataWasAccessed = true
                    returnedData = {coroutine.resume(self.action, unpack(legacy_event_promise.answerData))}
                else
                    -- Our legacy_event promise wasn't fullfilled
                    self.isActive = false
                    returnedData = {true, nil}
                end
            end


            local ok = returnedData[1]
            table.remove(returnedData, 1)

            if not ok then
                self.isActive = false
                return ok, returnedData
            end

            self:cleanupRequiredPromises()

            if self.isActive then
                -- The task yielded somehow, but since self.isActive is true, the
                -- task likely did not call self:yield(). Hence, we presume the
                -- task called coroutine.yield(), and we wrap the event of the
                -- coroutine into a promise to interface with the task API.
                local legacy_event = returnedData[1]
                table.remove(returnedData,1)
                self.requiredPromises['legacy_event'] = self:requestPromise {
                    questionData = returnedData,
                    kind = {legacy_event, 'legacy_event'}
                }
                self.isActive = false
            end

            return ok, returnedData
        else
            self.isActive = false
            return true
        end
    end,

    registerOutcome = function(self, newRegisteredOutcome)
        self.registeredOutcome = newRegisteredOutcome
    end,

    requestPromise = function(self, attributes)
        local promise = Promise:new{
            askingTask = self,
            questionData = attributes.questionData,
            kind = assert(attributes.kind, self.name .. " attempted to requestPromise without specifying kind")
        }
        return promise
    end,

    cleanupRequiredPromises = function(self)
        local promisesToDelete = {}
        for i,v in pairs(self.requiredPromises) do
            if v.dataWasAccessed then
                table.insert(promisesToDelete, i)
            end
        end

        for _,v in pairs(promisesToDelete) do
            self.requiredPromises[v] = nil
        end
    end,

    findPromisesToResolve = function(self)
        local promisesToResolve = {}
        for _,promise in pairs(self.enclosingTaskSequence.resolvablePromises) do
            if not promise:resolved() then
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

_module = Task
