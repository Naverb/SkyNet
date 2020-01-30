--- Searches the /etc folder for a particular package.
--- If you need to search subdirectories, separate levels with a `.`, e.g. `foo.bar` searches for `/etc/foo/bar.cfg`
--- Returns a table of everything in the config file.
---@param package_name string
---@return table
function loadConfiguration(package_name)
    -- Identify the subdirectories, if any.
    local dirs = nym.algo.splitString(package_name,'.')
    local config_file = '/etc'
    for _, dir in ipairs(dirs) do
        config_file = fs.combine(config_file,dir)
    end
    config_file = config_file .. '.cfg'

    local config_data = {}
    if fs.exists(config_file) and not fs.isDir(config_file) then
        local file = fs.open(config_file,'r')
        local raw_data = try {
            body = function ()
                return file.readAll()
            end,
            finally = function ()
                file.close()
            end
        }
        config_data = textutils.unserialize(raw_data)
    else
        local ex = Exception:new('Failed to find config file for ' .. package_name,'FileNotFoundException')
        ex:throw()
    end

    return config_data
end
