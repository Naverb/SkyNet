--[[

    ======================================================================
    ==================== STARTUP PROCEDURE FOR SKYNET ====================
    ======================================================================

    This file loads critical variables into the global table, clears cache
    variables that should not retain their values across program runs, and
    runs basic configuration procedures.

    23 August 2018
--]]

-- This variable is used by some files to determine whether the system is
-- running through start.lua or through some other means.
IS_LOADER = true

-- ================ ELEMENTARY LOGGING ==================
-- =============== /MWP/lib/core/log.lua ================

local log_loader = loadfile('/MWP/lib/core/log.lua')
setfenv(log_loader, getfenv())
ok,log = pcall(log_loader)
if not ok then print(module) else print('Loaded logging API.') end

log.initialize()
-- While we are running in Skynet, we append this prefix to each line to make stdout cleaner.
LINE_PREFIX = '> '

-- ==================== FILE EXECUTION ==================
-- ======================================================
local function execute_files(filesToExec)
    for _,filepath in ipairs(filesToExec) do
        print('Executing ' .. tostring(filepath))
        local exec = loadfile(filepath)
        local exec_env = {LINE_PREFIX = '>> '}
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
            LINE_PREFIX = '> '
        end
    end
end
-- ===================== MODULE.LUA =====================
-- ============== /MWP/lib/core/module.lua ==============

-- Load the module library:
local module_loader = loadfile('/MWP/lib/core/module.lua')
setfenv(module_loader, getfenv())
ok, module = pcall(module_loader)
if not ok then print(module) else print('Module API loaded successfully.') end

-- Clear loaded libraries:
module.clear_module_cache()

-- ================= NOTYOURMOMSLUA.LUA =================
-- ========== /MWP/lib/core/notyourmomslua.lua ==========

nym = module.require('/MWP/lib/core/notyourmomslua.lua')

-- ===================== CLASS.LUA ======================
-- ============== /MWP/lib/core/class.lua ===============

Class = module.require('/MWP/lib/core/class.lua')

-- ===================== REPORTING ======================
-- ======== /MWP/lib/core/[error,reporting].lua =========

error_lib = module.require('/MWP/lib/core/error.lua')
Exception = error_lib.Exception
try = error_lib.try

-- ================== PERSISTENCE.LUA ===================
-- =========== /MWP/lib/core/persistence.lua ============

pst = module.require('/MWP/lib/core/persistence.lua')
pst.initialize()

-- ====================== SKYNETRC =======================
-- ================= /MWP/sys/skynetrc ===================
-- All files specified in skynetrc will be executed here after all critical
-- libraries have been loaded.

print('Running programs in skynetrc')
local executables_file = fs.open('/MWP/sys/skynetrc','r')
local executables = nym.readLines(executables_file)
executables_file.close()
execute_files(executables)

print('Executed all programs in skynetrc. Exiting to CraftOS.')
LINE_PREFIX = ''
