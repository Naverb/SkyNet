I = vector.new(1,0,0)
J = vector.new(0,1,0)
K = vector.new(0,0,1)


-- Get location of computer using rednet
function getLocation()
    local loc = gps.locate(5)
    if not loc then
        return true, nil
        -- We return error = true and loc = nil
    else
        return false, vector.new(loc)
    end
end

-- Get orientation of turtle (if localMode, 
-- then use the turtle's stored direction)
function getOrientation(localMode)
    
    if not turtle then
        return nil
        -- Computers don't have an orientation
    end
    if not localMode then
        local loc1 = getLocation()
        -- Now we'll move the turtle

        local delta_y = 0
        local rotationCount = 0

        repeat
            repeat
                if turtle.forward() then
                    local loc2 = getLocation()
                    rotationCount = 4
                else 
                    turtle.turnRight()
                    rotationCount = rotationCount + 1
                end
            until rotationCount == 4
            if loc2 == nil then
                rotationCount = 0
                if not turtle.up() then
                    if turtle.digUp() then
                        turtle.up()
                    else
                        loc2 = loc1
                        -- We failed to move the turtle, so we give up and let
                        -- loc2 = loc1 so the function can terminate.
                    end
                end

                delta_y = delta_y + 1
            end
        until loc2 ~= nil

        -- Now move back down
        turtle.back()
        for i=1,delta_y,1 do
            turtle.down()
        end

        -- Now rotate back to original position
        for i=1,rotationCount,1 do
            turtle.turnLeft()
        end

        local disp = loc2 - loc1
        -- We don't care about the vertical component
        disp.y = 0

        return disp
    else 
        return local_orientation
    end
end

-- Initialize local_orientation vector
local_orientation = getOrientation(false)

-- Calculate the vector trajectory between destination from current location
function getTrajectory(dest)
    local err, loc = getLocation()
    if not err then
        return false, dest - loc
    else
        return true, vector.new(0,0,0)
        -- Don't send displacement if there is an error
    end
end

-- Rotate until turtle matches given orientation
function orientTurtle(direction, localMode)
    if localMode then
        repeat
            turtle.turnRight()
        until direction:dot(local_orientation) ~= 0
    else
        repeat
            turtle.turnRight()
        until direction:dot(getOrientation()) ~= 0
    end

    local_orientation = direction
end

-- Travel down trajectory vector
function traverseTrajectory(trajectory, breakBlocks)
    
    local dx = trajectory:dot(I)
    local dy = trajectory:dot(J)
    local dz = trajectory:dot(K)

    local sign_x = dx/math.abs(dx)
    local sign_y = dx/math.abs(dy)
    local sign_z = dx/math.abs(dz)
    
    -- Move in x first
    orientTurtle(I:mul(sign_x), true)
    for i = 1,math.abs(dx),1 do
        if not turtle.forward() then
            if breakBlocks then
                turtle.dig()
            end
        end
    end

    -- Move in z now
    orientTurtle(K:mul(sign_z), true)
    for i = 1,math.abs(dx),1 do
        if not turtle.forward() then
            if breakBlocks then
                turtle.dig()
            end
        end
    end

    -- Move in y
    if sign_y > 0 then
        for i = 1,math.abs(dy),1 do
            if not turtle.up() then
                if breakBlocks then
                    turtle.digUp()
                end
            end
        end
    elseif sign_y < 0 then
        for i = 1,math.abs(dy),1 do
            if not turtle.down() then
                if breakBlocks then
                    turtle.digDown()
                end
            end
        end
    end
end

-- Go to location (takes a 3 vector for destination). Tolerance is the
-- maximum distance from destination allowed
function goto(destination, tolerance, breakBlocks)
    local trajectory = nil
    repeat
        err, trajectory = getTrajectory(destination)
        
        if not err then
            traverseTrajectory(trajectory, breakBlocks)
        else
            print('Failed to get trajectory, aborting goto to '.. trajectory:tostring())
            break

    until trajectory:length < tolerance
end



    

