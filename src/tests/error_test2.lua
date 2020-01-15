print('Beginning secondary error system test...')

try{
    body = function()
        local testEx = Exception:new('TestError','Test Message')
        testEx:throw()
    end
}
