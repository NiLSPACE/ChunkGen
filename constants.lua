
-- Constants.lua

-- Contains various constants used in the plugin.
-- All constants are saved in the 'Constants' variable making it easy to serialize them
-- so the frontend can also use them.





ChunkOrder = {
	Lines = "Lines",
	Spiral = "Spiral",
	Hilbert = "Hilbert"
}





GenerateMode = {
	Regenerate = "Regenerate",
	Generate = "Generate"
}





--- Contains a dictionary of all the constants. 
-- Makes it easy to serialize them to JSON.
Constants = {
	ChunkOrder = ChunkOrder,
	GenerateMode = GenerateMode
}



