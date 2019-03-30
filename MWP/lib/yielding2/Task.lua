local EMPTY_BOOL        = nym.EMPTY_BOOL
local EMPTY_PROPERTY    = nym.EMPTY_PROPERTY

local YieldingInterface = module.require('/MWP/lib/yielding2/YieldingInterface.lua')
local PromiseInterface  = module.require('/MWP/lib/yielding2/PromiseInterface.lua')
local Promise           = module.require('/MWP/lib/yielding2/Promise.lua')

local Task = Class {
    implements = {YieldingInterface,PromiseInterface},
    constructor = function(self,params)

    end,

    active  = EMPTY_BOOL,
    enabled = EMPTY_BOOL,
    name    = EMPTY_PROPERTY,

    -- The following table lists the kinds of Promises that this Task can resolve.
    promiseResolutionCapabilities = {},

    -- The following table lists the promises this Task requires
    requiredPromises = {},

    -- The function executed within this Task's action (which is a coroutine)
    procedure = function() end,

    -- This is the coroutine that stores this Task's procedure
    action = EMPTY_PROPERTY,

    -- This is the function that returns true if the Task is to be run
    condition = function(self) return true end,

    -- If a Task is patient, it will not be run until all of its Promises are resolved.
    patient = EMPTY_BOOL,

    isActive = function(self)
        return self.active
    end,

    isEnabled = function(self)
        return self.enabled
    end,

    enable = function(self)
        self.enabled = true
    end,

    disable = function(self)
        self.enabled = false
    end,

    getRequiredPromises = function(self)
        return self.requiredPromises
    end,

    cleanupRequiredPromises = function(self)
        local promisesToDelete = {}
        for i,promise in pairs(self.requiredPromises) do
            if promise:isReadyToDelete() then
                table.insert(promisesToDelete,i)
            end
        end

        for _,promiseIndex in pairs(promisesToDelete) do
            self.requiredPromises[promiseIndex] = nil
        end
    end,

    checkCondition = function(self)
        if self:isEnabled() then
            return self:condition()
        end
        return false
    end,

    run = function(self)
        if self:checkCondition() then
            self.active = true

            if self.patient then
                local allPromisesResolved = true
                for _,promise in pairs(self:getRequiredPromises()) do
                    if not promise:isResolved() then
                        allPromisesResolved = false
                        break
                    end
                end

                if not allPromisesResolved then
                    self.active = false
                    return true
                end
            end

            local returnedData

            if self.requiredPromises['legacy_event'] ~= nil then
                -- If the Task called coroutine.yield() instead of Task:yield(), we have to handle the workflow slightly differently
                local legacy_event_promise = self.requiredPromises['legacy_event']
                -- The legacy_event Promise handles situations where the Task calls coroutine.yield() without calling Task:yield(). I.e. when rednet yields gps, etc...
                if legacy_event_promise:isResolved() then
                    legacy_event_promise:markReadyForDeletion()
                    returnedData = {coroutine.resume(self.action,unpack(legacy_event_promise.answerData))}
                else
                    self.active = false
                    returnedData = {true}
                end
            else
                returnedData = {coroutine.resume(self.action)}
            end

            local ok = returnedData[1]
            table.remove(returnedData, 1)

            if not ok then
                self.active = false
                local ex_msg = self.name .. ' failed to execute! Dumped received data to log.'
                log.printToLog(ex_msg)
                log.printToLog(textutils.serialize(returnedData))
                local taskEx = Exception:new(ex_msg,'TaskExecutionException')
                taskEx:throw()
            end

            self:cleanupRequiredPromises()

            if self.active then
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
                self.active = false
            end

            return ok, returnedData
        else
            self.active = false
            return true
        end
    end,

    yield = function(self,requiredPromises, unqueue)
        self.active = false
        self.requiredPromises = requiredPromises or {}
        if unqueue then
            return coroutine.yield({__unqueue = true})
        end
        return coroutine.yield()
    end,

    terminate = function(self, finalData)
        self.active = false
        finalData.__unqueue = true
        return finalData
    end,

    requestPromise = function(self, promiseAttributes)
        assert(promiseAttributes.kind, self.name .. " attempted to requestPromise without specifying kind!")
        local newPromise = Promise:new{
            askingTask = self.name,
            questionData = promiseAttributes.questionData,
            kind = promiseAttributes.kind
        }
        return newPromise
    end,

    checkPromise = function(self,promise)
        if promise:isResolved() then
            return true
        elseif promise.askingTask ~= self.name then
            return true
        end
        return false
    end
}

_module = Task


--[[
   Question 1: What is the notation to specify action as a coroutine?
        Answer: coroutine.create(FUNCTION_TO_MAKE_INTO_COROUTINE)

   Question 2: Why do we not actually delete promises that are ready to delete while cleaning up, and we instead add them to a delete queue?
        Answer: If we delete them

    Question 3:

--]]
