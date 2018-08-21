function tableClone(tbl)
    newTbl = {}

    if type(tbl) == 'table' then
        for k,v in pairs(tbl) do
            newTbl[k] = v
        end
    else
        print('Attempted to clone empty table!')
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

-- SOME HELPER STUFF --
EMPTY_PROPERTY 	= '__empty__'
EMPTY_BOOL 		= false
