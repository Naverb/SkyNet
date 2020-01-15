function tableClone(tbl)
    local newTbl = {}

    if type(tbl) == 'table' then
        for k,v in pairs(tbl) do
            if type(v) == 'table' then
                newTbl[k] = tableClone(v)
            else
                newTbl[k] = v
            end
        end
    else
        print('Attempted to clone empty table!')
    end

    local mt = getmetatable(tbl)

    if not mt then
        setmetatable(newTbl, {})
    else
        setmetatable(newTbl, mt)
    end

    return newTbl
end

function generateUID()
	local s1 = math.random(999999999)
	local s2 = math.random(999999999)
	local s3 = math.random(999999999)
	local s4 = math.random(999999999)
	return string.format("%09d", s1)..string.format("%09d", s2)..string.format("%09d", s3)..string.format("%09d", s4)
end

function run(filepath,...)
    -- Runs a lua file at filepath and returns either the return statement or
    -- any error encountered during execution. When filepath is executed the
    -- current function environment is set as the global function environment
    -- for the script. This ensures that the script has access to all global
    -- variables.
    local exec = loadfile(filepath)
    setfenv(exec, getfenv())
    return pcall(exec,...)
end

function readLines(file)
    local first_line = file.readLine()
    local lines = {}
    if not first_line then
        return nil
    else
        table.insert(lines,first_line)
        local next_line = file.readLine()
        while next_line do
            table.insert(lines,next_line)
            next_line = file.readLine()
        end
        file.close()
        return lines
    end
end

function prependToFile(filepath,str)
    if fs.exists(filepath) then
        local file = fs.open(filepath,"r")
        local old_data = file.readAll()
        file.close()
        file = fs.open(filepath,"w")

        file.writeLine(str)
        file.write(old_data)

        file.close()
    end
end

function appendToFile(filepath,str)
    local file = fs.open(filepath,"a")
    local ok,err = pcall(file.writeLine,str)
    if not ok then
        error(err,1)
    end
    file.close()
end

function removeFromFile(filepath,str)
    local file = fs.open(filepath,"r")
    local ok, data = pcall(file.readAll)
    if ok then
        file.close()
        data = string.gsub(data,str,'')
        file = fs.open(filepath,"w")
        file.write(data)
        file.close()
    else
        file.close()
        -- Something went wrong with getting data, so let's not overwrite the file.
        error(data,1)
    end
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

-- SOME HELPER STUFF --
EMPTY_PROPERTY 	= '__empty__'
EMPTY_BOOL 		= false
