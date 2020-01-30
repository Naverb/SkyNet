--[[

    ======================================================================
    ==================== SKYNET COMMUNICATION LIBRARY ====================
    ======================================================================

    Data is transmitted over the bundled cable interface.  Since we're transmitting directly to
    another turtle, we can transmit both directions simultaneously with the analog interface.

    The analog signal has three values encoded into it.
    0001
    Ready
    1000
    Clock signal
    0010
    File or Variable

    functions:
        |sendVar(side,inVar)
        Serializes the input data into a string, and then once it receives a ready
        signal from another turtle will send it two bytes at a time.

        |sendFile(side, path)
        Sends a file, along with its filename, to a receiving turtle.  Calls sendVar.

        |receiveVar(side, [optional] path)
        Receives and reconstructs serialized data received from a turtle using sendVar.

        |receiveFile(side [optional] path, [optional] name)
        Receives a file sent using sendFile.  By default, will save the file using the name received.
        If a name is provided, it will use that instead.
--]]

function sendVar(side, inVar, type)
    type = type or 0
    -- resets redstone output
    redstone.setBundledOutput(side,0)
    redstone.setAnalogOutput(side,0)

    local serString

    -- prepares data to be transmitted
    -- If it's just a variable, then it needs to be serialized.  If it's a file,
    -- the contents can be just sent as is
    if type == 0 then
        serString = textutils.serialize(inVar)
    else
        serString = inVar
    end

    local outData = {}
    local i = 1

	-- makes sure the string has an even length
	if (string.len(serString) % 2) == 1 then
	serString = serString .. "\0"
	end

    -- converts the string into an array of 16 bit values containing two 8 bit characters each
    while i <= string.len(serString) do
        outData[math.ceil(i/2)] = bit.bor(bit.blshift(string.byte(serString,i),8), string.byte(serString,i+1))
		i = i + 2
    end

    -- print("Waiting...")
    -- sends a ready signal to a receiving turtle
    redstone.setAnalogOutput(side, bit.bor(type, 1))
    redstone.setBundledOutput(side,outData[1])

    -- waits to receive a ready signal
    while redstone.getAnalogInput(side) == 0 do
    os.sleep(0.05)
    end

    -- toggles redstone power level to wake the receiving turtle
    redstone.setAnalogOutput(side,bit.bxor(redstone.getAnalogOutput(side), 7))

    -- transmits the data over the bundled cable output
    for i = 1,#outData do
        redstone.setBundledOutput(side,outData[i])
        redstone.setAnalogOutput(side,bit.bxor(redstone.getAnalogOutput(side), 7))
	    os.sleep(0.1)
    end

    -- resets redstone output
    redstone.setAnalogOutput(side,0)
    redstone.setBundledOutput(side,0)
    -- print("Sent!")
end

function sendFile(side, path)
    local file = fs.open(path, "r")
    local fileName = fs.getName(path)
    -- transmits file name
    sendVar(side, fileName)
    os.sleep(0.1)
    -- transmits file contents
    sendVar(side, file.readAll(), 2)
end

function receive(side, path)
    path = path or "default"

    -- resets redstone output
    redstone.setAnalogOutput(side, 0)

    local inData = {}
	local i = 1

    -- waits for ready signal from sending turtle
    -- print("Waiting...")
    while(redstone.getAnalogInput(side) == 0) do
        os.sleep(0.05)
    end

    local varOrFile = bit.band(redstone.getAnalogInput(side),2)

    -- notifies sending turtle that is ready for communication
	-- print("Receiving...")
    redstone.setAnalogOutput(side,1)

    -- saves incoming binary data to a table
    while redstone.getAnalogInput(side) ~= 0 do
        inData[i] = redstone.getBundledInput(side)
		i = i+1
		os.pullEvent("redstone")
    end

    -- resets redstone out
    redstone.setAnalogOutput(side,0)

    -- print("Received!")
    -- converts binary back into characters
    rawData = ""
    for i = 1, #inData do
        rawData = rawData .. string.char(bit.blogic_rshift(inData[i],8),bit.band(inData[i],255))
    end

    --returns the unserialized information
    if varOrFile == 0 then
        return textutils.unserialize(rawData)
    else
        local outFile = fs.open(path, "w")
        outFile.write(rawData)
        outFile.flush()
        return outFile
    end
end

function receiveFile(side,path,name)
    name = name or ""
    path = path or ""

    if name == "" then
        name = receive(side)
    else
        -- throwaway to clear out fileName being sent
        local flush = receive(side)
    end

    if path ~="" then
        inFile = receive(side, fs.combine(path, name))
    else
        inFile = receive(side, name)
    end

    return inFile
end
