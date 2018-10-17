--[[

    ======================================================================
    ==================== STARTUP PROCEDURE FOR SKYNET ====================
    ======================================================================

    This file loads critical variables into the global table, clears cache
    variables that should not retain their values across program runs, and
    runs basic configuration procedures.

    23 August 2018
--]]


-- ===================== MODULE.LUA =====================
-- ============== /MWP/lib/core/module.lua ==============

-- Load the module library:
module = loadfile('/MWP/lib/core/module.lua')()
-- Clear loaded libraries:
module.clear_cache()

-- ================= NOTYOURMOMSLUA.LUA =================
-- ========== /MWP/lib/core/notyourmomslua.lua ==========

nym = module.require('/MWP/lib/core/notyourmomslua.lua')

-- ===================== CLASS.LUA ======================
-- ============== /MWP/lib/core/class.lua ===============

Class = module.require('/MWP/lib/core/class.lua')

-- ================== PERSISTENCE.LUA ===================
-- =========== /MWP/lib/core/persistence.lua ============

pst = module.require('/MWP/lib/core/persistence.lua')

-- ====================== SKYNETRC =======================
-- ================= /MWP/sys/skynetrc ===================
-- All files specified in skynetrc will be executed here after all critical
-- libraries have been loaded.
loadfile('/MWP/sys/skynetrc.lua')()
