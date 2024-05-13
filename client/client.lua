if Config.Target == "QB" then
    for _, pianoLoc in ipairs(Config.PropName) do
        exports['qb-target']:AddTargetModel(pianoLoc, {
            options = {
                {
                    type = "client",
                    event = "atiya-piano:client:openPiano",
                    icon = "fa-solid fa-music",
                    label = "Play Piano"
                }
            },
            distance = 2.5
        })
    end
elseif Config.Target == "OX" then
    for _, pianoLoc in ipairs(Config.PropName) do
        exports.ox_target:addModel(pianoLoc, {
            {
                name = "PlayPiano",
                event = "atiya-piano:client:openPiano",
                icon = "fa-solid fa-music",
                label = "Play Piano"
            }
        })
    end
end

RegisterNetEvent('atiya-piano:client:openPiano')
AddEventHandler('atiya-piano:client:openPiano', function()
    if IsNearConfiguredPiano() then
        SetNuiFocus(true, true)
        SendNUIMessage({type = 'showPiano'})
    else
        return
    end
end)

RegisterNUICallback('playPianoNote', function(data, cb)
    local note = data.note
    local volume = data.volume
    local maxDistance = tonumber(tonumber(Config.AudioDistance))

    TriggerServerEvent('atiya-piano:PlayWithinDistance', maxDistance, note, volume)
    cb('ok')
end)

RegisterNUICallback('playSound', function(data, cb)
    local soundFile = data.transactionFile
    local volume = data.transactionVolume

    SendNUIMessage({
        transactionType = 'playSound',
        transactionFile = soundFile,
        transactionVolume = volume
    })
    cb('ok')
end)

RegisterNetEvent('atiya-piano:playSoundForNearby')
AddEventHandler('atiya-piano:playSoundForNearby', function(note, volume, sourcePlayerCoords, sourcePlayer)
    local playerPed = PlayerPedId()
    local sourcePed = GetPlayerPed(GetPlayerFromServerId(sourcePlayer))
    local distance = #(GetEntityCoords(playerPed) - sourcePlayerCoords)
    local maxDistance = tonumber(Config.AudioDistance)
    local adjustedVolume = volume
    if Config.AllPianos then
        local nearestProp = nil
        local minDistance = math.huge
        for _, propName in ipairs(Config.PropName) do
            local propHash = GetHashKey(propName)
            local nearestPropCandidate = GetClosestObjectOfType(sourcePlayerCoords, maxDistance, propHash, false, false, false)
            if nearestPropCandidate ~= 0 then
                local propCoords = GetEntityCoords(nearestPropCandidate)
                local propDistance = #(sourcePlayerCoords - propCoords)
                if propDistance < minDistance then
                    minDistance = propDistance
                    nearestProp = nearestPropCandidate
                end
            end
        end
        if nearestProp ~= nil then
            local propCoords = GetEntityCoords(nearestProp)
            local propDistance = #(sourcePlayerCoords - propCoords)
            adjustedVolume = volume * (1 - (propDistance / 10.0))
        end
    else
        local nearestPianoLocation = GetNearestPianoLocation(sourcePlayerCoords)
        if nearestPianoLocation then
            local distance = #(sourcePlayerCoords - nearestPianoLocation.coords.xyz)
            local maxConfigDistance = nearestPianoLocation.distance
            adjustedVolume = volume * (1 - (distance / maxConfigDistance))
        end
    end
    local receiverDistance = #(GetEntityCoords(playerPed) - sourcePlayerCoords)
    adjustedVolume = adjustedVolume * (1 - (receiverDistance / maxDistance))
    if receiverDistance <= maxDistance then
        SendNUIMessage({
            transactionType = 'playSound',
            note = note,
            volume = adjustedVolume
        })
    end
end)

RegisterNUICallback('closePiano', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({type = 'hidePiano'})
    cb('ok')
end)

function IsNearConfiguredPiano()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local maxDistance = tonumber(Config.AudioDistance)

    for _, propName in ipairs(Config.PropName) do
        local propHash = GetHashKey(propName)
        local nearestProp = GetClosestObjectOfType(playerCoords, maxDistance, propHash, false, false, false)
        if nearestProp ~= 0 then
            return true
        end
    end
    return false
end

function GetNearestPianoLocation(coords)
    local nearestLocation = nil
    local minDistance = math.huge
    if Config.AllPianos then
        for _, propName in ipairs(Config.PropName) do
            local propHash = GetHashKey(propName)
            local nearestProp = GetClosestObjectOfType(coords, tonumber(Config.AudioDistance), propHash, false, false, false)
            if nearestProp ~= 0 then
                local propCoords = GetEntityCoords(nearestProp)
                local distance = #(coords - propCoords)
                if distance < minDistance then
                    minDistance = distance
                    nearestLocation = { coords = vector4(propCoords.x, propCoords.y, propCoords.z, GetEntityHeading(nearestProp)), distance = tonumber(Config.AudioDistance), prop = propName }
                end
            end
        end
    else
        for _, pianoLocation in ipairs(Config.PianoLocations) do
            local distance = #(coords - vector3(pianoLocation.coords.x, pianoLocation.coords.y, pianoLocation.coords.z))
            if distance < minDistance then
                minDistance = distance
                nearestLocation = pianoLocation
            end
        end
    end
    return nearestLocation
end

--RegisterCommand("debugPiano", function()
    --TriggerEvent('debugPianoEvent')
--end, false)


RegisterNetEvent('debugPianoEvent', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "startDebugging"
    })
end)

Citizen.CreateThread(function()
    for propName, _ in pairs(Config.PropName) do
        RequestModel(GetHashKey(propName))
    end
    while true do
        Citizen.Wait(1000)
        for _, propName in ipairs(Config.PropName) do
            local propHash = GetHashKey(propName)
            local existingPianos = GetGamePool("CObject")
            for _, piano in ipairs(existingPianos) do
                local model = GetEntityModel(piano)
                if model == propHash then
                    local pianoCoords = GetEntityCoords(piano)
                    if not DoesObjectOfTypeExistAtCoords(pianoCoords, 2.0, propHash, true) then
                        local pianoProp = CreateObject(propHash, pianoCoords, true, false, false)
                        FreezeEntityPosition(pianoProp, true)
                    end
                end
            end
        end
    end
end)
