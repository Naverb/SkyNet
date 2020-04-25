local gps3 = module.require('/lib/move/gps3.lua')
local gps3_ctx = gps3.getGPSContext()
local gps3_cfg = config.retrieve('gps')

-- Standard Vectors
local I = vector.new(1,0,0)
local J = vector.new(0,1,0)
local K = vector.new(0,0,1)


------------------------------------------------------
----------------- HELPER FUNCTIONS -------------------

-- In order to deal with event handling higher up, we need to write helper functions
--      that yield the current coroutine before moving each block. Essentially, we are
--      creating a parallel system where the robot checks auxiliary functions after
--      moving a single block. That way, we can deal with event interrupts, etc..

local valid_move_multipliers = {
    forward = 1,
    back = -1,
    up = 1,
    down = -1,
    turnleft = 1,
    turnRight = 1
}
function move(moveCommand)
    -- Call turtle[moveCommand], updating context as necessary
    assert(valid_move_multipliers[moveCommand], "One must call a valid move command for move.move")
    local success = turtle[moveCommand]()
    if success then -- update context
        if moveCommand == 'turnRight' then
            -- Rotate the orientation vector pi/2 radians in xz plane
            local x_prime = -1 * gps3.getOrientation().z
            local z_prime = gps3.getOrientation().x

            gps3_ctx:set('orientation',{x_prime,0,z_prime})
        elseif moveCommand == 'turnleft' then
            -- Rotate the orientation vector -pi/2 radians in xz plane
            local z_prime = -1 * gps3.getOrientation().x
            local x_prime = gps3.getOrientation().z

            gps3_ctx:set('orientation',{x_prime,0,z_prime})
        else
            if not gps3_cfg.LOCAL_MODE then
                gps3.updateLocation()
            else
                if moveCommand == 'up' or moveCommand == 'down' then
                    gps3_ctx:set('location', gps3.getLocation() + valid_move_multipliers[moveCommand] * J)
                elseif moveCommand == 'forward' or moveCommand == 'back' then
                    gps3_ctx:set('location', gps3.getLocaton() + valid_move_multipliers[moveCommand] * gps3.getOrientation())
                else
                    local ex = Exception:new('Extraneous move case executed!')
                    ex:throw()
                end
            end
        end
    end

    return success
end

------------------------------------------------------
------------------ GOTO LOCATION ---------------------

-- Travel down trajectory vector
local function traverseTrajectory(trajectory, breakBlocks)

    local dx = trajectory.x
    local dy = trajectory.y
    local dz = trajectory.z

    local sign_x = dx/math.abs(dx)
    local sign_y = dy/math.abs(dy)
    local sign_z = dz/math.abs(dz)

    -- Move in x first
    if (dx ~= 0) then
        gps3.orient(I:mul(sign_x), true)
        for i = 1,math.abs(dx) do
            if not move 'forward' then
                if breakBlocks then
                    turtle.dig()
                    move 'forward'
                end
            end
        end
    end

    -- Move in z now
    if (dz ~= 0) then
        gps3.orient(K:mul(sign_z), true)
        for i = 1,math.abs(dz) do
            if move 'forward' then
                if breakBlocks then
                    turtle.dig()
                    move 'forward'
                end
            end
        end
    end

    -- Move in y
    if (sign_y) > 0 then
        for i = 1,math.abs(dy) do
            if not move 'up' then
                if breakBlocks then
                    turtle.digUp()
                    move 'up'
                end
            end
        end
    elseif (sign_y) < 0 then
        for i = 1,math.abs(dy) do
            if not move 'down' then
                if breakBlocks then
                    turtle.digDown()
                    move 'down'
                end
            end
        end
    end
end

-- Go to location (takes a 3 vector for destination). Tolerance is the
-- maximum distance from destination allowed
function goTo(destination, _breakBlocks, _tolerance)


    local breakBlocks = _breakBlocks or false
    local tolerance = _tolerance or 1

    repeat
        local err, trajectory = gps3.getTrajectory(destination)

        if not err then
            traverseTrajectory(trajectory, breakBlocks)
        else
            print('Failed to get trajectory, aborting goTo to '.. trajectory:tostring())
            break
        end

    until trajectory:length() < tolerance
    -- FIX ME until trajectory:round():length() < tolerance
end

------------------------------------------------------
-------------- ENVIROMENTAL ORIENTATION --------------

function orientChunk()
    local loc = gps3.getLocation()
    goTo(vector.new(loc.x - loc.x % 16, -- 16 BLOCKS IN A CHUNK
                    loc.y,
                    loc.z - loc.z % 16), true)
    gps3.orient(I, true)
    return loc.y
end
