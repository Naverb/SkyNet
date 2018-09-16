--[[
	THE WAYPOINT API

An object-based library to move around the world. This allows us to easily communicate locations of interest by serializing the waypoint object. Hence, with this library, going somewhere should be as simple as waypoint:go().

]]


local function go(self)
	print('Going to waypoint ' .. self.name .. ' @' .. self.location)
	local prevLoc = gps2.getLocation()
	move.goTo(self.location, self.breakBlocks, self.tolerance)
	previous_location:updateLocation(prevLoc)
end

-- @CLASS Waypoint @PARAMS {name,location [, tolerance, breakBlocks]}
Waypoint = class.Class{
	constructor = function(self, params)
		local obj = task3.task:new{
			location = assert(params.location, "Attempted to create a waypoint without specifying a location"),
			name = params.name or "untitled waypoint @" .. params.location,
			tolerance = params.tolerance or 1,
			breakBlocks = params.breakBlocks or false,
			procedure = go 
		}
		return obj
	end
}
-- @FUNCTION Waypoint.updateLocation @PARAMS (self, newLoc)
function Waypoint:updateLocation(newLoc)
	self.location = assert(newLoc, "Attempted to update location of waypoint without specifying a location")
end

-- I am not convinced we should put the "go" function in here - it feels this belongs to some form of movement library. The waypoint library seems like it ought to merely handle the creation and handling of waypoints
-- The waypoint API is separate from standard "move" commands. Moving 'go' outside of waypoint destroys the one thing for which the waypoint API was initially designed: an object-based system of navigation

-- @GLOBAL previous_location
local err, loc = gps2.getLocation()
previous_location = Waypoint:new{
	name = 'Previous_Location',
	location = loc or vector.new(0,0,0) -- We want to make sure previous_location is initialized.
}
