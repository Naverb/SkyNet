redstone.setOutput("left", true)
while true do
event, param = os.pullEvent()
   if event == "redstone" and redstone.getInput("front") == true then
   redstone.setOutput("left", false)
   sleep(3)
   redstone.setOutput("left", true)
   end
end