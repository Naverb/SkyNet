Scheduler = Class {
    consturctor = function(self,args)
        local obj = {
            persistent = args.persistent or true,
            macros = {},
            current_micros = {},
        }

        return obj
    end,

    queueMacroTask = function(newMacro)

    end,

    dropCurrentMacroTask = function()

    end,

    getNextMacro = function()

    end,


}
