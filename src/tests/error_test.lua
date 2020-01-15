print('Beginning error system test.')

try {
    body = function()
        try {
            body = function()
                print('Entering try')
                local testEx = Exception:new('Test Error', 'Test Message')
                testEx:throw()
            end,
            catch = function(ex)
                print('Caught exception')
                print(ex:string())

                print('Testing how exceptions are cast as strings now...')

                error('Test Error 2')
            end,
            finally = function()
                print('Running finally...')
            end
        }
    end,
    catch = function(ex)
        print('Caught another exception.')
        ex:throw()
    end
}
