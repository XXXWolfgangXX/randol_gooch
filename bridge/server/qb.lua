if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()
local ox_inv = GetResourceState('ox_inventory') == 'started'

function GetPlayer(id)
    return QBCore.Functions.GetPlayer(id)
end

function GetPlyIdentifier(Player)
    return Player.PlayerData.citizenid
end

function DoNotification(src, text, nType)
    TriggerClientEvent('QBCore:Notify', src, text, nType)
end

function GetCharacterName(Player)
    return Player.PlayerData.charinfo.firstname.. ' ' ..Player.PlayerData.charinfo.lastname
end

function AddMoney(Player, moneyType, amount)
    Player.Functions.AddMoney(moneyType, amount)
end

function RemoveMoney(player, acc, amount)
    player.Functions.RemoveMoney(acc, amount)
end

function GetPlayersCash(player)
    return player.PlayerData.money.cash
end

function isPlyDead(src)
    local player = GetPlayer(src)
    return player.PlayerData.metadata.isdead or player.PlayerData.metadata.inlaststand
end