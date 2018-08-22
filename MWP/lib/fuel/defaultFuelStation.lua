local module = loadfile('/MWP/lib/module.lua')()
local Waypoint = module.require('/MWP/lib/movement/Waypoint.lua')

fuelingStation = Waypoint:new('fuelingStation', vector.new(-145,93,375))

_module = fuelingStation
