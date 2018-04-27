while true do
    if redstone.getInput("front") then
        rednet.send(2,'reloadGit','reloadGit')
    end
end