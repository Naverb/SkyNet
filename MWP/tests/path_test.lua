local tasklib = module.require('/MWP/lib/yielding')
local movelib = module.require('/MWP/lib/movement')
local fuellib = module.require('/MWP/lib/fuel')

local corner1 = vector.new(-114,91,359)
local corner2 = vector.new(-178,91,359)
local corner3 = vector.new(-178,91,427)
local corner4 = vector.new(-114,91,423)

local _home = vector.new(-119,95,366)

local point1 = movelib.Waypoint:new('point1',corner1)
local point2 = movelib.Waypoint:new('point2',corner2)
local point3 = movelib.Waypoint:new('point3',corner3)
local point4 = movelib.Waypoint:new('point4',corner4)
local home = movelib.Waypoint:new('home', _home)

print('Testing path')

local path = movelib.Path:new('TestPath', {point1,point2,point3,point4})

print(path.name)

local TS = tasklib.TaskSequence:new { name = 'MainTaskSequence' }
local mainPathSupervisor = movelib.PathSupervisor:new{ name = 'MPS' } -- MainPathSupervisor
local legacyEventHandler = tasklib.LegacyEventHandler:new()

print('Registering MPS')
TS:registerToRegisteredTasks(mainPathSupervisor)
print('Registering LEH')
TS:registerToRegisteredTasks(legacyEventHandler)
local params = {yield = true, startAt = 1}
TS:queueAction(path.traverse, path, params)

repeat
    TS:run()
until not TS.enabled
