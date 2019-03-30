local EMPTY_BOOL,EMPTY_PROPERTY = nym.EMPTY_BOOL,nym.EMPTY_PROPERTY

local Promise = Class {
    constructor = function(self,params)
        local _questionData = params.questionData
        local _askingTask = assert(params.askingTask, "Attempted to create a promise without specifying askingTask!")
        local _kind = assert(type(params.kind) == 'table', "Attempted to create a promise without specifying kind!")

        local obj = {
            UID             = nym.generateUID(),
            questionData    = _questionData,
            askingTask      = _askingTask,
            kind            = _kind
        }

        return obj
    end,

    UID             = EMPTY_PROPERTY,
    kind            = EMPTY_PROPERTY,
    askingTask      = EMPTY_PROPERTY,
    answeringTask   = EMPTY_PROPERTY,

    answerData = {}, -- The metadata that the answeringTask passes to resolve this Promise
    questionData = {}, -- The metadata that the askingTask passes to help resolve this Promise
    resolved = EMPTY_BOOL, -- A Promise is resolved if an answeringTask has supplied answerData
    reserved = EMPTY_BOOL, -- A Promise is reserved if there exists an answeringTask that will supply answerData in the near future.
    readyToDelete = false, -- A Promise is readyToDelete if its answerData was accessed, so it can be deleted.

    setReservedState = function(self,state,reservingTask)
        assert(type(state) == 'boolean', 'The reserved state of a Promise must be a boolean value!')
        assert(reservingTask,'Attempted to reserve Promise ' .. tostring(self.kind) .. ':' .. tostring(self.UID) .. ' without providing a Task to reserve it!')
        self.answeringTask = reservingTask
        self.reserved = true
    end,

    setResolvedState = function(self,state)
        assert(type(state) == 'boolean','The resolved state of a Promise must be a boolean value!')
        self.resolved = state
    end,

    isResolved = function(self)
        return self.resolved
    end,

    isReadyForDeletion = function(self)
        return self.readyToDelete
    end,

    markReadyForDeletion = function(self)
        self.readyToDelete = true
    end
}

_module = Promise
