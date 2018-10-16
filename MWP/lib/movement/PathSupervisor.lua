local Task = module.require('/MWP/lib/yielding/Task.lua')
local fuellib = module.require('/MWP/lib/fuel')

PathSupervisor = Class {
    constructor = function(self, params)
        local obj = Task:new {
            name = assert(params.name, 'Attempted to create a PathSupervisor without specifying a name!'),
            registeredOutcome = 'path_yield',
            procedure = self.PathSupervisorProcedure,
            condition = params.condition,
        }

        if params.fuelingStation then
            obj.fuelingStation = params.fuelingStation
        end

        return obj
    end,

    extends = Task,

    fuelingStation = fuellib.defaultFuelStation,

    PathSupervisorProcedure = function()
        while true do
            local promisesToResolve = thisTask:findPromisesToResolve()

            local allPromisesResolved = true
            for _, promise in pairs(promisesToResolve) do

                promise:reserve(thisTask.name)

                local destination = promise.questionData[1]
                local fuelCheckerStatus, fuelData = fuellib.sufficientFuel(destination, thisTask.fuelingStation)

                local responseData
                if fuelCheckerStatus == 1 then
                    responseData = {halt = false, reset = false}
                    promise:resolve()
                elseif fuelCheckerStatus == -1 then
                    allPromisesResolved = false -- Once we get to the fueling station, we will want to continue traversing the path, so we don't resolve the path_yield promise yet.
                    responseData = {halt = true}
                    local fuelStn = fuellib.defaultFuelStation
                    fuelStn:go()

                    print('Normally, I refuel here. But this is a test.')
                    promise:resolve()
                else
                    -- The fuel checker has determined that there is not enough
                    -- fuel to get to either the destination or the fueling
                    -- station. This shouldn't happen, so we'll stop the turtle.
                    responseData = {halt = true}
                    promise:resolve()
                end

                promise.answerData = {responseData}
            end

            if allPromisesResolved then
                thisTask:unqueueFromTaskSequence()
            end

            thisTask:yield()
        end
    end
}

_module = PathSupervisor
