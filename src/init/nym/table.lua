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
