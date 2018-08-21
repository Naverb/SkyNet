local module = loadfile('/MWP/lib/module.lua')()

local EMPTY_BOOL = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_BOOL
local EMPTY_PROPERTY = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_PROPERTY
local tableClone = module.require('/MWP/lib/notyourmomslua.lua').tableClone

local Class = module.require('/MWP/lib/class.lua')

local YieldingInterface = module.require('/MWP/lib/yielding/YieldingInterface.lua')

-- @CLASS TaskSequence @PARAMS {name}
TaskSequence = Class {
    implements = YieldingInterface,
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
            self:cleanupRequiredPromises()

            repeat
                local noYieldingObjectsLeft, nextYieldingObject = self:getNextYieldingObject()
                if not nextYieldingObject then
                    return self:yield(true) -- This boolean will be passed to "ok" in the enclosingTaskSequence. Do we want that? Perhaps we should return two values: one for "ok" and another to deterined whether this taskSequence was enabled or disabled.
                else
                    local ok, returnedData = nextYieldingObject:run()
                    if nextYieldingObject.requiredPromises then
                        for _, promise in pairs(nextYieldingObject.requiredPromises) do
                            if self:checkPromiseFulfillment(promise) then
                                if not self.resolvablePromises[promise.UID] then
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
                        print('Error running ' .. nextYieldingObject.name .. ' disabling.')
                        nextYieldingObject:disable()
                    end
                end
            until noYieldingObjectsLeft
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
        table.insert(self.pendingTasks, task)
        task.enclosingTaskSequence = self
        task.index = #self.pendingTasks
    end,

    unqueueTask = function(self, task)
        table.remove(self.pendingTasks, task.index)
        task.index = nil
    end,

    getNextYieldingObject = function(self)
        if #self.tasksToRun <= 0 then
            self.tasksToRun = tableClone(self.pendingTasks)
            return true, nil -- We don't have a new yielding object to run until the enclosingTaskSequence queues this again.

            else
            local nextYieldingObject = self.tasksToRun[1]
            table.remove(self.tasksToRun, 1)
            return false, nextYieldingObject
        end
        return true, nil
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

    cleanupResolvablePromises = function(self)
        local promisesToDelete = {}
        for i,v in pairs(self.resolvablePromises) do
            if v.dataWasAccessed then
                table.insert(promisesToDelete, i)
            end
        end

        for _,v in pairs(promisesToDelete) do
            self.resolvablePromises[v] = nil
        end
    end
}

_module = TaskSequence
