-- Load init.cfg
local config_file = fs.open('/init/init.cfg','r')
local raw_config_data = config_file.readAll()
CONFIG = textutils.unserialize(raw_config_data)
config_file.close()

-- Load logging API
local log_loader, err = loadfile('/init/log.lua')
if err then
    error(err)
else
    log = log_loader(CONFIG)
    log.initialize()
end
LINE_PREFIX = 'INIT> '

-- Load exception API
local ex_loader, err = loadfile('/init/exception.lua')
if err then
    error(err)
else
    Exception = ex_loader(CONFIG)
end

-- Load nym
local nym_modules = fs.find('/init/nym/*')
nym = {}
for _,nym_module in ipairs(nym_modules) do
    module_loader, err = loadfile(nym_module)
    local loader_env = {}
    setmetatable(loader_env,{__index = getfenv()})
    setfenv(module_loader,loader_env)
    if err then error(err) else
        module_loader()

        local name = fs.getName(nym_module)
        name = string.sub(name,1,-5) -- Remove .lua from name

        nym[name] = loader_env
    end
end

print('Init complete! Proceeding to post-init.')
-- Proceed to post-init
LINE_PREFIX = 'SKYNET> '
os.run(getfenv(),CONFIG.POST_INIT)
