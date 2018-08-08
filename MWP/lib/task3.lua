Class = loadfile('./class.lua')()
-- SOME HELPER STUFF --
EMPTY_PROPERTY 	= '__empty__'
EMPTY_BOOL 		= false
EMPTY_TABLE 	= {}

-- @INTERFACE YieldingInterface
YieldingInterface = {
    isActive 				= EMPTY_BOOL,
    enabled 				= EMPTY_BOOL,
    enclosingTaskSequence 	= EMPTY_TABLE,
    requiredPromises 		= EMPTY_TABLE,
    name 					= EMPTY_PROPERTY,

    registerToTaskSequence  = function() end,
    enable                  = function() end,
    disable                 = function() end
}

-- @CLASS Promise @PARAMS {questionData, askingTask}
Promise = Class {
    constructor = function(self, params)
        _questionData = assert(params.questionData, "Attempted to create a promise without specifying questionData!")
        _askingTask = assert(params.askingTask, "Attempted to create a promise without specifying askingTask!")
        _kind = assert(params.kind, "Attempted to create a promise without specifying kind!")

        local obj = {
            questionData 	= _questionData,
            askingTask 		= _askingTask,
            kind 			= _kind
        }
        return obj
    end,

    dataWasAccessed     = EMPTY_BOOL,
    resolved            = EMPTY_BOOL,
    answerData          = EMPTY_TABLE,
    questionData        = EMPTY_TABLE,
    askingTask          = EMPTY_PROPERTY,
    kind                = EMPTY_PROPERTY
}

-- @CLASS Task @PARAMS {name,procedure [,registeredOutcome, condition]}
Task = Class {
    implements = {YieldingInterface},
    constructor = function(self, params)

        local obj = {}
        obj.enabled = true
        obj.name = assert(params.name, "Attempted to create a task without specifying a name!")
        obj.registeredOutcome = params.registeredOutcome or EMPTY_PROPERTY
        obj.procedure = assert(params.procedure, "Attempted to create a task without specifying a procedure!")
        obj.condition = params.condition or nil
        obj.action = coroutine.create(obj.procedure)

        return obj
    end,

    isActive                = EMPTY_BOOL,
    enabled                 = EMPTY_BOOL,
    enclosingTaskSequence   = EMPTY_TABLE,
    requiredPromises        = EMPTY_TABLE,
    name                    = EMPTY_PROPERTY,
    index                   = EMPTY_PROPERTY,
    registeredOutcome       = EMPTY_PROPERTY,
    procedure               = EMPTY_PROPERTY,
    action                  = EMPTY_PROPERTY,
    condition               = function() return true end,

    registerToTaskSequence = function(self, taskSequence)
        self.enclosingTaskSequence = taskSequence
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
        self.requiredPromises = requiredPromises
        return coroutine.yield()
    end,

    run = function(self)
        if self:checkCondition() then
            self.isActive = true

            if not self.requiredPromises then
                returnedData = {coroutine.resume(self.action, self)}
            else
                os_event_promise = self.requiredPromises['os_pullEvent'] -- The os_event_promise handles situations where the task calls coroutine.yield() without calling self:yield(). I.e. when rednet yields or gps... etc...
                if os_event_promise.resolved then
                    returnedData = {coroutine.resume(self.action, os_event_promise.answerData, self)} -- How the crap will we access self now? FIX THIS ASAP
                else
                    self.isActive = false
                    returnedData = {ok, nil}
                end
            end

            local ok = returnedData[1]
            table.remove(returnedData, 1)

            if self.isActive then
                -- The task yielded somehow, but since self.isActive is true, the
                -- task likely did not call self:yield(). Hence, we presume the
                -- task called coroutine.yield(), and we wrap the event of the
                -- coroutine into a promise to interface with the task API.
                local os_event = returnedData[1]
                self.requiredPromises['os_pullEvent'] = self:requestPromise {
                    questionData = returnedData,
                    kind = os_event
                }

            else
                self.requiredPromises['os_pullEvent'] = nil
            end

            return ok, returnedData
        else
            self.isActive = false
            return false
        end
    end,

    registerOutcome = function(self, newRegisteredOutcome)
        self.registeredOutcome = newRegisteredOutcome
    end,

    requestPromise = function(self, attributes)
        local promise = Promise:new{
            askingTask = self,
            questionData = assert(attributes.questionData, self.name .. " attempted to requestPromise without specifying questionData!"),
            kind = assert(attributes.kind, self.name .. " attempted to requestPromise without specifying kind")
        }
        return promise
    end,

    disable = function(self)
        self.enabled = false
    end,

    enable = function(self)
        self.enabled = true
    end

}

-- @CLASS TaskSequence @PARAMS {name}
TaskSequence = Class {
    implements = {YieldingInterface},
    constructor = function(self, params)
        local obj = {}

        obj.isActive = false
        obj.name = assert(params.name, "Attempted to create a tasksequence without specifying a name!")
        obj.enabled = true

        return obj
    end,

    isActive               = EMPTY_BOOL,
    enabled                = EMPTY_BOOL,
    enclosingTaskSequence  = EMPTY_TABLE,
    pendingTasks           = EMPTY_TABLE,
    registeredTasks        = EMPTY_TABLE,
    ranTasks               = EMPTY_TABLE,
    requiredPromises       = EMPTY_TABLE,
    name                   = EMPTY_PROPERTY,

    yield = function(self, status)
        self.isActive = false
        return status
    end,

    registerToTaskSequence = function(self, taskSequence)
        self.enclosingTaskSequence = taskSequence
    end,

    checkPromiseFulfillment = function(self, promise)
        return self.registeredTasks[promise.kind] ~= nil
    end,

    run = function(self)

        if self.enabled then
            self.isActive = true
            repeat
                local noYieldingObjectsLeft, nextYieldingObject = self:getNextYieldingObject()
                if not nextYieldingObject then
                    print('No tasks to run in ' .. self.name)
                    self:yield(true) -- This boolean will be passed to "ok" in the enclosingTaskSequence. Do we want that? Perhaps we should return two values: one for "ok" and another to deterined whether this taskSequence was enabled or disabled.
                else
                    local ok, returnedData = nextYieldingObject:run()
                    for i, promise in ipairs(nextYieldingObject.requiredPromises) do
                        if self:checkPromiseFulfillment(promise) then
                            self:queueTask(self.registeredTasks[promise.kind])
                        else
                            table.insert(self.requiredPromises, promise)
                        end
                    end

                    if not ok then
                        print(returnedData[1]) -- If the task terminated with an error, this is the error message.
                        nextYieldingObject:disable()
                    end
                end
            until noYieldingObjectsLeft
            self:yield(true)
        else
            self:yield(false)
        end
    end,

    enable = function(self)
        self.enabled = true
    end,

    disable = function(self)
        self.enabled = false
    end,

    queueTask = function(self, task)
        table.insert(self.pendingTasks, task)
        task.index = #self.pendingTasks
    end,

    unqueueTask = function(self, task)
        table.remove(self.pendingTasks, task.index)
        task.index = nil
    end,

    getNextYieldingObject = function(self)
        if #self.tasksToRun <= 0 then
            self.tasksToRun = self.pendingTasks
            return true, nil -- We don't have a new yielding object to run until the enclosingTaskSequence queues this again.

            else
            local nextYieldingObject = self.tasksToRun[1]
            table.remove(self.tasksToRun, 1)
            return false, nextYieldingObject
        end

        return true, nil
    end
}

return {
    Promise 		= Promise,
    Task 			= Task,
    TaskSequence 	= TaskSequence
}
