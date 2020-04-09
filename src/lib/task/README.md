# Skynet Multitasking
*There have been many iterations of this library. Let's get it right this time*

There are two fundamental components of the multitasking library:

- Context

- Tasks

Context is the information necessary to multitask. This includes information on
the state of the turtle (position, fuel level, inventory, etc.) which is
*volatile*: that which gets modified by a process which yields the turtle. Since
chunk-unloading yields turtles and suspends them, volatile data is highly
related to persistent data. In fact, most of the context is a persistent
variable because multitasking must be capable of resuming after a system
shutdown or forced yield.

Tasks are the dynamic framework to interact with the world - changing the
context along the way.
