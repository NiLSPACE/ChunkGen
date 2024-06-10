
--- Commands.lua

-- Contains the command handlers




function HandleRegCommand(a_Split, a_Player)
    
    if (not a_Split[2]) then
        a_Player:SendMessage("Missing second parameter.")
        a_Player:SendMessage("Usage 1: /reg <radius>")
        a_Player:SendMessage("Usage 2: /reg cancel")
        return true;
    end
    local playerstate = GetPlayerState(a_Player)
    if (a_Split[2] == "cancel") then
        playerstate:CancelLastTask()
        return true
    end
    
    local radius = tonumber(a_Split[2])
    if (not radius) then
        a_Player:SendMessage("Specified radius is not a number.")
        return true;
    end

    local success, task = playerstate:CreateNewTask(a_Player, radius);
    if (not success) then
        a_Player:SendMessage(cChatColor.Red .. task)
    else
        a_Player:SendMessage(cChatColor.Green .. "Task started")
    end
    return true
end




