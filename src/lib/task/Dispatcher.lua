-- Naive Dispatcher class. Based on the cc-tweaked/computercraft parallel API
--- @class Dispatcher
--- @field context Context
Dispatcher = Class {
    constructor = function (self,context)
        local obj = {
            -- Entries of tasks are coroutines.
            tasks = {},
            context = context
        }
        return obj
    end,

    getTasksCount = function (self)
        -- Surely there must be a better way to accomplish thiss
        local count = 0
        for _ in pairs(self.tasks) do
            count = count + 1
        end
        return count
    end,
    queue = function (self, name, task)
        assert(name, 'Cannot queue a task without a name!')
        if type(task) == 'function' then
            local env_table = {
                _ParentDispatcher = self
            }
            setmetatable(env_table,{
                __index = getfenv()
            })
            setfenv(task,env_table)
            task = coroutine.create(task)
        else
            local ex = Exception:new('Attempted to queue a task with type ' .. type(task), 'DispatcherQueueException')
            ex:throw()
        end

        self.tasks[name] = task
    end,

    delete = function (self,task_name)
        self.tasks[task_name] = nil
        self.context:delete(task_name)
    end,

    expired = function (self)
        -- When a Dispatcher is expired, the current yield_data from
        -- os.pullEventRaw() is considered not up-to-date, so any task that
        -- needed to use this yield_data will be prohibited from running until
        -- new data is retrieved.
        return self.context:get('__expired')
    end,

    expire = function (self)
        self.context:set('__expired', true)
    end,

    unexpire = function (self)
        self.context:set('__expired',false)
    end,

    cycle = function (self,...)
        -- Run all tasks once. Delete any tasks that are dead.
        local passed_args = {...}
        -- Iterate through all tasks, and run as many as possible
        for task_name, task_coroutine in pairs(self.tasks) do
            local task_context_data = self.context:get(task_name)

            if task_context_data == nil or (task_context_data[1] == passed_args[1] and not self:expired() ) or passed_args[1] == "terminate" then

                local returned_data = { coroutine.resume(task_coroutine,...) }

                if returned_data[1] then
                    -- the coroutine ran successfully
                    self.context:set(task_name,{ table.unpack(returned_data,2) })
                else
                    print('Task ' .. tostring(task_name) .. ' has encountered an error.')
                    print(tostring(returned_data[2])) -- The error
                    self:delete(task_name)
                end
            end

            if coroutine.status(task_coroutine) == 'dead' then
                print('Coroutine died!')
                self:delete(task_name)
            end
        end
    end,

    run = function (self)
        local yield_data = self.context:get('__yield_data') or {}
        repeat
            self:cycle(table.unpack(yield_data))
            yield_data = {os.pullEventRaw()} -- Should this just be pullEvent?
            self:unexpire()
            self.context:set('__yield_data',yield_data)
        until self:getTasksCount() < 1
    end

}
_module = Dispatcher
