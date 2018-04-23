turtle.refuel()
local success, data = turtle.inspect()
if success then
    print("Block name: ", data.name)
    print("Block metadata: ", data.metadata)
end