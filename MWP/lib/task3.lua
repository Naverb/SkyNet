local module = loadfile('/MWP/lib/module.lua')()
local tableClone = module.require('/MWP/lib/notyourmomslua.lua').tableClone
local generateUID = module.require('/MWP/lib/notyourmomslua.lua').generateUID
local Class = module.require('/MWP/lib/class.lua').Class

-- SOME HELPER STUFF --
EMPTY_PROPERTY 	= '__empty__'
EMPTY_BOOL 		= false

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

-- @CLASS Promise @PARAMS {questionData, askingTask}
Promise = Class {
    constructor = function(self, params)
        _questionData = params.questionData
        _askingTask = assert(params.askingTask, "Attempted to create a promise without specifying askingTask!")
        _kind = assert(params.kind, "Attempted to create a promise without specifying kind!")

        local obj = {
            UID             = generateUID(),
            questionData 	= _questionData,
            askingTask 		= _askingTask,
            kind 			= _kind
        }
        return obj
    end,

    UID                 = EMPTY_PROPERTY,
    dataWasAccessed     = EMPTY_BOOL,
    resolved            = EMPTY_BOOL,
    answerData          = {},
    questionData        = {},
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

        obj.env_mt = { __index = _G }
        obj.procedure_env = { thisTask = obj }
        setmetatable(obj.procedure_env, obj.env_mt)
        setfenv(obj.procedure, obj.procedure_env) -- This creates a global variable within the scope of the procedure - thisTask -  that references the current task (self)

        return obj
    end,

    isActive                = EMPTY_BOOL,
    enabled                 = EMPTY_BOOL,
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

    checkCondition = function(self)
        if self.enabled then
            return self:condition()
        else
            return false
        end
    end,

    yield = function(self, requiredPromises)
        self.isActive = false
        print(self.name .. ' is yielding. Received required promises ' .. tostring(requiredPromises))
        if not requiredPromises then
            requiredPromises = {}
        end
        self.requiredPromises = requiredPromises
        return coroutine.yield()
    end,

    terminate = function(self, finalData)
        self.isActive = false
        self:disable()
        self.enclosingTaskSequence:unqueueTask(self)
        return finalData
    end,

    run = function(self)
        if self:checkCondition() then
            self.isActive = true

            if not self.requiredPromises['os_pullEvent'] then
                -- This code is run if the task last yielded by calling self:yield()
                returnedData = {coroutine.resume(self.action, self)}
                print("Received returned data " .. textutils.serialise(returnedData))
            else
                -- This code is run if the task last yielded by calling coroutine.yield.
                os_event_promise = self.requiredPromises['os_pullEvent'] -- The os_event_promise handles situations where the task calls coroutine.yield() without calling self:yield(). I.e. when rednet yields or gps... etc...
                if os_event_promise.resolved then
                    returnedData = {coroutine.resume(self.action, unpack(os_event_promise.answerData))}
                    self.requiredPromises['os_pullEvent'] = nil
                else
                    -- Our os_pullEvent promise wasn't fullfilled
                    self.isActive = false
                    returnedData = {true, nil}
                end
            end

            local ok = returnedData[1]
            table.remove(returnedData, 1)

            if self.isActive then
                -- The task yielded somehow, but since self.isActive is true, the
                -- task likely did not call self:yield(). Hence, we presume the
                -- task called coroutine.yield(), and we wrap the event of the
                -- coroutine into a promise to interface with the task API.
                print('Generating an OS event for ' .. self.name)
                local os_event = returnedData[1]
                print('OS Event: ' .. tostring(os_event))
                self.requiredPromises['os_pullEvent'] = self:requestPromise {
                    questionData = os_event,
                    kind = 'os_pullEvent'
                }
                self.isActive = false
            end

            self:cleanupRequiredPromises()

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

        for i,v in pairs(promisesToDelete) do
            self.requiredPromises[i] = nil
        end
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

-- @CLASS OSEventHandler @PARAMS {name}
OSEventHandler = Class {
    implements = {YieldingInterface},

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

        for _,promise in pairs(promisesToResolve) do
            print('Found a promise of type ' .. promise.kind)
            if promise.kind == 'os_pullEvent' then
                if not promise.questionData then
                    promise.answerData = {os.pullEventRaw()}
                else
                    promise.answerData = {os.pullEventRaw(promise.questionData)}
                end
                promise.resolved = true
            end
        end

        self.enclosingTaskSequence:unqueueTask(self)
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
    enclosingTaskSequence  = {},
    pendingTasks           = {},
    registeredTasks        = {},
    tasksToRun             = {},
    ranTasks               = {},
    requiredPromises       = {},
    resolvablePromises     = {},
    name                   = EMPTY_PROPERTY,

    yield = function(self, status)
        print('Yielding ' .. self.name)
        self.isActive = false
        return status
    end,

    registerToTaskSequence = function(self, taskSequence)
        self.enclosingTaskSequence = taskSequence
    end,

    registerToRegisteredTasks = function(self,task)
        self.registeredTasks[task.registeredOutcome] = task
    end,

    checkPromiseFulfillment = function(self, promise)
        return self.registeredTasks[promise.kind] ~= nil
    end,

    run = function(self)

        if self.enabled then
            self.isActive = true
            self:cleanupResolvablePromises()
            repeat
                local noYieldingObjectsLeft, nextYieldingObject = self:getNextYieldingObject()
                if not nextYieldingObject then
                    print('No tasks to run in ' .. self.name)
                    return self:yield(true) -- This boolean will be passed to "ok" in the enclosingTaskSequence. Do we want that? Perhaps we should return two values: one for "ok" and another to deterined whether this taskSequence was enabled or disabled.
                else
                    local ok, returnedData = nextYieldingObject:run()
                    print('Finished running ' .. nextYieldingObject.name)
                    if nextYieldingObject.requiredPromises then
                        for _, promise in pairs(nextYieldingObject.requiredPromises) do
                            if self:checkPromiseFulfillment(promise) then
                                if not self.resolvablePromises[promise.UID] then
                                    print('Queueing a task to resolve a promise')
                                    self:queueTask(self.registeredTasks[promise.kind])
                                    self.resolvablePromises[promise.UID] = promise
                                end
                            else
                                if not self.requiredPromises[promise.UID] then
                                    self.requiredPromises[promise.UID] = promise
                                end
                            end
                        end
                    end

                    if not ok then
                        print(returnedData[1]) -- If the task terminated with an error, this is the error message.
                        nextYieldingObject:disable()
                    end
                end
            until noYieldingObjectsLeft
            print('About to yield ' .. self.name)
            return self:yield(true)
        else
            return self:yield(false)
        end
    end,

    enable = function(self)
        self.enabled = true
    end,

    disable = function(self)
        self.enabled = false
    end,

    queueTask = function(self, task)
        print('Received queueTask request')
        table.insert(self.pendingTasks, task)
        task.enclosingTaskSequence = self
        task.index = #self.pendingTasks
    end,

    unqueueTask = function(self, task)
        print('Received unqueueTask request')
        table.remove(self.pendingTasks, task.index)
        task.index = nil
    end,

    getNextYieldingObject = function(self)
        if #self.tasksToRun <= 0 then
            self.tasksToRun = tableClone(self.pendingTasks)
            print('No tasks to run')
            return true, nil -- We don't have a new yielding object to run until the enclosingTaskSequence queues this again.

            else
            local nextYieldingObject = self.tasksToRun[1]
            table.remove(self.tasksToRun, 1)
            print('Returning next task to run: ' .. nextYieldingObject.name)
            return false, nextYieldingObject
        end
        print('No tasks to run')
        return true, nil
    end,

    cleanupResolvablePromises = function(self)
        local promisesToDelete = {}
        for i,v in pairs(self.resolvablePromises) do
            if v.dataWasAccessed then
                table.insert(promisesToDelete, i)
            end
        end

        for i,v in pairs(promisesToDelete) do
            self.resolvablePromises[i] = nil
        end
    end
}

return {
    Promise 		= Promise,
    Task 			= Task,
    TaskSequence 	= TaskSequence
}
