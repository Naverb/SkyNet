function yielding_object:yield(...)
    promises = table.pack(...)
    coroutine.yield(promises)
end

tS {

    tS.promises = {
        'fuel': data,
        'storage': data,...
    }

task.goToWaypoint {
    {initial stuff}
    move.forward()
        while true do
            ->receivedPromiseData = {yield and for check for fuel} (yields)
            if (receivedPromiseData.sufficientFuel) then
                turtle.forward()
            else yield
        end
    ...



}


    {task: question
    task2: question
}

    promisesINeed = {}


    taskCode {
        doStuff

        questionData = {...}
        sufficientFuelCheck = self:newPromise('fuel',questionData)
        self:yield(sufficientFuelCheck)
    }

    function task:newPromise(type, questionData)
        local obj = {}
        obj.type = type
        obj.askingTask = self
        obj.questionData = questionData
        return obj
    end



    function task:yield(requiredPromises)
        for _,promise in pairs(requiredPromises) do
            task.parent:registerPromise(promise)
        end
        coroutine.yield()
    end

    function taskSequence:registerPromise(promise)
        self.promisesINeed[promise.type].append(promise)
    end

    requiredPromises = coroutine.resume(task)
    Now I know task needs {fuelPromise, storagePromise, locationPromise}

    resume task2
    Now I know task2 needs 'fuel', 'potato'

    repeat for all tasks
        promisesINeed.append(requiredPromises)

        promisesINeed = {
            fuelPromises {
                fuelPromise = {
                    askingTask: task1,
                    type = 'fuel'
                    questionData: {...}
                },
                fuelPromise2 = {
                    askingTask: task2,
                    ...
                }
            }
        }

    fuelChecker {
        for _,promises in pairs(fuelPromises) do:
            ...
    }

    tS.promises = {}

    coroutine.yield(promisesINeed)
}



{code}

    requiredPromises = {
        'fuel','storage','location'
    }

    thisTask:yield(requiredPromises)
