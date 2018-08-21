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

_module = Promise
