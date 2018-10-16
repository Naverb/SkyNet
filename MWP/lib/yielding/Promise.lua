local EMPTY_BOOL = nym.EMPTY_BOOL
local EMPTY_PROPERTY = nym.EMPTY_PROPERTY
local generateUID = nym.generateUID

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
        }

        -- Promise.kind can either be a string or an array of strings. If
        -- Promise.kind is an array, a TaskSequence will check for tasks that
        -- can fulfill the promise in the order of the kinds listed in the
        -- array.

        if type(_kind) == 'table' then
            obj.kind = _kind
        else
            obj.kind = {_kind}
        end
        return obj
    end,

    UID                 = EMPTY_PROPERTY,
    dataWasAccessed     = EMPTY_BOOL,
    status              = 1,
    --[[
        status = 1: Promise is not resolved, and no task is trying to resolve it.
        status = 0: Promise is resolved.
        status = -1: Promise is not resolved, and a task is trying to resolve it.
    ]]
    answerData          = {},
    questionData        = {},
    askingTask          = EMPTY_PROPERTY,
    answeringTask       = EMPTY_PROPERTY,
    kind                = EMPTY_PROPERTY,

    reserved = function(self, context)
        if (self.status <= 0) and (context ~= self.answeringTask) then
            return true
        else
            return false
        end
    end,

    resolved = function(self)
        return self.status == 0
    end,

    resolve = function(self)
        self.status = 0
    end,

    unResolve = function(self)
        self.status = 1
    end,

    reserve = function(self,context)
        self.status = -1
        self.answeringTask = context or nil -- Will we always be within the context of a task's procedure when calling this?
    end
}

_module = Promise
