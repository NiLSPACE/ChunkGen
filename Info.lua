
-- Info.lua

-- Implements the g_PluginInfo standard plugin description

g_PluginInfo =
{
	Name = "ChunkGen",
	Version = 4,
	DisplayVersion = "1.3",
	Date = "2024-06-27", -- yyyy-mm-dd
	SourceLocation = "https://github.com/NiLSPACE/ChunkGen",
	Description = [[Inspired by {%a https://github.com/cuberite/chunkworx}ChunkWorx{%/a} this plugin allows the user to easily (re)generate chunks from the webadmin. ChunkWorx still works, but it's been 10 years since anyone has looked at the code. There are lots of magic numbers which makes maintaining the code harder. The interface also loses it's state everytime there is a reload which makes development on the world generator more frustrating. This plugin tries to solve all these issues and add some more functionality to make world generator development easier.
    
    Some advantages over ChunkWorx:
    {%list}
    {%li}Interface state isn't lost when Cuberite reloads.{%/li}
    {%li}Allow any radius around a player instead of just the exact chunk or 3x3.{%/li}
    {%li}Shows statistics about the generator, lighting and storage queues.{%/li}
    {%li}The to be generated chunks can spiral around a set of coordinates or a player which allows you to see the new chunks immediately instead of waiting for the updates to finally catch up to you.{%/li}
    {%/list}
	]],

    Commands =
    {
        ["/reg"] =
        {
            HelpString = "Regenerates chunks around the player or cancel the previous task.",
            Permission = "chunkgen.reg",
            Handler = HandleRegCommand,
            ParameterCombinations =
            {
                {
                    Params = "<radius>",
                    Help = "Generates chunks around you in the specified radius."
                },
                {
                    Params = "cancel",
                    Help = "Stops your last chunk generation tasks."
                },
            }
        }
    }
}