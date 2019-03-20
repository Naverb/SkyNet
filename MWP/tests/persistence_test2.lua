local persistence_test_var = pst.get('test')

if persistence_test_var == "a" then
    print('Discovered test var')
    pst.delete('test')
else
    print('Failed to find test var; writing it to the persistence filesystem.')
    pst.set('test','a')
    print('Rebooting in 3s...')
    sleep(3)
    os.reboot()
end
