while true do
    senderId, message, protocol = rednet.receive("reloadGit")
    print(message)
end