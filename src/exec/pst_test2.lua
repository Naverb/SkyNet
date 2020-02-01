if not _P.new_var then
    print('Testing writing to persistence..')
    _P.new_var = {
        test = {
            foo = 'bar'
        }
    }
    print('Rebooting now')
    os.reboot()
elseif _P.new_var.test.foo == 'bar' then
    print('Found test persistent variable.')
    print('Test val: ' .. _P.new_var.test.foo)
    print('Changing test variable..')
    _P.new_var.test.foo = 'bar_prime'
    print('Rebooting now')
    os.reboot()
else
    print('Test val: ' .. _P.new_var.test.foo)
    print('Deleting test variable now..')
    pst.delete('new_var')
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
