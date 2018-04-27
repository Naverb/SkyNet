rednet.open("right")
redstone.setOutput("left", true)

while true do
    id, message = rednet.receive() -- wait until something is received over rednet
    if (message == "reloadGit") then
        redstone.setOutput("left", false)
        fs.delete('SkyNet')
        shell.run("github","clone","Naverb/SkyNet","SkyNet")
        redstone.setOutput("left", true)
    end
end