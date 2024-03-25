# ChunkGen

Inspired by [ChunkWorx](https://github.com/cuberite/chunkworx) this plugin allows the user to easily (re)generate chunks from the webadmin. ChunkWorx still works, but it's been 10 years since anyone has looked at the code. There are lots of magic numbers, and the interface loses it's state everytime there is a reload. For this reason I made this plugin. Not just to try make a more user friendly replacement, but also to see how viable Ajax calls are when used inside Cuberite.

Some advantages over ChunkWorx:

- Async interface
- Allow any radius around a player instead of just the exact chunk or 3x3
- Statistics about the generator, lighting en storage queues.
- The to be generated chunks can spiral around a set of coordinates or a player which allows you to see the new chunks immediately instead of waiting for the updates to finally catch up to you.


