local Config = lib.require('server.sv_config')
local lastPlayer = 0
local goochedPlayer = {}

local function canBeChosen(id)
    local ped = GetPlayerPed(id)
    return not isPlyDead(id) and id ~= lastPlayer and GetVehiclePedIsIn(ped, false) == 0
    -- Check dead, chosen player isn't the same as the last and make sure we're not in a vehicle.
    -- You can add more checks in here, these are just basic.
end

local function findRandomPlayer()
    local players = GetActivePlayers()
    if #players == 0 then return false end

    local tempStore = {}
    local attempts = 0

    while attempts < #players do
        local index = math.random(#players)
        local id = players[index]

        if not tempStore[id] then
            tempStore[id] = true
            attempts += 1

            if id ~= lastPlayer and canBeChosen(id) then
                return id
            end
        end
    end

    return false
end

local function goochInterval()
    local id = findRandomPlayer()
    if id then
        lastPlayer = id
        goochedPlayer[id] = {}
        TriggerClientEvent('randol_gooch:client:spawnGooch', id)
    end
end

RegisterNetEvent('randol_gooch:server:storeGooch', function(netId)
    local src = source
    if lastPlayer ~= src or not goochedPlayer[src] then return end

    local gooch = NetworkGetEntityFromNetworkId(netId)

    if not DoesEntityExist(gooch) or GetEntityModel(gooch) ~= `U_M_M_YuleMonster` then return end

    goochedPlayer[src].netid = netId
    goochedPlayer[src].entity = gooch
end)

RegisterNetEvent('randol_gooch:server:stealMoney', function()
    local src = source
    if lastPlayer ~= src or not goochedPlayer[src] then return end

    local player = GetPlayer(src)
    if not player then return end

    local cash = GetPlayersCash(player)

    if Config.StealPlayersCash and cash > 0 then
        goochedPlayer[src].cash = cash
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
    if lastPlayer ~= src or not goochedPlayer[src] then return end

    local gooch = NetworkGetEntityFromNetworkId(netId)

    if not DoesEntityExist(gooch) or GetEntityModel(gooch) ~= `U_M_M_YuleMonster` or not goochedPlayer[src].netid then return end

    local coords = GetEntityCoords(gooch)

    if goochedPlayer[src].netid == netId and goochedPlayer[src].entity then
        DeleteEntity(goochedPlayer[src].entity)
    end
    
    goochedPlayer[src].netid = nil
    goochedPlayer[src].entity = nil

    local present = CreateObjectNoOffset(`xm3_prop_xm3_present_01a`, coords.x, coords.y, coords.z-0.98, true, true)
    while not DoesEntityExist(present) do
        Wait(0)
    end

    goochedPlayer[src].present = present

    DoNotification(src, 'The Gooch has dropped a present', 'success')
    TriggerClientEvent('randol_gooch:client:dropPresent', src, NetworkGetNetworkIdFromEntity(present))
end)

RegisterNetEvent('randol_gooch:server:goochGotAway', function()
    local src = source
    if lastPlayer ~= src or not goochedPlayer[src] then return end

    if goochedPlayer[src].entity and DoesEntityExist(goochedPlayer[src].entity) then
        DeleteEntity(goochedPlayer[src].entity)
        goochedPlayer[src] = nil
        -- probably add your own logging here if the gooch gets away with your player's money KEKW.
        TriggerClientEvent('randol_gooch:client:resetGooch', src)
    end
end)

lib.callback.register('randol_gooch:server:claimReward', function(source)
    local src = source

    if lastPlayer ~= src or not goochedPlayer[src] or not goochedPlayer[src].present or GetEntityModel(goochedPlayer[src].present) ~= `xm3_prop_xm3_present_01a` then return false end

    local pos = GetEntityCoords(GetPlayerPed(src))
    local coords = GetEntityCoords(goochedPlayer[src].present)

    if #(pos - coords) > 10.0 then return false end

    local player = GetPlayer(src)
    if not player then return false end

    if Config.StealPlayersCash and goochedPlayer[src].cash then 
        AddMoney(player, 'cash', goochedPlayer[src].cash)
        DoNotification(src, 'You got your cash back!', 'success')
    end

    Config.AdditionalRewards(player, src)
    DeleteEntity(goochedPlayer[src].present)
    goochedPlayer[src] = nil

    return true
end)

AddEventHandler('playerDropped', function(reason)
	local src = source
    if goochedPlayer[src] then
        if goochedPlayer[src].entity then
            DeleteEntity(goochedPlayer[src].entity)
        end
        goochedPlayer[src] = nil
    end
end)


SetInterval(goochInterval, Config.Timer * 60000) -- Will cycle every x minutes and pick a random player.
