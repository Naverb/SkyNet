os.loadAPI("SkyNet/MWP/lib/quarry_api")

gps2.orientChunk()

for i=1,8 do   
    quarry_api.quarryLine()
    turtle.turnRight()
    turtle.dig()
    turtle.forward()
    turtle.turnRight()
    quarry_api.quarryLine()
    turtle.turnLeft()
    turtle.dig()
    turtle.forward()
    turtle.turnLeft()
end
