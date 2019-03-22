local LOG_DIR = '/MWP/sys/log'
local CURRENT_LOG_DIR = fs.combine(LOG_DIR,'recent.log')
local current_log_number = 0
local logfiles = { MAIN = 'recent.log'}

function createLogFile(name,path)
	-- Create a new log file with the given name and path (relative to LOG_DIR)
	local realpath = fs.combine(LOG_DIR,path)

	local enclosing_dir = fs.getDir(realpath)
	if not fs.exists(enclosing_dir) then
		fs.makeDir(enclosing_dir)
	end

	local file = fs.open(realpath,'a')
	file.writeLine('=== ' .. tostring(name) .. ' LOG FILE: ' .. tostring(current_log_number) .. ' ===')
	file.close()
	logfiles[name] = path
end
function writeToLog(msg,logfile)
	logfile = logfile or 'MAIN'
	-- Writes the string msg to the specified logfile
	local logpath = fs.combine(LOG_DIR,logfiles[logfile])
	local file = fs.open(logpath,'a')
	file.write(msg)
	file.close()
end
function printToLog(msg,logfile)
	writeToLog(msg .. '\n',logfile)
end
function initialize()
	-- Create a new log file, renaming the last one.
	-- We first rename the previous log file:
	if fs.exists(CURRENT_LOG_DIR) then
		local last_log = fs.open(CURRENT_LOG_DIR,'r')
		local header = last_log.readLine()
		last_log.close()
		current_log_number = (string.match(header,'%d+') or 0) + 1 -- Just in case the header is missing, start back at 0.
		-- We rename the log file here:
		print('Current log number: ' .. current_log_number)
		fs.move(CURRENT_LOG_DIR,fs.combine(LOG_DIR,'log_' .. tostring(current_log_number - 1)) )
	else
		-- There is no most-recent log file. We can just create one.
		current_log_number = current_log_number + 1
		print('Current log number: ' .. current_log_number)
	end

	-- We now create the new log file
	local logfile = fs.open(CURRENT_LOG_DIR,'w')
	logfile.writeLine('=== SKYNET LOG FILE: ' .. tostring(current_log_number) .. ' ===')
	logfile.close()

	-- We now overwrite the print function to incorporate logging:
	-- We do this in initialize because we want to make sure we have a logfile before we start using it.

	local lua_write = write
	write = function(str,line_prefix) -- In theory, line_prefix allows us to uppend information at each line. This would be handy to print what program we are currently running. Work in progress.
		line_prefix = line_prefix or ''
		local serialized_str
		-- Very basic serialization code:
		if type(str) == 'table' then
			local ok, serialized_str = pcall(textutils.serialize,str)
			if not ok then
				serialized_str = tostring(str)
			elseif serialized_str == "" or serialized_str == '{}' then
				serialized_str = "[EMPTY_TABLE]"
			end
		else
			serialized_str = tostring(str)
		end

		writeToLog(line_prefix .. serialized_str)
		return lua_write(line_prefix .. str)
	end
	print = function(...)
		-- We steal part of the built-in print function to format properly:

		-- We also overwrite the original write function in this scope to write to the log file:

		local nLinesPrinted = 0
		local nLimit = select("#", ... )
		for n = 1, nLimit do
			local s = tostring( select( n, ... ) )
			if n < nLimit then
				s = s .. "\t"
			end
			nLinesPrinted = nLinesPrinted + write( s )
		end
		nLinesPrinted = nLinesPrinted + write( "\n" )
		return nLinesPrinted
	end
end

-- We have this here just in case we load this API before module.
return {
	initialize = initialize,
	createLogFile = createLogFile,
	print = printToLog,
	write = writeToLog
}
