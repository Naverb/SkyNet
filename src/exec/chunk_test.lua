if not _P.movement then
    _P.movement = {
        i = 0
    }
end

while _P.movement.i < 20 do
    turtle.up()
    _P.movement.i = _P.movement.i + 1
end
