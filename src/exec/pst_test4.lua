local A = function()
    print('This is a test function')
end
local tab = {
    foo = A
}

if not _P.foo then
    print('Setting PSTVar')
    _P.foo = tab
    print('Set PSTVar')
    os.reboot()
end

pst.delete('foo')
print('Test complete!')
print('Resetting skynetrc to prevent recursion..')
local file = fs.open('/etc/skynetrc','w')
try {
    body = function ()
        file.writeLine('/exec/hello.lua')
        file.writeLine('/exec/pst_test_complete.lua')
        file.writeLine('/exec/emulator_close.lua')
    end,
    finally = function ()
        file.close()
        os.reboot()
    end
}
