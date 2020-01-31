--[[

    ======================================================================
    ==================== STARTUP PROCEDURE FOR SKYNET ====================
    ======================================================================

    This file loads critical variables into the global table, clears cache
    variables that should not retain their values across program runs, and
    runs basic configuration procedures.

    23 August 2018
--]]

print('Handed post-init to start.lua!')

-- This variable is used by some files to determine whether the system is
-- running through start.lua or through some other means.
IS_LOADER = true

-- Load the module library:
local module_loader = loadfile('/lib/core/module.lua')
setfenv(module_loader, getfenv())
ok, module = pcall(module_loader)
if not ok then print(module) else print('Module API loaded successfully.') end

-- Clear loaded libraries:
module.clearModuleCache()

-- Load main libraries
config = module.require('/lib/core/config.lua')
Class = module.require('/lib/core/class.lua')

pst = module.require('/lib/core/pst/pst2.lua')
pst.generate()
_P = pst.bind()

-- ====================== SKYNETRC =======================
-- =================== /etc/skynetrc =====================
-- All files specified in skynetrc will be executed here after all critical
-- libraries have been loaded.

local function executeFiles(filesToExec)
    for _,filepath in ipairs(filesToExec) do
        print('Executing ' .. tostring(filepath))
        local exec = loadfile(filepath)
        local exec_env = {LINE_PREFIX = tostring(filepath) .. '>> '}
        setmetatable(exec_env,{__index = getfenv()})
        setfenv(exec,exec_env)
        -- We pass the filepath to the first argument of the executable. In a way, this emulates the way the first argument of a bash script is always the path to the current executable.
        local ok, result = pcall(exec,filepath)
        if not ok then
            LINE_PREFIX = '!!> '
            print(filepath .. ' failed to load properly. Received Error:')
            LINE_PREFIX = ''
            local ex = Exception:unserialize(result)
            print(ex:string())
            LINE_PREFIX = 'SKYNET> '
        end
    end
end

local executables = nym.file.readLines('/etc/skynetrc')
print('Running programs in skynetrc')
executeFiles(executables)

print('Executed all programs in skynetrc. Exiting to CraftOS.')
LINE_PREFIX = ''
