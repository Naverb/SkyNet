 4-22-2018; Brevan
 -
I have spent the last few hours pondering chunk loading techniques, both those for 1.8.9 and for later versions. We can effectively break down the loaders into two categories: connected and disconnected. Connected chunk loaders work by daisy chaining chunk loaders out from spawn chunks, and thus form continuous chains. In contrast, disconnected chunk loaders can be remote. I will evaluate a few chunk loaders I have found here, with pros and cons.

**Connected**
-  <u>Simply Sarc's Hopper Loader
	- https://www.youtube.com/watch?v=egqsmXD_oCM
	- Pros
		- No timeout
		- Reload friendly
	- Cons
		- Resource intensive (iron)
		- Lazy chunks
		- Requires hopper to face *into* chunk

**Disconnected**
- <u>Mobbin's Arrow Loader
	- https://www.youtube.com/watch?v=atBzZ7Qg1hA
	- Pros
		- No timeout
		- Works on reloads?
		- Extremely cheap
		- Active chunk
	- Cons
		- No obvious way to unload chunks
		- Requires loading $\langle0,0,0\rangle$
		- Not guaranteed to work after 1.8.9
		- Only loads a single chunk
		$\phantom{ }$
- <u>Gnembon Breaks Minecraft
	- https://www.youtube.com/watch?v=aeq5GZxRH9s
	- Pros
		- No timeout
		- Works on reloads
		- Never unloads (single tick every 45 seconds)
		- FRACTALS and XOR ARITHMETIC
	- Cons
		- Not obvious how to use this in modular form
		- Players can accidentally unload chunks
		- Seemingly reliant on diagonal
		- So complicated I don't fully understand it yet
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTExOTk4NTc0NzFdfQ==
-->