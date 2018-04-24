local direction = 0
local width = 18
local height = 18
local counter = 0
local area = width * height 

function cornerCheck()
    if (direction == 0) then
        turtle.turnRight()
        if (not turtle.detect()) then
            direction = 1
        end
        turtle.forward()
        turtle.turnRight()
    else
        turtle.turnLeft()
        if (not turtle.detect()) then
            direction = 0
        end
        turtle.forward()
        turtle.turnLeft()
    end
end

for i = 1, 16 do
    turtle.select(i)
    local fuel = turtle.getItemDetail()
    if fuel then
        if (fuel.name == "minecraft:charcoal" or fuel.name == "minecraft:coal") then
            turtle.select(1)
            turtle.refuel(turtle.getItemCount(1)-9) -- leave something in slot
        end
    end
end
while true do
    print(turtle.getFuelLevel())
    local success, data = turtle.inspectUp()
    if success then
        if (data.name == "minecraft:furnace" or data.name == "minecraft:lit_furnace") then
            print("furnace detected!")
            turtle.select(1)
            turtle.suckUp() -- pull out produced charcoal
            local item = turtle.getItemDetail()
            if item then
                if (item.name == "minecraft:charcoal" or item.name == "minecraft:coal") then
                    if (turtle.getItemCount(1) > 8) then
                        turtle.dropUp(8) -- all that is needed
                    end
                end
            end
            turtle.refuel(turtle.getItemCount(1)/3)
            print("back it on up")
            turtle.back()
            turtle.up()
            turtle.up()
            turtle.forward()
            turtle.select(3)
            local item = turtle.getItemDetail()
            if item then
                if (item.name == "minecraft:log") then
                    turtle.dropDown(turtle.getItemCount(3)-1) -- leave one to reserve slot
                end
            end
            turtle.back()
            turtle.down()
            turtle.down()
            turtle.forward()
            turtle.forward()
        end
    end
    local success, data = turtle.inspect()
    if (not success) then
        turtle.suck()
        turtle.forward()
    elseif (data.name == "minecraft:log") then
        turtle.dig()
        turtle.forward()
        turtle.digUp()
        turtle.up()
        turtle.select(2)
        local item = turtle.getItemDetail()
        if item then
            if (item.name == "minecraft:sapling" and turtle.getItemCount(2) > 1) then
                turtle.placeDown()
            end
        end
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
        print("somehow reached a chest still")
        for i = 4, 16 do
            turtle.select(i)
            turtle.drop()
        end
        cornerCheck()
    else
        cornerCheck()
    end
end