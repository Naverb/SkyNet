## Init directory
This folder contains the libraries necessary to start the skynet system:

- Error management
- Basic lua modifications
- Logging
- start.lua

In order to be admissible into init, all files should not require ANY external libraries (except ComputerCraft libraries) with the sole exception being:

** `init.cfg` is the proper place to store constants, and its contents will be stored in the global variable CONFIG **

All init libraries will be available to any file executed by skynet.
