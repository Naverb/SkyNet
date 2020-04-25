local Dispatcher = module.require('/lib/task/Dispatcher.lua')
local Context = module.require('/lib/task/Context.lua')
local gps = module.require('/lib/move/gps3.lua')
local movelib = module.require('/lib/move/move.lua')
local move = movelib.move

gps.updateOrientation()

local ctx = Context:new()
ctx:bind('tree_farm')
local d = Dispatcher:new(ctx)
