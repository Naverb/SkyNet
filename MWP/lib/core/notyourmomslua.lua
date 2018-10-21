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

-- SOME HELPER STUFF --
EMPTY_PROPERTY 	= '__empty__'
EMPTY_BOOL 		= false
