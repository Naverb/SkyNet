local LOG_DIR = '/MWP/sys/log'
local CURRENT_LOG_DIR = fs.combine(LOG_DIR,'recent.log')
local current_log_number = 0
local logfiles = { MAIN = 'recent.log'}
function initialize()
	-- Create a new log file, renaming the last one.
	-- We first rename the previous log file:
	if fs.exists(CURRENT_LOG_DIR) then
		local last_log = fs.open(CURRENT_LOG_DIR,'r')
		local header = last_log.readLine()
		last_log.close()
		current_log_number = string.match(header,'%d+') + 1
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
end

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

function printToLog(msg,logfile)
	logfile = logfile or 'MAIN'
	-- Writes the string msg to the specified logfile
	local logpath = fs.combine(LOG_DIR,logfiles[logfile])
	local file = fs.open(logpath,'a')
	file.writeLine(msg)
	file.close()
end

-- We have this here just in case we load this API before module.
return {
	initialize = initialize,
	createLogFile = createLogFile,
	print = printToLog
}
