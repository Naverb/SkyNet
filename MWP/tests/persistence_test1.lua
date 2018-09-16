function woah()
    g = 10
    print('g = ' .. 10 .. ' m/s/s')
    g = 9.8
end

local env = { name = 'woah environment'}
local env_mt = {
    __index = function(tab, key)
        print('Recalling ' .. tostring(key) .. '.')
        return _G[key]
    end,
    __newindex = function(tab,key,val)
        rawset(tab,key,val)
        print('Setting global var ' .. tostring(key) .. ' = ' .. tostring(val) .. ' in ' .. tab.name)
        _G[key] = val
    end
}

setmetatable(env,env_mt)
setfenv(woah,env)

woah()

for k,v in pairs(env) do
    print(k .. ' = ' .. tostring(v))
end
