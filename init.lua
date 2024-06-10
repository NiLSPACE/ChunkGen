
-- init.lua

-- Contains the initialization code.





function Initialize(a_Plugin)
	a_Plugin:SetName(g_PluginInfo.Name)
	a_Plugin:SetVersion(g_PluginInfo.Version)

	-- Load the InfoReg library file for registering the Info.lua command table:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")

	a_Plugin:AddWebTab("Chunk Regen", HandleWebRequest)
	
	-- Register world tick hook which will check for chunk generation tasks.
	RegisterHooks();

	-- Register commands:
	RegisterPluginInfoCommands()
	
	LOG("Initialized");
	return true;
end

