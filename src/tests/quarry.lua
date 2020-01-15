os.loadAPI("SkyNet/MWP/lib/quarry_api")

local height = gps2.orientChunk()

for i=1,8 do   
    quarry_api.quarryLine(height)
    turtle.turnRight()
    turtle.dig()
    turtle.forward()
    turtle.turnRight()
    quarry_api.quarryLine(height)
    turtle.turnLeft()
    turtle.dig()
    turtle.forward()
    turtle.turnLeft()
end
