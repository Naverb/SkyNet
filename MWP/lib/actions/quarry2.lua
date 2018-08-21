-- APIS
    os.loadAPI("SkyNet/MWP/lib/move")

-- FIXME: Coroutines for turtle digging?

local function digDownUp(height)

    print(height)

    for i=1, height do
        turtle.digDown()
        move.down()
    end
    for i=1, height do
        turtle.digUp()
        move.up()
    end
end

local function quarryLine(height, sideWidth)
    local width = sideWidth or 7

    print(width)
    print(height)

    for i=1,width do
        digDownUp(height)
        turtle.dig()
        move.forward()
    end
    digDownUp()
end

function makeQuarry(height, sideLength, sideWidth)
    local length = sideLength or 7
    local width = sideWidth or 7

    print(length)
    print(width)
    print(height)

    for i=1,length do
        quarryLine(height, width)
        turtle.turnRight()
        turtle.dig()
        move.forward()
        turtle.turnRight()
        quarryLine(height, width)
        turtle.turnLeft()
        turtle.dig()
        move.forward()
        turtle.turnLeft()
    end
end