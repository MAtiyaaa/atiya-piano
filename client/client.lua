local spawnedPianos = {}
local propHash = GetHashKey(Config.PropName)
local benchHash = GetHashKey(Config.BenchName)
local occupiedPianos = {}

RegisterNetEvent('atiya-piano:spawnPiano')
AddEventHandler('atiya-piano:spawnPiano', function(coords, heading, propHash, benchHash)
    local pianoLoc = LoadVector4(coords)
    if not pianoLoc then
        if Config.Debug then
            print("Error: Invalid piano coordinates:", coords)
        end
        return
    end

    local pianoProp = createCustomProp({ 
        prop = propHash, 
        coords = pianoLoc, 
        heading = heading 
    }, true, false)

    local benchOffset = GetOffsetFromEntityInWorldCoords(pianoProp, 0.0, -1.5, 0.0)
    local benchProp = createCustomProp({ 
        prop = benchHash, 
        coords = vector4(
            benchOffset.x, 
            benchOffset.y, 
            benchOffset.z, 
            pianoLoc.w
        ) 
    }, true, false)

    spawnedPianos[coords] = {
        piano = pianoProp,
        bench = benchProp,
        distance = Config.AudioDistance,
        occupied = false,
        coords = pianoLoc
    }
    
    if Config.Debug then
        print("Client: Piano spawned at:", coords)
        print("Client: Bench spawned at:", vector4(benchOffset.x, benchOffset.y, benchOffset.z, pianoLoc.w))
    end
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
    exports['qb-target']:AddTargetModel(Config.BenchName, {
        options = {
            {
                type = "client",
                event = "atiya-piano:client:sitBench",
                icon = "fa-solid fa-chair",
                label = "Sit"
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
    exports.ox_target:addModel(Config.BenchName, {
        {
            name = "SitPianoBench",
            event = "atiya-piano:client:sitBench",
            icon = "fa-solid fa-chair",
            label = "Sit"
        }
    })
end

RegisterNetEvent('atiya-piano:deletePiano')
AddEventHandler('atiya-piano:deletePiano', function(coords)
    local pianoData = spawnedPianos[coords]
    if pianoData then
        if DoesEntityExist(pianoData.piano) then
            DeleteObject(pianoData.piano)
        end
        if DoesEntityExist(pianoData.bench) then
            DeleteObject(pianoData.bench)
        end
        spawnedPianos[coords] = nil
        if Config.Debug then
            print("Client: Piano & Bench deleted at:", coords)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for coords, _ in pairs(spawnedPianos) do
            TriggerEvent('atiya-piano:deletePiano', coords)
        end
        spawnedPianos = {}
    end
end)

Citizen.CreateThread(function()
    TriggerServerEvent('atiya-piano:requestPianos')
end)

RegisterNetEvent('atiya-piano:playNote')
AddEventHandler('atiya-piano:playNote', function(note, volume, coords)
    local soundId = "piano_" .. note
    local audiodistance = Config.AudioDistance
    local soundPath = "nui://xsound/html/sounds/" .. note .. ".ogg"
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

RegisterNetEvent('atiya-piano:client:openPiano')
AddEventHandler('atiya-piano:client:openPiano', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'showPiano' })
end)

RegisterNUICallback('closePiano', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hidePiano' })
    cb('ok')
end)

RegisterNetEvent('atiya-piano:client:sitBench')
AddEventHandler('atiya-piano:client:sitBench', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestPianoData = GetNearestPianoLocation(playerCoords)
    if nearestPianoData and not nearestPianoData.occupied then
        nearestPianoData.occupied = true
        sittingPlayer = playerPed
        local benchCoords = GetEntityCoords(nearestPianoData.bench)
        local benchHeading = GetEntityHeading(nearestPianoData.bench)
        TaskStartScenarioAtPosition(
            playerPed, 
            "PROP_HUMAN_SEAT_BENCH", 
            benchCoords.x, 
            benchCoords.y, 
            benchCoords.z + 0.5, 
            benchHeading, 0, 
            true, 
            true
        )
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(500)
                if IsControlJustReleased(0, 202) then
                    if sittingPlayer then
                        ClearPedTasks(sittingPlayer)
                        sittingPlayer = nil
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local nearestPiano = GetNearestPianoLocation(playerCoords)
                        if nearestPiano then
                            occupiedPianos[nearestPiano] = false
                        end
                        if Config.Debug then
                            print("Client: Player no longer sitting on the bench.")
                        end
                    end
                end
            end
        end)
        if Config.Debug then
            print("Client: Player sat on bench at:", nearestPianoData.coords)
        end
    end
end)

function GetNearestPianoLocation(coords)
    local nearestLocation = nil
    local minDistance = math.huge
    for locStr, pianoData in pairs(spawnedPianos) do
        local pianoLocation = LoadVector4(locStr)
        if pianoLocation then
            local distance = Vdist(coords.x, coords.y, coords.z, pianoLocation.x, pianoLocation.y, pianoLocation.z)
            if distance < minDistance then
                minDistance = distance
                nearestLocation = {
                    coords = pianoLocation, 
                    heading = pianoData.heading, 
                    piano = pianoData.piano, bench = 
                    pianoData.bench, occupied = 
                    pianoData.occupied
                }
            end
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
