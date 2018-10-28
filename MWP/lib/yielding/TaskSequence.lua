local EMPTY_BOOL = nym.EMPTY_BOOL
local EMPTY_PROPERTY = nym.EMPTY_PROPERTY
local tableClone = nym.tableClone
local generateUID = nym.generateUID

local YieldingInterface = module.require('/MWP/lib/yielding/YieldingInterface.lua')
local Task = module.require('/MWP/lib/yielding/Task.lua')

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
    pendingTasks           = {},
    registeredTasks        = {},
    tasksToRun             = {},
    ranTasks               = {},
    requiredPromises       = {},
    resolvablePromises     = {},
    name                   = EMPTY_PROPERTY,

    yield = function(self, ...)
        self.isActive = false
        return ...
    end,

    checkPromiseFulfillment = function(self, promise)
        for _,kind in pairs(promise.kind) do
            if self.registeredTasks[kind] ~= nil then
                return true, kind
            end
        end
        return false
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
                    --[[
                        Here we should write code that assignz the promises that the Task can fulfill. That way we can remove doubly linked lists.
                    ]]
                    nextYieldingObject:assignResolvablePromises(self)

                    local ok, returnedData = nextYieldingObject:run()
                    if nextYieldingObject.requiredPromises then
                        for _, promise in pairs(nextYieldingObject.requiredPromises) do
                            local fulfillable, kind = self:checkPromiseFulfillment(promise)
                            if fulfillable then
                                if not self.resolvablePromises[promise.UID] then
                                    self:queueTask(self.registeredTasks[kind])
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
                        print('Error running ' .. nextYieldingObject.name .. '; disabling. \n Error: ' .. textutils.serialise(returnedData))
                        nextYieldingObject:unqueueFromTaskSequence()
                        nextYieldingObject:disable()
                    end
                end
            until noYieldingObjectsLeft
            return self:yield(true)
        else
            return self:yield(true)
        end
    end,

    queueAction = function(self,func,...)
        local args = {...}
        local preppedFunc = function()
            func(unpack(args)) -- Darn lua varargs
            return thisTask:terminate()
        end

        local wrappingTask = Task:new {
            name = 'WrappingTask-' .. generateUID(),
            procedure = preppedFunc
        }

        self:queueTask(wrappingTask)
    end,

    enable = function(self)
        self.enabled = true
    end,

    disable = function(self)
        self.enabled = false
    end,

    register = function (self,task)
        self.registeredTasks[task.registeredOutcome] = task
    end,

    queue = function(self, task)
        table.insert(self.pendingTasks, task)
        task.enclosingTaskSequence = self
        task.index = #self.pendingTasks
    end,

    unqueue = function(self, task)
        table.remove(self.pendingTasks, task.index)
        task.index = nil
    end,

    getNextYieldingObject = function(self)
        if #self.pendingTasks < 1 then
            if self.enclosingTaskSequence.name then -- We check if the enclosing task sequence is actually an instantiated TaskSequence.
                self.enclosingTaskSequence:unqueueTask(self)
            else
                -- This TaskSequence does not have an enclosing TaskSequence, so
                -- we disable self in order to terminate the program.
                self:disable()
            end
        end
        if #self.tasksToRun <= 0 then
            for k,v in pairs(self.pendingTasks) do
                self.tasksToRun[k] = v
            end
            --self.tasksToRun = tableClone(self.pendingTasks)
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
