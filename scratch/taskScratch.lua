local function waitOrTimeout(promise)
    local response
    local timeout = os.startTimer(3) -- 30 seconds is probably a long time.

    print('Question data:')
    for key,_ in pairs(promise.questionData) do
        print(key)
    end
    print('End question data.')

    if true then--(not promise.questionData) or (promise.questionData == {}) then
        local done = false
        repeat
            print('Pulling a null event now...')
            response = {os.pullEventRaw()}
            if response[1] == 'timer' and response[2] == timeout then
                print('Timed out.')
                done = true
                response = nil
            else
                print('Got event.')
                promise.answerData = response
                promise.resolved = true
                done = true
            end
        until done
        print('Event pulled.')
    elseif promise.questionData ~= {} then
        local done = false
        repeat
            print('Pulling an event now...')
            for k,_ in pairs(promise.questionData) do
                print(k)
            end
            print('End event info.')
            response = {os.pullEventRaw(promise.questionData)}
            if response[1] == 'timer' and response[2] == timeout then
                print('Timed out.')
                done = true
                response = nil
            else
                print('Got event.')
                promise.answerData = response
                promise.resolved = true
                done = true
            end
        until done
        print('Event pulled.')
    end
end
