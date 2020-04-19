local gps = module.require('/lib/move/gps3.lua')
local move = module.require('/lib/move/move.lua')

Waypoint = Class {
    constructor = function(self, _name, loc)
        local obj = {
            name = _name,
            location = loc,
        }
        return obj
    end,

    reconstruct = function(self,table)
        assert(table.name and table.location, "Waypoint data must be provided to Waypoint.reconstruct.")
        -- Since waypoints will likely be stored in persistence, we need a way
        -- regenerate a waypoint object from the table containing its data.
        return self:new(table.name,table.location)
    end,

    name = 'untitled_waypoint',
    location = vector.new(0,0,0),

    updateLocation = function(self, newLocation)
        self.location = newLocation or gps.getLocation()
    end,

    go = function(self, tolerance, breakBlocks)
        print('Going to waypoint ' .. self.name)
        print(self.location)
        local prevLoc = gps.getLocation()
        move.goTo(self.location, breakBlocks, tolerance)
    end
}

_module = Waypoint
