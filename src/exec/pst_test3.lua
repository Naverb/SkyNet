if not _P.new_var and not _P.foo then
    print('Writing {} to new_var in _P.')
    _P.new_var = {}
    print('Rebooting..')
    os.reboot()
elseif _P.new_var and not _P.new_var.entry then
    print('Found empty table')
    _P.new_var.entry = 'foo'
    print('Rebooting..')
    os.reboot()
elseif _P.new_var and _P.new_var.entry == 'foo' then
    print('Found entry')
    local entry = _P.new_var.entry
    _P[entry] = {
        data = 'bar'
    }
    pst.delete('new_var')
    print('Rebooting..')
    os.reboot()
else
    print('Found foo')
    print(textutils.serialize(_P.foo.data))
    pst.delete('foo')
end

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
