METATABLE = getmetatable(_G)
for k,v in pairs(METATABLE) do print(k) end
METATABLE.__oldlt = METATABLE.__lt
METATABLE.__lt = function(lhs,rhs)
    if (type(lhs) == 'table' and type(rhs) == 'table') then
        lhs = tableClone(rhs)
        return true
    else
        return getmetatable(_G).__oldlt(lhs,rhs)
    end
end




print("printing  0 <= 1")
print(0 <= 1)
print("printing 'a' <= 'b'")
print("a" <= "b")
print("setting b={2}")
b = {2}
print("letting a <= b")
local a
_= a <= b
print("printing a")
print(textutils.serialize(a))
print("changing b")
b = {3}
print("printing a")
print(textutils.serialize(a))
printing("b")
print(textutils.serialize(b))


getmetatable('').__index = function(str,i) return string.sub(str,i,i) end
getmetatable('').__call = function(str,i) return string.upper(str) end
getmetatable('').__unm = function(str,i) return string.reverse(str) end
getmetatable('').__add = function(str,i) return (str .. i) end
getmetatable('').__mul = function(str,i) return string.rep(str, i) end

local str = "test"

print(str[2]) --> "e"
print(str()) --> "TEST"
print(-str) --> "tset"
print(str + "er") --> "tester"
print(str * 2) --> "testtest"

getmetatable('').__index = function(str,i) return type(i) == 'number' and string.sub(str,i,i) or string[i] end
