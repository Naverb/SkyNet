local filesToExec = {
    -- Put files to execute in this array.
    '/MWP/sys/hello.lua',
    '/MWP/tests/path_test.lua'
}

for _,filepath in ipairs(filesToExec) do
    print('> Executing ' .. tostring(filepath))
    local exec = loadfile(filepath)
    setfenv(exec, getfenv())
    local ok, result = pcall(exec)
    if not ok then
        print(filepath .. ' failed to load properly.')
        error(result)
    end
end
