turtle.refuel()
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