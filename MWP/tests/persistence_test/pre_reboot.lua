local COMMAND_LINE_ARGS = {...}

print('Beginning persistence test.')
print('Setting persistent variable "test".')
pst.set('test','a')
print('Setting phase 2 of test to run at startup.')
nym.removeFromFile('/MWP/sys/skynetrc','/MWP/tests/persistence_test/pre_reboot.lua')
nym.appendToFile('/MWP/sys/skynetrc','/MWP/tests/persistence_test/post_reboot.lua')
print('Rebooting in 5s...')
sleep(5)
os.reboot()
