local filesToExec = {
    -- Put files to execute in this array.
    '/MWP/sys/hello.lua'
}

for _,filepath in ipairs(filesToExec) do
    print('Executing ' .. tostring(filepath))
    local exec = loadfile(filepath)
    local result = pcall(exec)
    print('Finished executing ' .. filepath .. '. System returned ' .. tostring(result) .. '.')
end
