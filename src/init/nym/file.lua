function run(filepath,...)
    -- Runs a lua file at filepath and returns either the return statement or
    -- any error encountered during execution. When filepath is executed the
    -- current function environment is set as the global function environment
    -- for the script. This ensures that the script has access to all global
    -- variables.
    assert(filepath,'Argument to nym.file.run should be nonempty!')
    local exec = loadfile(filepath)
    assert(exec,'Failed to load file ' .. filepath)
    setfenv(exec, getfenv())
    return pcall(exec,...)
end

function readLines(filepath)
    local file = fs.open(filepath,'r')
    local first_line = file.readLine()
    local lines = {}
    if not first_line then
        return nil
    else
        table.insert(lines,first_line)
        local next_line = file.readLine()
        while next_line and (next_line ~= '') do
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
