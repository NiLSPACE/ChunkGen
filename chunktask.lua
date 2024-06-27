


g_Tasks = {}

-- Initialize g_Tasks for every world with an empty array.
cRoot:Get():ForEachWorld(function(a_World)
	g_Tasks[a_World:GetName()] = {}
end)

-- Constants
local BATCH_SIZE = 100;
local MAX_GENERATOR_QUEUE = 200;
local MAX_LIGHTING_QUEUE = 200;
local MAX_STORAGE_QUEUE = 80;





--- Returns true if all the world chunk queues are not full enough.
local function CanContinue(a_World)
	return a_World:GetGeneratorQueueLength() < MAX_GENERATOR_QUEUE
	and    a_World:GetLightingQueueLength()  < MAX_LIGHTING_QUEUE
	and    (a_World:GetStorageSaveQueueLength() + a_World:GetStorageLoadQueueLength()) < MAX_STORAGE_QUEUE
end






-- ChunkTask class object.
local ChunkTask = {}





function ChunkTask:new(a_WorldName, a_TotalChunks, a_CoordinateProvider, a_Mode)
	local obj = {}
	
	-- Variables inside privates won't be serialized by cJson.
	-- Privates can be accessed by getting __index field from getmetatable on self.
	local privates = {}
	setmetatable(obj, {__index = setmetatable(privates, {__index = ChunkTask})})

	obj.totalChunks = a_TotalChunks
	obj.progress = 0
	obj.status = "running"
	obj.id = cUUID:GenerateVersion3(math.random()):ToShortString()
	obj.worldName = a_WorldName
	obj.mode = a_Mode
	privates.coordinateProvider = a_CoordinateProvider
	privates.onCompleteCallback = nil
	privates.coroutine = obj:CreateCoroutine()

	return obj
end





function ChunkTask:CreateCoroutine()
	return coroutine.create(function()
		local world = cRoot:Get():GetWorld(self.worldName);
		for x, z in self.coordinateProvider do
			self.progress = self.progress + 1
			if (self.mode == GenerateMode.Regenerate) then
				world:RegenerateChunk(x, z);
			elseif (self.mode == GenerateMode.Generate) then
				world:GenerateChunk(x, z);
			end
			
			if (self.progress % BATCH_SIZE == 0) then
				world:QueueSaveAllChunks()
				world:QueueUnloadUnusedChunks()
				while (true) do
					world = nil; -- Don't hold a reference to cWorld.
					coroutine.yield()
					world = cRoot:Get():GetWorld(self.worldName);
					
					if (CanContinue(world)) then
						break;
					end
				end
			end
		end
	end)
end





function ChunkTask:OnComplete(a_Reason)
	if (self.onCompleteCallback) then
		pcall(self.onCompleteCallback, self, a_Reason)
	end
end





function ChunkTask:SetOnCompleteCallback(a_Callback)
	-- Set callback as private so cJson won't try to serialize it.
	getmetatable(self).__index.onCompleteCallback = a_Callback
end





--- Creates and starts a new chunk generating task using the provided parameters.
function CreateTask(a_World, a_Mode, a_ChunkX, a_ChunkZ, a_Radius, a_ChunkOrder, a_OnCompleteCallback)
	local coordinateProvider;
	if (a_ChunkOrder == ChunkOrder.Lines) then
		coordinateProvider = CoordinateProviderArea(
			a_ChunkX - a_Radius, a_ChunkX + a_Radius,
			a_ChunkZ - a_Radius, a_ChunkZ + a_Radius
		);
	elseif (a_ChunkOrder == ChunkOrder.Spiral) then
		coordinateProvider = CoordinateProviderSpiral(a_ChunkX, a_ChunkZ, a_Radius)
	elseif (a_ChunkOrder == ChunkOrder.Hilbert) then
		coordinateProvider = CreateIteratorHilbert(a_ChunkX, a_ChunkZ, a_Radius)
	else
		return false, "Unknown chunk order"
	end
	
	LOGINFO(("New chunk generation task.  Size: %s,  Chunk Iterator: %s,  Mode: %s"):format((a_Radius * 2 + 1) ^ 2, a_ChunkOrder, a_Mode))
	local task = ChunkTask:new(a_World, (a_Radius * 2 + 1) ^ 2, coordinateProvider, a_Mode)

	table.insert(g_Tasks[a_World], task);
	return true, task
end





--- Removes the requested task from the queue.
function CancelTask(a_TaskId)
	for world, tasks in pairs(g_Tasks) do
		for idx = 1, #tasks do
			local task = tasks[idx]
			if (task.id == a_TaskId) then
				table.remove(tasks, idx)
				task:OnComplete("canceled")
				return "Task canceled"
			end
		end
	end
	return "Task not found"
end





--- Called for every world on every tick.
-- Checks if there is a task in the queue to process and resumes it.
function OnWorldTick(a_World, a_Delta)
	local currentTask = g_Tasks[a_World:GetName()][1]
	if (not currentTask) then
		return;
	end
	if (coroutine.status(currentTask.coroutine) == "dead") then
		a_World:QueueSaveAllChunks()
		a_World:QueueUnloadUnusedChunks()
		table.remove(g_Tasks[a_World:GetName()], 1);
		currentTask:OnComplete("completed")
		return;
	end
	local response = coroutine.resume(currentTask.coroutine)
end





--- Registers all the Cuberite hooks.
function RegisterHooks()
	cPluginManager:AddHook(cPluginManager.HOOK_WORLD_TICK, OnWorldTick)
end




