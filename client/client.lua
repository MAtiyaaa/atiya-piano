local spawnedPianos = {}
local propHash = GetHashKey(Config.PropName)

RegisterNetEvent('atiya-piano:spawnPiano')
AddEventHandler('atiya-piano:spawnPiano', function(coords, heading, propHash)
    local pianoLoc = LoadVector4(coords)
    local pianoProp = createCustomProp({prop = propHash, coords = pianoLoc, heading = heading}, true, false)
    spawnedPianos[coords] = { prop = pianoProp, distance = Config.AudioDistance }
    if Config.Debug then
        print("Client: Piano spawned at:", coords)
    end
end)

RegisterNetEvent('atiya-piano:deletePiano')
AddEventHandler('atiya-piano:deletePiano', function(coords)
    local pianoData = spawnedPianos[coords]
    if pianoData and DoesEntityExist(pianoData.prop) then
        DeleteObject(pianoData.prop)
        spawnedPianos[coords] = nil
        if Config.Debug then
            print("Client: Piano deleted at:", coords)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for coords, pianoData in pairs(spawnedPianos) do
            if DoesEntityExist(pianoData.prop) then
                DeleteObject(pianoData.prop)
                if Config.Debug then
                    print("Client: Piano deleted on resource stop at:", coords)
                end
            end
        end
        spawnedPianos = {}
    end
end)

Citizen.CreateThread(function()
    TriggerServerEvent('atiya-piano:requestPianos')
end)

RegisterNetEvent('atiya-piano:playNote')
AddEventHandler('atiya-piano:playNote', function(note, volume, coords)
    local soundPath = "nui://xsound/html/sounds/" .. note .. ".ogg"
    local soundId = "piano_" .. note
    local audiodistance = Config.AudioDistance
    exports.xsound:PlayUrlPos(soundId, soundPath, volume, coords, false)
    exports.xsound:Distance(soundId, audiodistance)
end)

RegisterNetEvent('atiya-piano:playNoteForEveryone')
AddEventHandler('atiya-piano:playNoteForEveryone', function(note, volume)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestPianoLocation = GetNearestPianoLocation(playerCoords)
    TriggerServerEvent('atiya-piano:playNote', note, volume, playerCoords)
end)

RegisterNUICallback('playPianoNote', function(data, cb)
    local note = data.note
    local volume = data.volume
    TriggerEvent('atiya-piano:playNoteForEveryone', note, volume)
    cb('ok')
end)

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
    SetNuiFocus(true, true)
    SendNUIMessage({type = 'showPiano'})
end)

RegisterNUICallback('closePiano', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({type = 'hidePiano'})
    cb('ok')
end)

function GetNearestPianoLocation(coords)
    local nearestLocation = nil
    local minDistance = math.huge
    for _, pianoData in ipairs(Config.PianoLocations) do
        local pianoLocation = LoadVector4(pianoData.coords)
        local distance = Vdist(coords.x, coords.y, coords.z, pianoLocation.x, pianoLocation.y, pianoLocation.z)
        if distance < minDistance then
            minDistance = distance
            nearestLocation = pianoLocation
        end
    end
    return nearestLocation
end

function LoadVector4(str)
    local x, y, z, w = str:match("([^,]+),%s*([^,]+),%s*([^,]+),%s*([^,]+)")
    if x and y and z and w then
        return vector4(tonumber(x), tonumber(y), tonumber(z), tonumber(w))
    else
        if Config.Debug then
            print("Failed to parse vector4 from string:", str)
        end
        return nil
    end
end

if Config.Debug then
    RegisterCommand("debugPiano", function()
        TriggerEvent('debugPianoEvent')
    end, false)
    RegisterNetEvent('debugPianoEvent', function()
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "startDebugging"
        })
    end)
end
