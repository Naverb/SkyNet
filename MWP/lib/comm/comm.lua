--[[

    ======================================================================
    ==================== SKYNET COMMUNICATION LIBRARY ====================
    ======================================================================

    functions:
        sendVar(side,inVar)
        Serializes the input data into a string, and then once it receives a ready
        signal from another turtle will send it two bytes at a time.

        receive(side)
        Receives and reconstructs serialized data received from a turtle using sendVar.
--]]

function sendVar(side, inVar)
    -- resets redstone output
    redstone.setBundledOutput(side,0)
    redstone.setAnalogOutput(side,0)

    -- prepares data to be transmitted
    local serString = textutils.serialize(inVar)
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

    print("Waiting...")
    -- sends a ready signal to a receiving turtle
    redstone.setAnalogOutput(side, 1)
    redstone.setBundledOutput(side,outData[1])
    
    -- waits to receive a ready signal
    while redstone.getAnalogInput(side) == 0 do
    os.sleep(0)
    end

    -- toggles redstone power level to wake the receiving turtle
    redstone.setAnalogOutput(side,bit.bxor(redstone.getAnalogOutput(side), 7))

    for i = 1,#outData do
        redstone.setBundledOutput(side,outData[i])
        redstone.setAnalogOutput(side,bit.bxor(redstone.getAnalogOutput(side), 7))
	    os.sleep(0.1)
    end

    -- resets redstone output
    redstone.setAnalogOutput(side,0)
    redstone.setBundledOutput(side,0)
    print("Sent!")
end

function receiveVar(side)
    -- resets redstone output
    redstone.setAnalogOutput(side, 0)

    local inData = {}
	local i = 1

    -- waits for ready signal from sending turtle
    print("Waiting...")
    while(redstone.getAnalogInput(side) == 0) do
        os.sleep(0.05)
    end
    
    -- notifies sending turtle that is ready for communication
	print("Receiving")
    redstone.setAnalogOutput(side,1)

    -- saves incoming binary data to a table
    while redstone.getAnalogInput(side) ~= 0 do
        inData[i] = redstone.getBundledInput(side)
		i = i+1
		os.pullEvent("redstone")
    end
    print("Received")
    
    -- converts binary data back into characters
    rawData = ""
    for i = 1, #inData do
        print(inData[i])
        rawData = rawData .. string.char(bit.blogic_rshift(inData[i],8),bit.band(inData[i],255))
	end
    
    --returns the unserialized information
    return textutils.unserialize(rawData)
end
