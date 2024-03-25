
-- init.lua

-- Contains the initialization code.





function Initialize(a_Plugin)	
	a_Plugin:AddWebTab("Chunk Regen", HandleWebRequest)
	
	RegisterHooks();
	
	LOG("Initialized");
	return true;
end

