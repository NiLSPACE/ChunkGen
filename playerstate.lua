
--- playerstate.lua

-- Contains information about the players current chunk tasks.




-- Table containing all the player states
local g_PlayerStates = {}

-- PlayerState class object
local PlayerState = {}





function PlayerState:new(a_PlayerUUID)
    local obj = {}

    setmetatable(obj, {__index = PlayerState});

    -- The tasks created by the player.
    obj._tasks = {}
    obj._uuid = a_PlayerUUID

    return obj;
end





--- Sends a message to the player.
-- Message can be a string or an array of strings.
function PlayerState:SendMessage(a_Messages)
    local messages = type(a_Messages) == "string" and {a_Messages} or a_Messages;

    cRoot:Get():DoWithPlayerByUUID(self._uuid, function(a_Player)
        for idx, message in ipairs(messages) do
            a_Player:SendMessage(message)
        end
    end)
end




--- Removes the specified task from the player's task list.
function PlayerState:RemoveTask(a_Task)
    for idx = 1, #self._tasks do
        local task = self._tasks[idx]
        if (task.id == a_Task.id) then
            table.remove(self._tasks, idx)
            return
        end
    end
end





function PlayerState:CancelLastTask()
    if (#self._tasks == 0) then
        self:SendMessage("No tasks to cancel")
        return
    end
    CancelTask(self._tasks[#self._tasks].id)
end





function PlayerState:CreateNewTask(a_Player, a_Radius)
    local success, task = CreateTask(a_Player:GetWorld():GetName(), GenerateMode.Regenerate, a_Player:GetChunkX(), a_Player:GetChunkZ(), a_Radius, ChunkOrder.Spiral)
    if (not success) then
        -- Task contains the error message
        return false, task
    end
    task:SetOnCompleteCallback(function(a_Task, a_Reason)
        self:SendMessage("Chunk generation task was " .. a_Reason .. ".")
        self:RemoveTask(task)
    end)
    table.insert(self._tasks, task)
    return true, task
end





function GetPlayerState(a_Player)
    local uuid = a_Player:GetUUID()
    if (g_PlayerStates[uuid]) then
        return g_PlayerStates[uuid]
    end
    g_PlayerStates[uuid] = PlayerState:new(uuid)
    return g_PlayerStates[uuid]
end




