rednet.open("right")
redstone.setOutput("left", true)

while true do
    id, message = rednet.receive() -- wait until something is received over rednet
    if (message == "reloadGit") then
        redstone.setOutput("left", false)
        sleep(2)
        redstone.setOutput("left", true)
    end
end