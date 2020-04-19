-- Standard vectors
local I = vector.new(1,0,0)
local J = vector.new(0,1,0)
local K = vector.new(0,0,1)

local Context = module.require('/lib/task/Context.lua')
local gps3_ctx = Context:new()
local gps3_cfg = config.retrieve('gps')
gps3_ctx:bind('gps3')

function getGPSContext()
    return gps3_ctx
end

function getLocation()
    return vector.new(table.unpack(gps3_ctx:get('location')))
end

function getorientation()
    return vector.new(table.unpack(gps3_ctx:get('orientation')))
end

function updateLocation()
    if not gps3_cfg.LOCAL_MODE then
        local loc = vector.new(gps.locate(5))
        if loc then
            gps3_ctx:set('location',loc)
        end
    else
        local ex = Exception:new('Cannot run gps3.updateLocation when local mode is enabled', 'gps3Exception')
        ex:throw()
    end
end

function updateOrientation()
    assert(turtle,'gps3.updateOrientation must be called on a turtle.')
    assert(not gps3_cfg.LOCAL_MODE, 'gps3.updateOrientation cannot be called when local mode is enabled.')

    updateLocation()
    local loc1 = getLocation()

    local dy = 0
    local loc2_ready = false
    -- We need to move the turtle to get a displacement vector to calculate
    -- orientation
    repeat
        if turtle.forward() then
            loc2_ready = true
        else
            if turtle.up() then
                dy = dy + 1
            else
                if turtle.digUp() then
                    turtle.up()
                    dy = dy + 1
                else
                    local ex = Exception:new('Failed gps3.updateOrientation. Is turtle obstructed?','gps3Exception')
                    ex:throw()
                end
            end
        end
    until loc2_ready

    updateLocation()
    local loc2 = getLocation()

    -- Now move back to starting point
    turtle.back()
    for i=1,dy,1 do
        turtle.down()
    end

    local displacement = loc2 - loc1
    -- We don't care about the vertical component
    displacement.y = 0
    -- Note at this point, displacement must equal +- I,J, or K
    gps3_ctx:set('orientation',displacement)
end

function orient(direction)
    assert(direction:length() > 0,'gps3.orient needs nonzero direction.')
    if not (direction:dot(getOrientation()) > 0) then
        repeat
            turtle.turnRight()
            -- Rotate the orientation vector pi/2 radians in xz plane
            local x_prime = -1 * getOrientation().z
            local z_prime = getOrientation().x

            gps3_ctx:set('orientation',{x_prime,0,z_prime})
        until (direction:dot(getOrientation()) > 0)
    end
end

function getTrajectory(dest)
    return dest - getLocation()
end
