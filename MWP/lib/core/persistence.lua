--[[

    ======================================================================
    ===================== SKYNET PERSISTENCE LIBRARY =====================
    ======================================================================

    Investigating chunk loading, we found that regardless of the usage of
    vanilla chunk loaders, turtles would reboot once the player leaves the
    region. This creates the issue of keeping track of variables and the
    last actions of the turtle before rebooting. The persistence library
    solves this problem by sandboxing lua blocks, tracking changes to the
    lua table, and writing changes to a file on board the turtle. On
    reboot, this file is reviewed to restore the state of the turtle
    before reboot. Coupled with the yielding API, we can yield each task
    after each update to the persistence file, keeping the saved state as
    up to date as possible.

    23 August 2018

--]]

function persistent(value)
    local vartable = { persistent = true, value = value }
    if type(value) == 'table' then
        -- Here we check to see if a reference to this table has already been
        -- saved to the persistence filesystem.
        vartable.persistedData = 'SOME STRING THAT IDENTIFIES THE LOCATION OF THE TABLE IN THE PERSISTENT FILESYSTEM.'
    else
        vartable.persistedData = value
    end
    return vartable
    -- We are going to intercept the newIndex method via function environments,
    -- so the variable should never end up with the value of vartable.
end

local function grabData(path)

end

persistence_mt = {
    -- This table is the template for a metatable that handles writing the
    -- current computer state to storage.

    __index = function(tbl,key)
        -- Recall the value of the global var 'key'.

        -- First we check if a value for the variable exists.
        local val = rawget(tbl,key) or nil
        if not val then
            -- If no value exists, we check the persistent filesystem.
            local varpath = fs.join(tbl._PERSISTENCE_PATH, key)
            if fs.exists(varpath) then
                val = grabData(varpath)
            else
                -- The variable does not exist in the persistent filesystem, so
                -- we check the enclosing environment for the variable.

            end
        end

        return val
    end,

    __newindex = function(tbl,key,val)
        -- Set the value of 'key' to 'val'

        -- Create a filepath to store the persistent data.
        local varpath = fs.combine(tbl._PERSISTENCE_PATH, key)

        if val.persistent then
            -- We identify that the variable in question is a persistent
            -- variable, so now we move forward.
            local enclosingDir = fs.getDir(varpath)

            if not fs.exists(enclosingDir) then
                fs.makeDir(enclosingDir)
            end

            local file = fs.open(varpath, 'w')
            file.write(val.persistedData) -- Should we cast to string?
            file.close()

            -- Save the value of the variable to the environment.
            rawset(tbl,key,val.value)
        else
            -- Save the value of the variable to the environment.
            if type(val) == 'function' then
                -- Since we are creating a function, we add some metadata to the
                -- function's environment for the persistence filesystem.
                local f_env = { _PERSISTENCE_PATH = varpath }
                local f_env_mt = { __index = getfenv() }
                setmetatable(f_env,f_env_mt)
                setfenv(val, f_env)
            end
            rawset(tbl,key,val)
        end
    end
}
