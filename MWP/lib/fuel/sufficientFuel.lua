local gps2 = module.require('/MWP/lib/movement/gps2.lua')

function sufficientFuel(waypoint, fuelingStation)
    --[[
        return 1: Sufficient fuel to reach destination
        return -1: Sufficient fuel to reach refuel station
        retirn 0: Insufficient fuel to reach destination or a fueling station.
    ]]
    local fuelRange = turtle.getFuelLevel()
    local err, currentLocation = gps2.getLocation()
    local displacementToStation = fuelingStation.location - currentLocation
    local displacementToDestination = waypoint.location - currentLocation

    -- This is the distance in the blocks the turtle must travel to get to the fueling station
    local distanceToStation = math.abs(displacementToStation.x) + math.abs(displacementToStation.y) + math.abs(displacementToStation.z)
    local distanceToDestination = math.abs(displacementToDestination.x) + math.abs(displacementToDestination.y) + math.abs(displacementToDestination.z)

    if (fuelRange - distanceToDestination) > 25 then
        return 1 -- We have enough fuel to reach our destination
    end

    if ( (fuelRange - distanceToStation) < 25 and (fuelRange - distanceToStation) > 0) then
        -- We return true because we need to go to the refuelling station
        return -1
    elseif ( (fuelRange - distanceToStation) <= 0) then
        -- We don't have enough fuel to return home
        local delta = fuelRange - distanceToStation
        print('INSUFFICIENT FUEL TO REACH REFUEL STATION. Delta: ' .. delta)
        return 0, {delta = delta}
    end

    return 0 -- If all else fails, lets get some fuel just to be safe.
end

_module = module.exportFunction(sufficientFuel)
