




--- Returns the status of all worlds.
-- This includes all running tasks and all the players.
function HandleEndpointWorlds(a_Request)
	local worlds = {};
	cRoot:Get():ForEachWorld(function(a_World)
		local players = {};
		local tasks = g_Tasks[a_World:GetName()]
		a_World:ForEachPlayer(function(a_Player)
			table.insert(players, a_Player:GetName())
		end);
		table.insert(worlds, {
			name = a_World:GetName(), 
			players = players,
			tasks = tasks,
			stats = {
				generator_queue = a_World:GetGeneratorQueueLength(),
				lighting_queue = a_World:GetLightingQueueLength(),
				storage_save_queue = a_World:GetStorageSaveQueueLength(),
				storage_load_queue = a_World:GetStorageLoadQueueLength()
			}
		});
	end);
	return cJson:Serialize(worlds), "application/json"
end





--- Builds a file path from all parameters using cFile:GetPathSeparator as the separator.
-- Expects that all arguments are strings.
local function CreatePath(...)
	return table.concat({...}, cFile:GetPathSeparator())
end





--- All the files that the web page can request.
local g_Files = {
	angular = {path = CreatePath(cPluginManager:GetCurrentPlugin():GetLocalFolder(), "lib", "angular.min.js"), mime = "application/javascript"},
	index =   {path = CreatePath(cPluginManager:GetCurrentPlugin():GetLocalFolder(), "lib", "index.html"), mime = "text/html"},
	appjs =   {path = CreatePath(cPluginManager:GetCurrentPlugin():GetLocalFolder(), "lib", "app.js"), mime = "application/javascript"},
	appcss =  {path = CreatePath(cPluginManager:GetCurrentPlugin():GetLocalFolder(), "lib", "app.css"), mime = "text/css"}
}





--- Endpoint that handles the loading/returning of the index page, it's javascript/css files and it's libraries
function HandleEndpointGetFile(a_Request)
	local fileReq = a_Request.Params["file"]
	if (g_Files[fileReq]) then
		return cFile:ReadWholeFile(g_Files[fileReq].path), g_Files[fileReq].mime
	end
	return "Unknown file"
end





--- Handles the creation of a new chunk generating task.
function HandleEndpointTask(a_Request)
	local task = a_Request.PostParams["task"];
	if (not task) then
		return "Invalid Task";
	end
	local decoded = cJson:Parse(task);
	if (not decoded) then
		return "Invalid Task";
	end
	
	local world = decoded.world
	if (not world) then
		return "World not specified"
	elseif (cRoot:Get():GetWorld(world) == nil) then
		return "Unknown world"
	end
	
	if (decoded.type == "fixed") then
		return HandleSubEndpointFixedTask(decoded);
	elseif (decoded.type == "player") then
		return HandleSubEndpointPlayerTask(decoded);
	else
		return "Unknown type"
	end
end





--- Starts a new chunk generating task around the provided coordinates.
function HandleSubEndpointFixedTask(a_Task)
	return CreateTaskFixed(a_Task);
end





--- Starts a new chunk generating task around the requested player.
function HandleSubEndpointPlayerTask(a_Task)
	return CreateTaskPlayer(a_Task);
end





--- Cancels the requested task.
function HandleEndpointCancelTask(a_Request)
	local taskId = a_Request.PostParams["taskId"]
	if (not taskId) then
		return "No task id provided"
	end
	return CancelTask(taskId);
end





--- All supported endpoints.
local g_Endpoints = {
	file = HandleEndpointGetFile,
	worlds = HandleEndpointWorlds,
	task = HandleEndpointTask,
	canceltask = HandleEndpointCancelTask
}





--- Handles all incoming requests.
-- If no specific endpoint is requested it returns HTML
-- containing an iframe that points to the actual page.
-- Using an iframe has the advantage that all ajax calls
-- made will also point to /~webadmin which means no layout will be send.
-- The downside is that auto resizing gets a little more complicated.
function HandleWebRequest(a_Request)
	local requestedEndpoint = a_Request.Params["endpoint"] or
		a_Request.PostParams["endpoint"] or
		(a_Request.FormData["endpoint"] and a_Request.FormData["endpoint"].Value)
	
	if (requestedEndpoint) then
		if (g_Endpoints[requestedEndpoint]) then
			return g_Endpoints[requestedEndpoint](a_Request);
		end
		return "Unknown Endpoint"
	end
	
	-- Loading the page as an iframe has the advantage that all Ajax calls will automatically go to /~webadmin.
	return [[
	<style>
	#content-iframe {
		width:100%;
		min-height: 70vh;
		border: none;
	}
	</style>
	<script>
		function resizeIframe(obj) {
			obj.style.height = obj.contentWindow.document.documentElement.scrollHeight + 'px';
		}
		window.addEventListener("message", (event) => {
			let iframe = document.getElementById("content-iframe");
			resizeIframe(iframe);
		})
	</script>
	<iframe id="content-iframe"  onload="resizeIframe(this)" src="/~webadmin/ChunkRegen/Chunk+Regen?endpoint=file&file=index">
	]]
end





