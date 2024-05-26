
-- Info.lua

-- Implements the g_PluginInfo standard plugin description

g_PluginInfo =
{
	Name = "ChunkGen",
	Version = 1,
	DisplayVersion = "1.0",
	Date = "2024-05-26", -- yyyy-mm-dd
	SourceLocation = "https://github.com/NiLSPACE/ChunkGen",
	Description = [[Inspired by {%a https://github.com/cuberite/chunkworx}ChunkWorx{%/a} this plugin allows the user to easily (re)generate chunks from the webadmin. ChunkWorx still works, but it's been 10 years since anyone has looked at the code. There are lots of magic numbers, and the interface loses it's state everytime there is a reload. For this reason I made this plugin. Not just to try make a more user friendly replacement, but also to see how viable Ajax calls are when used inside Cuberite.
    
    Some advantages over ChunkWorx:
    {%list}
    {%li}Async interface{%/li}
    {%li}Allow any radius around a player instead of just the exact chunk or 3x3{%/li}
    {%li}Statistics about the generator, lighting en storage queues.{%/li}
    {%li}The to be generated chunks can spiral around a set of coordinates or a player which allows you to see the new chunks immediately instead of waiting for the updates to finally catch up to you.{%/li}
    {%/list}
	]],
}