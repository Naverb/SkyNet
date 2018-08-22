local module = loadfile('/MWP/lib/module.lua')()
local Class = module.require('/MWP/lib/class.lua')

Path = Class {
    constructor = function(self, name, waypoints)
        local obj = {
            name = assert(name, 'Attempted to create a path without specifying a name!'),
            waypoints = waypoints,
            destination = waypoints[#waypoints] or nil
        }

        return obj
    end,

    waypoints = {},
    name = 'Untitled_Path',
    currentWaypointNumber = 1,

    append = function(self,waypoint)
        table.insert(self.waypoints, waypoint)
        self.destination = waypoint
    end,

    pop = function(self)
        table.remove(self.waypoints)
    end,

    reset = function(self)
        self.currentWaypointNumber = 1
    end,

    traverse = function(self, params)
        local yield = params.yield or false
        local startingWaypointNumber = params.startAt or 1

        -- Move along the waypoints of the path.
        local i = startingWaypointNumber
        for i,waypoint in ipairs(self.waypoints) do
            self.currentWaypointNumber = i

            if yield then
                local response = coroutine.yield('path_yield', self.destination)

                if response.halt then
                    print('Path ' .. self.name .. ' has been halted. Rerun traverse() to continue the path.')
                    if response.reset then
                        self:reset()
                    end

                    break
                end

            end

            waypoint:go()
        end
    end
}

_module = Path
