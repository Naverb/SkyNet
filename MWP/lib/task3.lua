-- SOME HELPER STUFF --
EMPTY_PROPERTY = '__empty__'
EMPTY_BOOL = false
EMPTY_TABLE = {}


-- @CLASS Promise @PARAMS {questionData, askingTask}
Promise = class.Class{
    constructor = function(self, params)
        _questionData = assert(params.questionData, "Attempted to create a promise without specifying questionData!")
        _askingTask = assert(params.askingTask, "Attempted to create a promise without specifying askingTask!")
        _kind = assert(params.kind, "Attempted to create a promise without specifying kind!")
        local obj = {
            questionData = _questionData,
            askingTask = _askingTask,
            kind = _kind
        }
        return obj
    end
}
Promise.dataWasAccessed     = EMPTY_BOOL
Promise.resolved            = EMPTY_BOOL
Promise.data                = EMPTY_TABLE
Promise.questionData        = EMPTY_TABLE
Promise.askingTask          = EMPTY_PROPERTY
Promise.kind                = EMPTY_PROPERTY


-- @PRIMITIVE YieldingObject
YieldingObject = {
    isActive                = EMPTY_BOOL,
    enclosingTaskSequence   = EMPTY_TABLE,
    requiredPromises        = EMPTY_TABLE,
    name                    = EMPTY_PROPERTY,

    yield = function(self, requiredPromises)
        self.isActive = false
        self.requiredPromises = requiredPromises
        return coroutine.yield()
    end,
    registerToTaskSequence = function(self, taskSequence)
        self.enclosingTaskSequence = taskSequence
    end
}

-- @CLASS Task @PARAMS {name,procedure [,registeredOutcome, condtion]}
Task = class.Class{
    extends = YieldingObject,
    constructor = function(self, params)

        local obj = {}
        obj.enabled = true
        obj.name = assert(params.name, "Attempted to create a task without specifying a name!")
        obj.registeredOutcome = params.registeredOutcome or EMPTY_PROPERTY
        obj.procedure = assert(params.procedure, "Attempted to create a task without specifying a procedure!")
        obj.condition = params.condition or nil
        obj.action = coroutine.create(obj.procedure)

        return obj
    end
}
Task.isActive                = EMPTY_BOOL
Task.enabled                 = EMPTY_BOOL
Task.enclosingTaskSequence   = EMPTY_TABLE
Task.requiredPromises        = EMPTY_TABLE
Task.name                    = EMPTY_PROPERTY
Task.index                   = EMPTY_PROPERTY
Task.registeredOutcome       = EMPTY_PROPERTY
Task.procedure               = EMPTY_PROPERTY
Task.action                  = EMPTY_PROPERTY
Task.condition               = function() return true end

function Task:checkCondition()
    if self.enabled then
        return self:condition()
    else
        return false
    end
end

function Task:run()
    if self:checkCondition() then
        self.isActive = true
        returnedData = {coroutine.resume(self.action, self)}
        local ok = returnedData[1]
        table.remove(returnedData, 1)
        return ok, returnedData
    else
        self.isActive = false
        return false
    end
end

function Task:registerOutcome(newRegisteredOutcome)
    self.registeredOutcome = newRegisteredOutcome
end

function Task:requestPromise(attributes)
    local promise = Promise:new{
        askingTask = self,
        questionData = assert(attributes.questionData, self.name .. " attempted to requestPromise without specifying questionData!"),
        kind = assert(attributes.kind, self.name .. " attempted to requestPromise without specifying kind")
    }
    return promise
end

function Task:disable()
    self.enabled = false
end

function Task:enable()
    self.enabled = true
end

-- @CLASS TaskSequence @PARAMS {name}
TaskSequence = class.Class{
    extends = YieldingObject,
    constructor = function(self, params)
        local obj = {}

        obj.isActive = false
        obj.name = assert(params.name, "Attempted to create a tasksequence without specifying a name!")
        obj.enabled = true

        return obj
    end
}

TaskSequence.isActive               = EMPTY_BOOL
TaskSequence.enabled                = EMPTY_BOOL
TaskSequence.enclosingTaskSequence  = EMPTY_TABLE
TaskSequence.pendingTasks           = EMPTY_TABLE
TaskSequence.registeredTasks        = EMPTY_TABLE
TaskSequence.ranTasks               = EMPTY_TABLE
TaskSequence.askedPromises          = EMPTY_TABLE
TaskSequence.name                   = EMPTY_PROPERTY

function TaskSequence:passUpPromises()
	self.enclosingTaskSequence.requiredPromises = self.askedPromises
	-- I am 99.99% sure this should be self.requiredPromises = self.askedPromises, otherwise we overwrite requestedPromises of other children in the enclosingTaskSequence. Moreover, we may not need a passUpPromises method for the same reasons that we may not need a yield method (see below).
		-- If task sequence is unable to fulfill, pass up to enclosingTaskSequence. Seperated from yield in case we want to have multiple task sequences alternating, and we want to be able to yield system control between Task Sequences without passing data up to enclosingTaskSequences at the same time.
end

function TaskSequence:yield()
	-- See my comment above. Not sure what we want to entail yielding, so I'll leave this one open for discussion.
	-- We may not need to define a TaskSequence:yield function, for TaskSequence:run() returns control to the enclosing TaskSequence when it returns after running all tasks in taskSequence.tasksToRun.
end

function TaskSequence:checkPromiseFulfillment(promise)
    return self.registeredTasks[promise.kind] ~= nil
end

function TaskSequence:run()

    if self.enabled then
	repeat
		local noTasksLeft, nextTask = self:getNextTask()
		if not nextTask then
			print('No tasks to run in ' .. self.name)
			return true -- This boolean will be passed to "ok" in the enclosingTaskSequence. Do we want that? Perhaps we should return two values: one for "ok" and another to deterined whether this taskSequence was enabled or disabled.
		else
			local ok, returnedData = nextTask:run()
			for i, promise in ipairs(nextTask.requiredPromises) do
			    if self:checkPromiseFulfillment(promise) then
				self:queueTask(self.registeredTasks[promise.kind])
			    else
				table.insert(self.askedPromises, promise) -- We probably want to change all references to askedPromises to requiredPromises. In doing so, we make taskSequences fully compatible with the YieldingObject's interface, and we can simplify the implementation of nested taskSequences within control flow.
			    end
			end

			if not ok then
			    print(returnedData[1]) -- If the task terminated with an error, this is the error message.
			    nextTask:disable()
			end
		end
	until noTasksLeft
        return true
    else
        return false
    end
end

function TaskSequence:enable()
    self.enabled = true
end

function TaskSequence:disable()
    self.enabled = false
end

function TaskSequence:queueTask(task)
    table.insert(self.pendingTasks, task)
    task.index = #self.pendingTasks
end

function TaskSequence:unqueueTask(task)
    table.remove(self.pendingTasks, task.index)
    task.index = nil
end

function TaskSequence:getNextTask()
    if #self.tasksToRun <= 0 then
	self.tasksToRun = self.pendingTasks
	return true, nil -- We don't have a new task to run until the enclosingTaskSequence queues this again.

    else
	local nextTask = self.tasksToRun[1]
	table.remove(self.tasksToRun, 1)
	return false, nextTask
    end

    return true, nil 
end
