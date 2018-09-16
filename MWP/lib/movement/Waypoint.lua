local module = loadfile('/MWP/lib/module.lua')()
local Class = module.require('/MWP/lib/class.lua')
local gps2 = module.require('/MWP/lib/movement/gps2.lua')
local move = module.require('/MWP/lib/movement/move.lua')

Waypoint = Class {
    constructor = function(self, _name, loc)
        local obj = {
            name = _name,
            location = loc,
            err = false
        }
        return obj
    end,

    name = 'untitled_waypoint',
    location = vector.new(0,0,0),

    updateLocation = function(self, newLocation)
        local err, loc = false, newLocation or gps2.getLocation()
        if not err then
            self.location = loc
        elseif err then
            self.err = true
        end
    end,

    go = function(self, tolerance, breakBlocks)
        print('Going to waypoint ' .. self.name)
        print(self.location)
        local err, prevLoc = gps2.getLocation()
        move.goTo(self.location, breakBlocks, tolerance)
        previous_location:updateLocation(prevLoc)
    end
}

-- We create this global variable so that we may work with the robot's prior location
local err, loc = gps2.getLocation()
if not err then
    previous_location = Waypoint:new('Previous_Location', loc)
elseif err then
    previous_location = Waypoint:new('Previous_Location', vector.new(0,0,0))
end

-- Now we append this attribute to the class.
Waypoint.previous_location = previous_location

_module = Waypoint
