


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
function CanContinue(a_World)
	return a_World:GetGeneratorQueueLength() < MAX_GENERATOR_QUEUE
	and    a_World:GetLightingQueueLength()  < MAX_LIGHTING_QUEUE
	and    (a_World:GetStorageSaveQueueLength() + a_World:GetStorageLoadQueueLength()) < MAX_STORAGE_QUEUE
end





--- Creates an iterator which returns X/Z coordinates between the provided min/max x and z coordinates.
function CoordinateProviderArea(a_MinX, a_MaxX, a_MinZ, a_MaxZ)
	local sizeX = a_MaxX - a_MinX + 1;
	local sizeZ = a_MaxZ - a_MinZ + 1;
	local idx = 0;
	return function()
		if (idx == sizeX * sizeZ) then
			return;
		end
		local x = idx % sizeX;
		local z = math.floor(idx / sizeX)
		idx = idx + 1
		return a_MinX + x, a_MinZ + z
	end
end





--- Creates an iterator which returns X/Z coordinates that spirals around a_X and a_Z until the requested radius is reached.
function CoordinateProviderSpiral(a_X, a_Z, a_Radius)
	-- Spiral code from https://stackoverflow.com/a/19287714
	local function spiral(n)
		-- given n an index in the squared spiral
		-- p the sum of point in inner square
		-- a the position on the current square
		-- n = p + a

		-- Original code: http:--jsfiddle.net/davidonet/HJQ4g/
		if (n == 0) then
			return 0, 0;
		end
		n = n - 1;
		
		local r = math.floor((math.sqrt(n + 1) - 1) / 2) + 1;
		
		-- compute radius : inverse arithmetic sum of 8+16+24+...=
		local p = (8 * r * (r - 1)) / 2;
		-- compute total point on radius -1 : arithmetic sum of 8+16+24+...

		local en = r * 2;
		-- points by face

		local a = (1 + n - p) % (r * 8);
		-- compute de position and shift it so the first is (-r,-r) but (-r+1,-r)
		-- so square can connect

		local x, z;
		local face = math.floor(a / (r * 2))
		if (face == 0) then
			x = a - r;
			z = -r;
		elseif (face == 1) then
			x = r;
			z = (a % en) - r;
		elseif (face == 2) then
			x = r - (a % en);
			z = r;
		elseif (face == 3) then
			x = -r;
			z = r - (a % en);
		end
		return x, z;
	end
	
	local idx = 0;
	local target = (a_Radius * 2 + 1) ^ 2
	return function()
		if (idx == target) then
			return;
		end
		local offsetX, offsetZ = spiral(idx)
		idx = idx + 1
		return a_X + offsetX, a_Z + offsetZ
	end
end





--- Creates and starts a new chunk generating task using the provided parameters.
function CreateTask(a_World, a_Mode, a_ChunkX, a_ChunkZ, a_Radius, a_ChunkOrder)
	local task = {
		totalChunks = (a_Radius * 2 + 1) ^ 2,
		progress = 0,
		status = "running",
		id = cUUID:GenerateVersion3(math.random()):ToShortString(),
	}
	
	local coordinateProvider;
	if (a_ChunkOrder == ChunkOrder.Lines) then
		coordinateProvider = CoordinateProviderArea(
			a_ChunkX - a_Radius, a_ChunkX + a_Radius,
			a_ChunkZ - a_Radius, a_ChunkZ + a_Radius
		);
	elseif (a_ChunkOrder == ChunkOrder.Spiral) then
		coordinateProvider = CoordinateProviderSpiral(a_ChunkX, a_ChunkZ, a_Radius)
	else
		return "Unknown chunk order"
	end
	
	local mt = {
		cor = coroutine.create(function()
			local world = cRoot:Get():GetWorld(a_World);
			for x, z in coordinateProvider do
				task.progress = task.progress + 1
				if (a_Mode == GenerateMode.Regenerate) then
					world:RegenerateChunk(x, z);
				elseif (a_Mode == GenerateMode.Generate) then
					world:GenerateChunk(x, z);
				end
				
				if (task.progress % BATCH_SIZE == 0) then
					world:QueueSaveAllChunks()
					world:QueueUnloadUnusedChunks()
					while (true) do
						world = nil; -- Don't hold a reference to cWorld.
						coroutine.yield()
						world = cRoot:Get():GetWorld(a_World);
						
						if (CanContinue(world)) then
							break;
						end
					end
				end
			end
		end)
	}
	
	-- By setting the coroutine as part of the metatable cJson won't try to serialize it.
	setmetatable(task, {__index = mt})
	table.insert(g_Tasks[a_World], task);
end





--- Creates a new chunk generating task at fixed coordinates.
function CreateTaskFixed(a_Task)
	return CreateTask(a_Task.world, a_Task.generateMode, a_Task.chunkX, a_Task.chunkZ, a_Task.radius, a_Task.chunkOrder);
end





--- Creates a new task from generating chunks around the requested player.
-- Only looks for the player in the specified world. 
-- If there are multiple people with the same name only the first one is used.
function CreateTaskPlayer(a_Task)
	local world = cRoot:Get():GetWorld(a_Task.world);
	local chunkX, chunkZ
	world:ForEachPlayer(function(a_Player)
		if (a_Player:GetName() == a_Task.playerName) then
			chunkX = a_Player:GetChunkX();
			chunkZ = a_Player:GetChunkZ();
			return true;
		end
	end);
	return CreateTask(a_Task.world, a_Task.mode, chunkX, chunkZ, a_Task.radius, a_Task.chunkOrder)
end





--- Removes the requested task from the queue.
function CancelTask(a_TaskId)
	for world, tasks in pairs(g_Tasks) do
		for idx = 1, #tasks do
			local task = tasks[idx]
			if (task.id == a_TaskId) then
				table.remove(tasks, idx)
				return "Task canceled";
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
	if (coroutine.status(currentTask.cor) == "dead") then
		a_World:QueueSaveAllChunks()
		a_World:QueueUnloadUnusedChunks()
		table.remove(g_Tasks[a_World:GetName()], 1);
		return;
	end
	local response = coroutine.resume(currentTask.cor)
end





--- Registers all the Cuberite hooks.
function RegisterHooks()
	cPluginManager:AddHook(cPluginManager.HOOK_WORLD_TICK, OnWorldTick)
end




