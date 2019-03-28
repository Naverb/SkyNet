print('Beginning secondary error system test...')

try(function()
        local testEx = Exception:new('TestError','Test Message')
        testEx:throw()
    end
)
