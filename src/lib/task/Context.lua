--- A naive context Class with getters and setters to interact with persistence.
--- @Class Context
Context = Class {
    hooks = {},
    bind = function(self,label)
        if not _P.context then
            _P.context = {}
        end
        if not _P.context[label] then
            _P.context[label] = {}
        end
        self.data = _P.context[label]
    end,
    hook = function(self,var,action)
        -- Should an action eventually be able to yield? I.e. should this really
        -- be a Task?
        self.hooks[var] = action
    end,
    get = function(self,var)
        local current_value = self.data[var]
        -- Run any hook to update data.
        if self.hooks[var] then
            -- We pass this as an argument to prevent calling get(var) within an
            -- action (with the same var) and regressing into an infinite loop.
            self.hooks[var](current_value)
        end
        return self.data[var] -- Now the variable is possibly updated
    end,
    set = function(self,var,val)
        self.data[var] = val
    end,
    delete = function(self,var)
        self.data[var] = nil
        self.hooks[var] = nil
    end
}

_module = Context
