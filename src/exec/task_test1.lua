Dispatcher = module.require('/lib/task/Dispatcher.lua')
Context = module.require('/lib/task/Context.lua')

local ctx = Context:new()
ctx:bind('test_main')
local d = Dispatcher:new(ctx)

d:queue('ATask',function ()
    print('Function A is being run!')
    local msg = os.pullEvent('BResponse')
    print('Function A here. B responded: ' .. tostring(msg))
    os.queueEvent('AResponse', 'Hello from A!')
    return 0
end)

d:queue('BTask',function ()
    print('Function B is being run!')
    os.queueEvent('BResponse', 'Hello from B!')
    local msg = os.pullEvent('AResponse')
    print('Function B here. A responded back: ' .. tostring(msg))
    return 0
end,'BTask')

print('Starting test.')
d:run()
print('Test complete!')
