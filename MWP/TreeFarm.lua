local direction = 0
local width = 18
local height = 18
local counter = 0
local area = width * height 
for i = 1, 16 do
    turtle.select(i)
    local fuel = turtle.getItemDetail()
    if fuel then
        if (fuel.name == "minecraft:charcoal" or fuel.name == "minecraft:coal") then
            turtle.refuel()
        end
    end
end
while true do
    turtle.suck()
    local success, data = turtle.inspectUp()
    if success then
        if (data.name == "minecraft:furnace") then
            turtle.suckUp() -- pull out produced charcoal
            turtle.select(1)
            local item = turtle.getItemDetail()
            if item then
                if (item.name == "minecraft:coal") then
                    turtle.dropUp(8) -- all that is needed
                end
            end
            turtle.back()
            turtle.up()
            turtle.up()
            turtle.forward()
            turtle.select(3)
            local item = turtle.getItemDetail()
            if item then
                if (item.name == "minecraft:log") then
                    turtle.dropDown(63) -- leave one to reserve slot
                end
            end
            turtle.back()
            turtle.down()
            turtle.down()
            turtle.turnRight()
            turtle.turnRight()
            direction = 0
        end
    end
    local success, data = turtle.inspect()
    if (not success) then
        turtle.forward()
    elseif (data.name == "minecraft:log") then
        turtle.dig()
        turle.forward()
        turtle.digUp()
        turtle.up()
        turtle.select(2)
        turtle.placeDown()
        while(turtle.detectUp()) do
            turtle.digUp()
            turtle.up()
        end
        while(not turtle.detectDown()) do
            turtle.down()
        end
        turtle.forward()
        turtle.down()
    elseif (data.name == "minecraft:sapling") then
        turtle.up() -- Please DO NOT put saplings on edge of farm
        turtle.forward()
        turtle.forward()
        turtle.down()
    elseif (data.name == "minecraft:chest") then
        for i = 4, 16 do
            turtle.select(i)
            turtle.drop()
        end
    elseif (direction == 0) then
        turtle.turnRight()
        if (not turtle.detect()) then
            direction = 1
        end
        turtle.forward()
        turtle.turnRight()
    elseif (direction == 1) then
        turtle.turnLeft()
        if (not turtle.detect()) then
            direction = 0
        end
        turtle.forward()
        turtle.turnLeft()
    end
    
end