function generateUID()
	local s1 = math.random(999999999)
	local s2 = math.random(999999999)
	local s3 = math.random(999999999)
	local s4 = math.random(999999999)
	return string.format("%09d", s1)..string.format("%09d", s2)..string.format("%09d", s3)..string.format("%09d", s4)
end

function splitString(inputstr, sep)
    -- Stolen from https://stackoverflow.com/questions/1426954/split-string-in-lua
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function splitString2(inputstr,substr)
    local t = {}
    local last_start = 1
    local next_index, next_start = inputstr:find(substr,last_start,true)
    local next_block
    while next_index do
        next_block = string.sub(inputstr,last_start,next_index-1)
        table.insert(t,next_block)
        last_start = next_start + 1
        next_index, next_start = inputstr:find(substr,last_start,true)
    end
    local final_block = string.sub(inputstr,last_start)
    table.insert(t,final_block)
    return t
end

function split(str, pat)
    local t = {} -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end
