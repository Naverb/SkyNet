for i = 1, 16 do
    turtle.select(i)
    local fuel = turtle.getItemDetail()
    if fuel then
        if (fuel.name ~= "minecraft:sapling") then
            turtle.refuel()
        end
    end
end
while true do
    turtle.suck()
    local success, data = turtle.inspect()
    if (not success) then
        turtle.forward()
    elseif (data.name == "minecraft:log") then
        turtle.dig()
        turtle.forward()
        while(turtle.detectUp()) do
            turtle.digUp()
            turtle.up()
        end
        while(not turtle.detectDown()) do
            turtle.down()
        end
    elseif (direction == 0) then
        turtle.turnRight()
        turtle.forward()
        turtle.turnRight()
        direction = 1
    elseif (direction == 1) then
        turtle.turnLeft()
        turtle.forward()
        turtle.turnLeft()
        direction = 0
    end
end