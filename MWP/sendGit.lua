rednet.open("right")
redstone.setOutput("left", true)

while true do
event, param = os.pullEvent()
    if event == "redstone" and redstone.getInput("front") == true then
        rednet.broadcast("reloadGit")
        redstone.setOutput("left", false)
        sleep(2)
        redstone.setOutput("left", true)
    end
end
