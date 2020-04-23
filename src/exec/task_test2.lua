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

    print('Waiting for a key press now')

    local event, key_code = os.pullEvent('key')
    print('A here. Received key ' .. keys.getName(key_code))
    _ParentDispatcher:expire()
    return 0
end)

d:queue('BTask',function ()
    print('Function B is being run!')
    os.queueEvent('BResponse', 'Hello from B!')
    local msg = os.pullEvent('AResponse')
    print('Function B here. A responded back: ' .. tostring(msg))

    print('Waiting for a key press now')

    local event, key_code = os.pullEvent('key')
    print('B here. Received key ' .. keys.getName(key_code))

    return 0
end)

print('Starting test.')
d:run()
print('Test complete!')

pst.delete('context')
