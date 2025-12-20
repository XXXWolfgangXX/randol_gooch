local Config = lib.require('server.sv_config')
local lastPlayer = 0
local goochedPlayer

local function canBeChosen(id)
    local ped = GetPlayerPed(id)
    return not isPlyDead(id) and id ~= lastPlayer and GetVehiclePedIsIn(ped, false) == 0
    -- Check dead, chosen player isn't the same as the last and make sure we're not in a vehicle.
    -- You can add more checks in here, these are just basic.
end

local function findRandomPlayer()
    local players = GetActivePlayers()
    if #players == 0 then return false end

    for i = #players, 2, -1 do
        local j = math.random(1, i)
        players[i], players[j] = players[j], players[i]
    end

    for i = 1, #players do
        local id = players[i]
        if canBeChosen(id) then
            return id
        end
    end

    return false
end

local function goochInterval()
    local id = findRandomPlayer()
    if id then
	    lastPlayer = id
	    goochedPlayer = { src = id }
		Wait(1000)
	    TriggerClientEvent('randol_gooch:client:spawnGooch', id)
	end
end

RegisterNetEvent('randol_gooch:server:storeGooch', function(netId)
    local src = source
    if not goochedPlayer or goochedPlayer.src ~= src then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) or GetEntityModel(entity) ~= `U_M_M_YuleMonster` then return end

    goochedPlayer.entity = entity
end)

RegisterNetEvent('randol_gooch:server:stealMoney', function()
    local src = source
    if not goochedPlayer or goochedPlayer.src ~= src then return end

    local player = GetPlayer(src)
    if not player then return end

    local cash = GetPlayersCash(player)

    if Config.StealPlayersCash and cash > 0 then
        goochedPlayer.cash = cash
        RemoveMoney(player, 'cash', cash)
    end

    local msg
    if Config.StealPlayersCash and cash > 0 then
        msg = 'The Gooch has stolen your cash. Take them out and collect the present left behind to recover it and earn an additional bonus.'
    else
        msg = 'The Gooch stole your dignity. Take them out and collect the present left behind to recover it and earn an additional bonus.'
    end

    DoNotification(src, msg, 'error')
end)

RegisterNetEvent('randol_gooch:server:onDeath', function(netId)
    local src = source
    if not goochedPlayer or goochedPlayer.src ~= src then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) or GetEntityModel(entity) ~= `U_M_M_YuleMonster` then return end

    local coords = GetEntityCoords(entity)

    if goochedPlayer.entity ~= entity then return end
    
    DeleteEntity(entity)
    goochedPlayer.entity = nil

    local present = CreateObjectNoOffset(`xm3_prop_xm3_present_01a`, coords.x, coords.y, coords.z - 0.98, true, true)
    while not DoesEntityExist(present) do Wait(0) end

    goochedPlayer.present = present

    DoNotification(src, 'The Gooch has dropped a present', 'success')
    TriggerClientEvent('randol_gooch:client:dropPresent', src, NetworkGetNetworkIdFromEntity(present))
end)

RegisterNetEvent('randol_gooch:server:goochGotAway', function()
    local src = source
    if not goochedPlayer or goochedPlayer.src ~= src then return end

    if goochedPlayer.entity and DoesEntityExist(goochedPlayer.entity) then
        DeleteEntity(goochedPlayer.entity)
        -- probably add your own logging here if the gooch gets away with your player's money KEKW.
        TriggerClientEvent('randol_gooch:client:resetGooch', src)
    end

    goochedPlayer = nil
end)

lib.callback.register('randol_gooch:server:claimReward', function(source)
    local src = source
    if not goochedPlayer or goochedPlayer.src ~= src then return false end
    if not goochedPlayer.present or GetEntityModel(goochedPlayer.present) ~= `xm3_prop_xm3_present_01a` then return false end

    local pedCoords = GetEntityCoords(GetPlayerPed(src))
    local presentCoords = GetEntityCoords(goochedPlayer.present)

    if #(pedCoords - presentCoords) > 10.0 then return false end

    local player = GetPlayer(src)
    if not player then return false end

    if Config.StealPlayersCash and goochedPlayer.cash then
        AddMoney(player, 'cash', goochedPlayer.cash)
        DoNotification(src, 'You got your cash back!', 'success')
    end

    Config.AdditionalRewards(player, src)

    DeleteEntity(goochedPlayer.present)
    goochedPlayer = nil

    return true
end)

AddEventHandler('playerDropped', function()
    local src = source
    if not goochedPlayer or goochedPlayer.src ~= src then return end

    if goochedPlayer.entity then
        DeleteEntity(goochedPlayer.entity)
    end

    goochedPlayer = nil
end)

SetInterval(goochInterval, Config.Timer * 60000) -- Will cycle every x minutes and pick a random player.

