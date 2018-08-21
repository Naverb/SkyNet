local module = loadfile('/MWP/lib/module.lua')()
local EMPTY_BOOL = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_BOOL
local EMPTY_PROPERTY = module.require('/MWP/lib/notyourmomslua.lua').EMPTY_PROPERTY
local generateUID = module.require('/MWP/lib/notyourmomslua.lua').generateUID

local Class = module.require('/MWP/lib/class.lua')

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
    resolved            = EMPTY_BOOL,
    answerData          = {},
    questionData        = {},
    askingTask          = EMPTY_PROPERTY,
    kind                = EMPTY_PROPERTY
}

_module = Promise
