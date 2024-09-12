--- Checks for Global functions that are injected through cheat patches to Project Zomboid's client.
---
--- @author asledgehammer, 2023
(function()
    -- Some LuaMethods rom EtherLuaMethods.java that are injected.
    local etherHackFunctions = {
        'getAntiCheat8Status',
        'getAntiCheat12Status',
        'getExtraTexture',
        'hackAdminAccess',
        'isDisableFakeInfectionLevel',
        'isDisableInfectionLevel',
        'isDisableWetness',
        'isEnableUnlimitedCarry',
        'isOptimalWeight',
        'isOptimalCalories',
        'isPlayerInSafeTeleported',
        'learnAllRecipes',
        'requireExtra',
        'safePlayerTeleport',
        'toggleEnableUnlimitedCarry',
        'toggleOptimalWeight',
        'toggleOptimalCalories',
        'toggleDisableFakeInfectionLevel',
        'toggleDisableInfectionLevel',
        'toggleDisableWetness',
        -- 'instanceof' -- [DEBUG]
    };

    --- Only perform the actual kick here. We want to check and see if a ticket exists first with
    --- our message. (This prevents ticket spamming the server)
    local disconnectFromServer = function()
        setGameSpeed(1);
        pauseSoundAndMusic();
        setShowPausedMessage(true);
        getCore():quit();
    end

    local getGlobalFunctions = function()
        local array = {};
        for name, value in pairs(_G) do
            -- Java API:
            --     'function <memory address>'
            -- Lua API:
            --     'closure <memory address>'
            if type(value) == 'function' and string.find(tostring(value), 'function ') == 1 then
                table.insert(array, name);
            end
        end
        table.sort(array, function(a, b) return a:upper() < b:upper() end);
        return array;
    end

    --- Kicks a player from the server.
    ---
    --- @return void
    local kick = function(hackName)
        local player = getPlayer();
        local username = player:getUsername();
        local ticketMessage = 'Hello. I am using ' .. hackName .. '. Please ban me.'

        --- Add and Remove the ticket checker after checking for a pre-existing hack message.
        --- @param tickets ArrayList<DBTicket>
        local __f = function(tickets) end
        __f = function(tickets)
            -- Execute only once.
            Events.ViewTickets.Remove(__f);
            local length = tickets:size() - 1;
            for i = 0, length, 1 do
                --- @type DBTicket
                local ticket = tickets:get(i);
                local author, message = ticket:getAuthor(), ticket:getMessage();
                if author == username and message == ticketMessage then
                    disconnectFromServer();
                    return
                end
            end
            addTicket(username, ticketMessage, -1);
            disconnectFromServer();
        end
        Events.ViewTickets.Add(__f);

        getTickets(username);
    end

    --- Checks if an array has a value stored.
    ---
    --- @param array string[] The array to check.
    --- @param value string The value to check.
    --- @return boolean True if one or more values are in the array.
    local hasValue = function(array, value)
        for _, next in ipairs(array) do if value == next then return true end end
        return false
    end

    --- Checks if one or more functions exists on the global scope. (_G)
    ---
    --- @param funcs string[] The names of the functions to test.
    --- @return boolean True if one or more global functions exists and is the type() == 'function'
    local checkIfGlobalFunctionsExists = function(global, funcs)
        for i = 1, #funcs do if hasValue(global, funcs[i]) then return true end end
        return false;
    end

    --- Tests the global functions of the player for EtherHack.
    ---
    --- @param global string[] The global array of functions to test.
    --- @return boolean True if the player has any functions that are injected into their client
    --- from the EtherHack client mod.
    local detectEtherHack = function(global)
        if checkIfGlobalFunctionsExists(global, etherHackFunctions) then
            kick('EtherHack');
            return true;
        end
        return false;
    end

    -- Only run the check when the game runs.
    Events.OnGameStart.Add(function()
        -- Keeps it only to the client-sessions for servers.
        if not isClient() then return end

        -- SERVER-SIDE HANDSHAKE
        sendClientCommand('etherhammer', 'handshake', { global = getGlobalFunctions() });

        -- CLIENT-SIDE CHECKING
        detectEtherHack(getGlobalFunctions());

        -- Keep checking in order to detect delayed injections from cheat(s).
        Events.EveryHours.Add(function()
            detectEtherHack(getGlobalFunctions());
        end);
    end);

    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= 'etherhammer' then return end
        if command == 'disconnect' then
            disconnectFromServer();
        elseif command == 'handshake' then
            sendClientCommand('etherhammer', 'handshake', { global = getGlobalFunctions() })
        end
    end)

    -- TODO: Add a players check for logins, logouts with a handshake request. - Jab, 11/12/2023
end)();
