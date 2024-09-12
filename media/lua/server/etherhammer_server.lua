--- Checks for Global functions that are injected through cheat patches to Project Zomboid's client.
---
--- @author asledgehammer, 2023
if isClient() or not isServer() then return end

(function()
    --- @type ZLogger
    local logger = ZLogger.new('AntiCheat', true);

    --- @param username string
    ---
    --- @return string
    local kickMessage = function(username)
        return 'The player \'' .. username .. '\' was kicked from the server. (Reason: Hacking)';
    end

    --- @param username string
    ---
    --- @return string
    local altKickMessage = function(username)
        return 'WARNING: The player \'' ..
            username ..
            '\' is playing with a hack. ' ..
            'Sending client-command to disconnect however their client can be altered to ignore ' ..
            'it. (CraftHammer not installed!)';
    end

    local warningNoInstall =
        '\n\n' ..
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' ..
        '!!! WARNING                                                !!!\n' ..
        '!!!                                                        !!!\n' ..
        '!!! CraftHammer is not installed!                          !!!\n' ..
        '!!! The server will NOT kick players with detected hacks.  !!!\n' ..
        '!!!                                                        !!!\n' ..
        '!!! To grab a copy, Go here: https://discord.gg/r6PeSFuJDU !!!\n' ..
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n' ..
        '\n\n';

    --- Custom API call for the server if CraftHammer is installed. You should use this!
    ---
    --- @diagnostic disable-next-line: undefined-field
    local kick = _G.kickPlayerFromServer;

    --- Place an alternative method that instructs the client to disconnect itself.
    ---
    --- NOTE: This may not work as a client can be compromised by the hack as self-protection.
    if kick == nil then
        kick = function(player, reason)
            logger:write(altKickMessage(player:getUsername()));
            sendClientCommand('etherhammer', 'disconnect', {});
        end
        print(warningNoInstall);
    end

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
    ---@param player IsoPlayer
    ---@param global string[] The global array of functions to test.
    local checkGlobal = function(player, global)
        if checkIfGlobalFunctionsExists(global, etherHackFunctions) then
            if kick ~= nil then kick(player, kickMessage(player:getUsername())) end
            return
        end
    end

    ---@param module string
    ---@param command string
    ---@param player IsoPlayer
    ---@param args table
    local clientFunc = function(module, command, player, args)
        if module ~= 'etherhammer' then return end
        if command == 'handshake' then checkGlobal(player, args.global) end
    end

    Events.OnClientCommand.Add(clientFunc);
end)();
