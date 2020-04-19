Context = module.require('/lib/task/Context.lua')

local ctx = Context:new()

ctx:bind('test_main')

ctx:set('foo',0)

ctx:hook('foo', function (foo_val)
    print('Received hook for reading foo!')
    print('Current value: ' .. foo_val)
    ctx:set('foo',foo_val + 1)
end)

for i= 1,10 do
    print('Level ' .. i)
    local val = ctx:get('foo')
    print('Context returns ' .. val .. ' for foo.')
end

ctx:delete('foo')
