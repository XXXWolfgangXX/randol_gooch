local gooch = {}
local grabDict, grabAnim = 'anim@scripted@player@freemode@tun_prep_ig1_grab_low@male@', 'grab_low'

local function playGoochAudio(entity, audioName)
    while not RequestScriptAudioBank('DLC_CM2022/CM2022_FREEMODE_01', false) do Wait(0) end
    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, audioName, entity, 'CM2022_Mugger_Sounds', false, -1)
    ReleaseSoundId(soundId)
	ReleaseNamedScriptAudioBank('DLC_CM2022/CM2022_FREEMODE_01')
end

local function onGoochDeath()
    if gooch.blip and DoesBlipExist(gooch.blip) then
        RemoveBlip(gooch.blip)
    end
    if gooch.ped then
        playGoochAudio(gooch.ped, 'Die')
        lib.requestNamedPtfxAsset('scr_xt_mugger')
        UseParticleFxAsset('scr_xt_mugger')
        StartNetworkedParticleFxNonLoopedOnEntityBone('scr_xt_mug_appear', gooch.ped, 0.0, 0.0, -0.3, 0.0, 0.0, 0.0, 11816, 1.0, false, false, false)
        TriggerServerEvent('randol_gooch:server:onDeath', NetworkGetNetworkIdFromEntity(gooch.ped))
		RemoveNamedPtfxAsset('scr_xt_mugger')
    end
end

local function goochBlip(ped)
    gooch.blip = AddBlipForEntity(ped)
    SetBlipSprite(gooch.blip, 1)
    SetBlipColour(gooch.blip, 1)
    SetBlipScale(gooch.blip, 0.5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Gooch')
    EndTextCommandSetBlipName(gooch.blip)
end

local function applySpawnAttributes(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesInWater(ped, false)
    DisablePedPainAudio(ped, true)
    StopPedSpeakingSynced(ped, true)
    SetPedSuffersCriticalHits(ped, false)
    SetCombatFloat(ped, 7, 1.0)
    SetCombatFloat(ped, 29, 2.0)
    SetPedCombatAbility(ped, 2)
    SetPedCombatAttributes(ped, 13, true)
    SetPedCombatAttributes(ped, 27, true)
    SetPedCombatAttributes(ped, 31, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 50, true)
    SetPedCombatAttributes(ped, 55, true)
    SetPedCombatAttributes(ped, 58, true)
    SetPedCombatAttributes(ped, 25, true)
    SetPedConfigFlag(ped, 286, true)
    SetPedConfigFlag(ped, 311, true)
    SetPedConfigFlag(ped, 410, true)
    SetPedConfigFlag(ped, 404, false)
    SetPedConfigFlag(ped, 208, true)
    SetPedConfigFlag(ped, 118, false)
    SetPedConfigFlag(ped, 42, true)
    SetPedConfigFlag(ped, 458, true)
    SetPedConfigFlag(ped, 153, true)
    SetPedConfigFlag(ped, 181, false)
    SetPedTargetLossResponse(ped, 1)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    UseFootstepScriptSweeteners(ped, true, `dlc_xm3_mugger_footsteps_sounds`)
end

RegisterNetEvent('randol_gooch:client:spawnGooch', function()
    if GetInvokingResource() then return end
    local pos = GetEntityCoords(cache.ped)
    local model = `U_M_M_YuleMonster`

    lib.requestModel(model, 10000)
    local ped = CreatePed(4, model, pos.x, pos.y-3.0, pos.z-0.98, 0.0, true, true)
    
    while not DoesEntityExist(ped) do
        Wait(0)
    end

	SetModelAsNoLongerNeeded(model)
    TriggerServerEvent('randol_gooch:server:storeGooch', NetworkGetNetworkIdFromEntity(ped))
    gooch.ped = ped
    applySpawnAttributes(ped)

    lib.requestNamedPtfxAsset('scr_xt_mugger')
    UseParticleFxAsset('scr_xt_mugger')
	StartNetworkedParticleFxNonLoopedOnEntityBone('scr_xt_mug_appear', ped, 0.0, 0.0, -0.3, 0.0, 0.0, 0.0, 11816, 1.0, false, false, false)
    
    playGoochAudio(ped, 'Spawn')

    TaskGoToEntity(ped, cache.ped, -1, 0.0, 2.0, 2.0, 0)
    SetPedCombatAttributes(ped, 2, false)
    FreezeEntityPosition(cache.ped, true)

    while GetScriptTaskStatus(ped, `SCRIPT_TASK_GO_TO_ENTITY`) < 2 do
        Wait(0)
    end

    FreezeEntityPosition(cache.ped, false)
    ClearPedTasksImmediately(ped)
    playGoochAudio(ped, 'Steal')
    TaskSmartFleePed(ped, cache.ped, 10000.0, -1, true, false)
    SetPedToRagdoll(cache.ped, 1000, 1000, 0, true, true, false)
    TriggerServerEvent('randol_gooch:server:stealMoney')
    goochBlip(ped)
    playGoochAudio(ped, 'Chase_Loop')
	RemoveNamedPtfxAsset('scr_xt_mugger')
	
    CreateThread(function()
        while DoesEntityExist(gooch.ped) do
            if #(GetEntityCoords(cache.ped) - GetEntityCoords(gooch.ped)) > 110.0 then
                TriggerServerEvent('randol_gooch:server:goochGotAway')
                break
            end

            if IsEntityDead(gooch.ped) and not gooch.dead then
                gooch.dead = true
                onGoochDeath()
                break
            end
            Wait(100)
        end
    end)
end)

RegisterNetEvent('randol_gooch:client:dropPresent', function(netid)
    if GetInvokingResource() then return end

    local pickup = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netid) then
            return NetToObj(netid)
        end
    end, '', 10000)

    PlaceObjectOnGroundOrObjectProperly(pickup)
    SetEntityLodDist(pickup, 1200)
    SetEntityInvincible(pickup, true)
    SetEntityProofs(pickup, true, true, false, true, true, true, true, false)
    SetObjectForceVehiclesToAvoid(pickup, true)
    FreezeEntityPosition(pickup, true)

    gooch.pickup = pickup

    Wait(1000)

    local options = {
        {
            name = 'gooch_gift',
            icon = 'fa-solid fa-gift',
            label = 'Pickup Present',
            onSelect = function(data)
                exports.ox_target:removeEntity(NetworkGetNetworkIdFromEntity(data.entity), {'Pickup Present'})
                lib.playAnim(cache.ped, grabDict, grabAnim, 8.0, -8.0, 1500, 01, 0.0, false, false, false)
                local success = lib.callback.await('randol_gooch:server:claimReward', false)
                if success then
                    playGoochAudio(pickup, 'De_Spawn')
                    table.wipe(gooch)
                end
            end,
            distance = 2.5
        }
    }
    exports.ox_target:addEntity(netid, options)
end)

RegisterNetEvent('randol_gooch:client:resetGooch', function()
    if GetInvokingResource() then return end
    DoNotification('The gooch got away with your shit, ggs.', 'error')
    table.wipe(gooch)

end)

