
function log(text)
		-- settings
	local logFile = fs.open("log", fs.exists("log") and "a" or "w")
	logFile.writeLine(text)

end
