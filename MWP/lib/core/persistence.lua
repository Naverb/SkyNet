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

PERSISTENCE_PATH = "/persistence"

function initialize()
    -- We run this function at startup to initialize the persistence filesystem
    if not fs.exists(PERSISTENCE_PATH) then
        ok, err = pcall(fs.makeDir,PERSISTENCE_PATH)
        if not ok then
            error(err)
        end
    end
end
function get(key)
    -- Get the value of the persistent variable with label "key"
    local varpath = fs.join(PERSISTENCE_PATH,key)
    if fs.exists(varpath) then
        local file = fs.open(varpath,"r")
        local ok, value = pcall(file.readAll)
        if ok then
            -- We now format the data from the string form in which it was stored.
            value = textutils.unserialize(value)
            file.close()
        else
            error("Failed to read the value of the persistence variable " .. key)
        end
        return value
    else
        return nil
    end
end

function set(key,value)
    -- Set the value of the persistence variable with label "key" and value "var"

    -- We first test whether the value we are about to write is not too complicated for the persistence filesystem.
    local serialized_value = textutils.serialize(value)
    local varpath = fs.join(PERSISTENCE_PATH,key)
    local file = fs.open(varpath,"w")

    local ok, err = pcall(file.write,serialized_value)

    if not ok then
        -- We should really revamp our error/logging system.
        error(err)
    end
end

function delete(key)
    -- Delete the persistence variable with label "key"
    local varpath = fs.join(PERSISTENCE_PATH,key)
    local ok, err = pcall(file.delete,varpath)

    if not ok then
        error(err)
    end
end

_module = {
    initialize = initialize,
    get = get,
    set = set,
    delete = delete
}
