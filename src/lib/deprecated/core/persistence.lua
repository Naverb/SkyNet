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
        try {
            body = function()
                fs.makeDir(PERSISTENCE_PATH)
            end
        }
    end
end
function get(key)
    -- Get the value of the persistent variable with label "key"
    local varpath = fs.combine(PERSISTENCE_PATH,key)
    if fs.exists(varpath) then
        local file = fs.open(varpath,"r")
        local value = try {
            body = function()
                local results = file.readAll()
                return results
            end,
            catch = function(ex)
                Exception:new('Failed to read the value of the persistence variable ' .. key):throw()
            end,
            finally = function()
                file.close()
            end
        }
        value = textutils.unserialize(value)
        return value
    else
        return nil
    end
end

function set(key,value)
    -- Set the value of the persistence variable with label "key" and value "var"

    -- We first test whether the value we are about to write is not too complicated for the persistence filesystem.
    local serialized_value = textutils.serialize(value)
    local varpath = fs.combine(PERSISTENCE_PATH,key)
    local file = fs.open(varpath,"w")
    try {
        body = function()
            file.write(serialized_value)
        end,
        catch = function(ex) ex:throw() end,
        finally = function()
            file.close()
        end
    }
end

function delete(key)
    -- Delete the persistence variable with label "key"
    local varpath = fs.combine(PERSISTENCE_PATH,key)
    try {
        body = function()
            fs.delete(varpath)
        end
    }
end
