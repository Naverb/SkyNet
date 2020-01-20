TREE_LOG_ID = 'minecraft:birch_log'
SAPLING_ID = 'minecraft:birch_sapling'
FARM_LENGTH = 17
FARM_WIDTH = 17
SAPLING_SLOT = 1
FUEL_THRESHOLD = 4 * FARM_LENGTH * FARM_WIDTH
REFUEL_RATIO = 4
CHARCOAL_FUEL_DENSITY= 80
WOOD_FURNACE_DENSITY = 1.5
CHARCOAL_REFUEL_RATIO = 4/7
CHARCOAL_FURNACE_DENSITY = 8

local I = vector:new(1,0,0)
local J = vector:new(0,1,0)
local K = vector:new(0,0,1)

local FARM_CORNER_START = pst.get('FARM_CORNER') or vector:new(0,0,0)
local FARM_CORNER_FINISH = FARM_CORNER_START + I:mul(FARM_LENGTH) + K:mul(FARM_WIDTH)


local pos = pst.get('pos') or FARM_CORNER_START
local orientation = pst.get('orientation')

--[[

local function getInstruction()
    local instruction = pst.get('instruction')
    local args = textutils.unserialize(pst.get('args'))

    return instruction,args
end

local function setInstruction(instruction,args)
    pst.set('instruction',instruction)
    pst.set('args',textutils.serialize(args))
end
]]

function forward()
    local ok = turtle.forward()
    if ok then
        local new_pos = pos + orientation
        pst.set('pos',new_pos)
        pos = new_pos
    end
    turtle.suck()
    return ok
end

function back()
    local ok = turtle.back()
    if ok then
        local new_pos = pos + orientation
        pst.set('pos',new_pos)
        pos = new_pos
    end
    turtle.suck()
    return ok
end

function up()
    local ok = turtle.up()
    if ok then
        local new_pos = pos + J
        pst.set('pos',new_pos)
        pos = new_pos
    end
    turtle.suckUp()
    turtle.suckDown()
    return ok
end

function down()
    local ok = turtle.down()
    if ok then
        local new_pos = pos - J
        pst.set('pos',new_pos)
        pos = new_pos
    end
    turtle.suckUp()
    turtle.suckDown()
    return ok
end

function turnRight()
    local ok = turtle.turnRight()
    if ok then
        -- Rotate orientation Pi/2 radians in xz plane.
        local new_orientation = vector:new(-1 * orientation.z,0,orientation.x)
        pst.set('orientation',new_orientation)
        orientation = new_orientation
    end

    turtle.suck()
    return ok
end

function turnLeft()
    local ok = turtle.turnLeft()
    if ok then
        -- Rotate orientation -Pi/2 radians in xz plane.
        local new_orientation = vector:new(orientation.z,0,-1 * orientation.x)
        pst.set('orientation',new_orientation)
        orientation = new_orientation
    end

    turtle.suck()
    return ok
end

function checkBoundary()
    local boundary_x = pos.x <= FARM_CORNER_START.x or pos.x >= FARM_CORNER_FINISH.x
    local boundary_z = pos.z <= FARM_CORNER_START.z or pos.z >= FARM_CORNER_FINISH.z

    return boundary_x or boundary_z
end

function placeSapling()
    local success = false
    if turtle.getItemCount(SAPLING_SLOT) > 1 then
        -- We have enough saplings to place a new sapling down.
        turtle.select(SAPLING_SLOT)
        success = turtle.placeDown()
    end

    return success
end

function moveAndCheckFuel(movecommand)
    local ok = movecommand()

    if not ok then
        if turtle.getFuelLevel() <= 0 then
            repeat
                print('Out of fuel. Place fuel in inventory and press [r].')
                repeat
                    local event, key = os.pullEvent("key")
                until key = keys.r
                for i=2,16 do
                    turtle.select(i)
                    turtle.refuel()
                end
            until turtle.getFuelLevel() > 0
        end
    end

    return ok
end

