local COMMAND_LINE_ARGS = {...}

print('Beginning persistence test part 2.')
print('>> Reading persistent variable "test".')
local testvar = pst.get('test')

if testvar == 'a' then
    if testvar == "a" then
        print('>> Discovered test variable.')
        print('>> Persistence test completed sucessfully!')
        print('>> Deleting test variable from persistent filesystem.')
        pst.delete('test')
    else
        print('>> Failed to find test variable.')
    end
    print('>> Removing phase 2 of test from startup.')
    nym.removeFromFile('/MWP/sys/skynetrc','/MWP/tests/persistence_test/post_reboot.lua')
end
