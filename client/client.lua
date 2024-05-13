if Config.Target == "QB" then
    exports['qb-target']:AddTargetModel(Config.PropName, {
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
elseif Config.Target == "OX" then
    exports.ox_target:addModel(Config.PropName, {
        {
            name = "PlayPiano",
            event = "atiya-piano:client:openPiano",
            icon = "fa-solid fa-music",
            label = "Play Piano"
        }
    })
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
        local propHash = GetHashKey(Config.PropName)
        local nearestPropCandidate = GetClosestObjectOfType(sourcePlayerCoords, maxDistance, propHash, false, false, false)
        if nearestPropCandidate ~= 0 then
            local propCoords = GetEntityCoords(nearestPropCandidate)
            local propDistance = #(sourcePlayerCoords - propCoords)
            if propDistance < minDistance then
                minDistance = propDistance
                nearestProp = nearestPropCandidate
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
    local propHash = GetHashKey(Config.PropName)
    local nearestProp = GetClosestObjectOfType(playerCoords, maxDistance, propHash, false, false, false)
    if nearestProp ~= 0 then
        return true
    end
    return false
end

function GetNearestPianoLocation(coords)
    local nearestLocation = nil
    local minDistance = math.huge
    if Config.AllPianos then
        local propHash = GetHashKey(Config.PropName)
        local nearestProp = GetClosestObjectOfType(coords, tonumber(Config.AudioDistance), propHash, false, false, false)
        if nearestProp ~= 0 then
            local propCoords = GetEntityCoords(nearestProp)
            local distance = #(coords - propCoords)
            if distance < minDistance then
                minDistance = distance
                nearestLocation = { coords = vector4(propCoords.x, propCoords.y, propCoords.z, GetEntityHeading(nearestProp)), distance = tonumber(Config.AudioDistance), prop = propName }
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

function LoadVector4(vectorString)
    local x, y, z, w = vectorString:match("vector4%(([%-0-9%.]+), ([%-0-9%.]+), ([%-0-9%.]+), ([%-0-9%.]+)%)")
    return vector4(tonumber(x), tonumber(y), tonumber(z), tonumber(w))
end

Citizen.CreateThread(function()
    RequestModel(GetHashKey(Config.PropName))
    while true do
        Citizen.Wait(1000)
        if Config.AllPianos then
            local existingPianos = GetGamePool("CObject")
            for _, piano in ipairs(existingPianos) do
                local model = GetEntityModel(piano)
                if model == GetHashKey(Config.PropName) then
                else
                    DeleteObject(piano)
                end
            end
            local propHash = GetHashKey(Config.PropName)
            local pianoCoords = GetEntityCoords(GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 50.0, propHash, false, false, false))
            if not DoesObjectOfTypeExistAtCoords(pianoCoords, 0.5, propHash, true) then
                local pianoProp = CreateObject(propHash, pianoCoords, true, false, false)
                FreezeEntityPosition(pianoProp, true)
            end
            for _, pianoLocStr in ipairs(Config.PianoLocations) do
                local pianoLoc = LoadVector4(pianoLocStr)
                local propHash = GetHashKey(Config.PropName)
                if not DoesObjectOfTypeExistAtCoords(pianoLoc, 0.5, propHash, true) then
                    local pianoProp = CreateObject(propHash, pianoLoc.x, pianoLoc.y, pianoLoc.z, true, false, false)
                    SetEntityHeading(pianoProp, pianoLoc.w)
                    FreezeEntityPosition(pianoProp, true)
                end
            end
        else
            local existingPianos = GetGamePool("CObject")
            for _, piano in ipairs(existingPianos) do
                local model = GetEntityModel(piano)
                local shouldDelete = true
                for _, pianoLocStr in ipairs(Config.PianoLocations) do
                    local pianoLoc = LoadVector4(pianoLocStr)
                    if GetHashKey(Config.PropName) == model then
                        shouldDelete = false
                        break
                    end
                end
                if shouldDelete then
                    DeleteObject(piano)
                end
            end
            for _, pianoLocStr in ipairs(Config.PianoLocations) do
                local pianoLoc = LoadVector4(pianoLocStr)
                local propHash = GetHashKey(Config.PropName)
                if not DoesObjectOfTypeExistAtCoords(pianoLoc, 0.5, propHash, true) then
                    local pianoProp = CreateObject(propHash, pianoLoc.x, pianoLoc.y, pianoLoc.z, true, false, false)
                    SetEntityHeading(pianoProp, pianoLoc.w)
                    FreezeEntityPosition(pianoProp, true)
                end
            end
        end
    end
end)