function mineTree()
    -- If standing under tree, mine to top.
    turtle.dig()
    moveAndCheckFuel(forward)

    local original_pos = pos
    while turtle.inspectUp()['name'] == TREE_LOG_ID do
        turtle.digUp()
        moveAndCheckFuel(up)
    end
    repeat
        moveAndCheckFuel(down)
    until pos == original_pos + J

    -- Place sapling
    placeSapling()

    -- move back to ground
    moveAndCheckFuel(forward)
    moveAndCheckFuel(down)
end

function turnCorner()
    if (pos == FARM_CORNER_START) or (pos == FARM_CORNER_FINISH) then
        turnRight()
    end
    turnRight()
end

function dodgeSapling()
    moveAndCheckFuel(up)
    moveAndCheckFuel(forward)
    moveAndCheckFuel(forward)
    moveAndCheckFuel(down)
end

function offloadChest()
    for i = 2,16 do
        turtle.select(i)
        turtle.drop()
    end
end

--[[
local function offloadChest()

    -- goto droppoff, drop off everything
    up()
    up()
    for i = 2,16 do -- first spot is reserved for saplings, which the turtle can hold on to
        turtle.select(i)
        turtle.drop()
    end

    -- go to pickup
    down()
    down()



    local desired_charcoal_count = (REFUEL_RATIO * FUEL_THRESHOLD - turtle.getFuelLevel()) / CHARCOAL_FUEL_DENSITY

    -- [pickup] <- [dropoff] <- [furnace]
    -- 1) goto dropoff, dropoff everything
    -- 2) goto pickup, grab the first slot of charcoal (+ amount to refuel), and first slot of wood
    -- 3) refuel (potentially with surplus we grabbed for this)
            --> Refuel before smelting!
    -- 4) goto furnace, drop off charcoal and wood we grabbed
    -- 5) goto dropoff chest, drop off everything
    -- 6) go on our merry way
end
]]

function proceed()
    -- Determine the next action of the turtle.

    if checkBoundary() then
        turnCorner()
    end

    if not moveAndCheckFuel(forward) then

        -- Identify block in front
        local block = turtle.inspect()

        if block.name == SAPLING_ID then
            dodgeSapling()
        elseif block.name == TREE_LOG_ID then
            mineTree()
        elseif block.name == 'minecraft:chest' then
            offloadChest()
        end

        -- Place sapling if dirt is below
        local block_below = turtle.inspectDown()
        if block_below.name == 'minecraft:dirt' then
            placeSapling()
        end

        --[[
        local block_above = turtle.inspectUp()

        if block_above.name == 'minecraft:furnace' then
            local reserved_wood_count

            if turtle.getFuelLevel() < FUEL_THRESHOLD then
                reserved_wood_count = math.ceil(REFUEL_RATIO * WOOD_FUEL_RATIO * FUEL_THRESHOLD)
            else
                reserved_wood_count = 0
            end

            -- acquireCharcoal(reserved_wood_count)
        end
        ]]
    end
end

while true do
    proceed()
end


--[[
local success, data = turtle.inspect()
if (not success) then
    turtle.suck() -- OPTIMIZE THIS - perhaps with water?
    turtle.forward()
elseif (data.name == "minecraft:log") then
    cutTree()
elseif (data.name == "minecraft:sapling") then
    evadeSaplings()
elseif (data.name == "minecraft:chest") then
    offloadChest()
else
    cornerCheck()
end

function sortSlots()
    for i = 4, 16 do
        turtle.select(i)
        for j = 1, 3 do
            if turtle.compareTo(j) then
                turtle.transferTo(j)
            end
        end
    end
end

function totalRefuel()
    for i = 1, 16 do
        turtle.select(i)
        local fuel = turtle.getItemDetail()
        if fuel then
            if (fuel.name == "minecraft:coal") then
                turtle.select(1)
                turtle.refuel(turtle.getItemCount(1)-1) -- leave something in slot
            end
        end
    end
end
]]

--[[
        for i = 2,16 do -- first spot is reserved for saplings, which the turtle can hold on to
        local item = turtle.getItemDetail(i)
        if item.name == TREE_LOG_ID then
                turtle.select(i)
                turtle.drop()
            end
        elseif item.name == 'minecraft:charcoal' then
            -- Charcoal is useful for refuelling
            break
        else
            turtle.select(i)
            turtle.drop()
        end
    end
]]
