Inspired by [ChunkWorx](https://github.com/cuberite/chunkworx) this plugin allows the user to easily (re)generate chunks from the webadmin. ChunkWorx still works, but it's been 10 years since anyone has looked at the code. There are lots of magic numbers which makes maintaining the code harder. The interface also loses it's state everytime there is a reload which makes development on the world generator more frustrating. This plugin tries to solve all these issues and add some more functionality to make world generator development easier.

Some advantages over ChunkWorx: 
 
 - Interface state isn't lost when Cuberite reloads. 
 - Allow any radius around a player instead of just the exact chunk or 3x3. 
 - Shows statistics about the generator, lighting and storage queues. 
 - The to be generated chunks can spiral around a set of coordinates or a player which allows you to see the new chunks immediately instead of waiting for the updates to finally catch up to you.

# Commands

### General
| Command | Permission | Description |
| ------- | ---------- | ----------- |
|/reg | chunkgen.reg | Regenerates chunks around the player or cancel the previous task.|



# Permissions
| Permissions | Description | Commands | Recommended groups |
| ----------- | ----------- | -------- | ------------------ |
| chunkgen.reg |  | `/reg` |  |
