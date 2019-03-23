print('Beginning error system test.')

try(function()
    try(function()
            print('Entering try')
            local testEx = Exception:new('Test Error', 'Test Message')
            testEx:throw()
        end,
        function(ex)
            print('Caught exception')
            print(ex:string())

            print('Testing how exceptions are cast as strings now...')

            error('Test Error 2')
        end,
        function()
            print('Running finally...')
        end
    )
end,
function(ex)
    print('Caught another exception.')
    ex:throw()
end
)
