local propHash = GetHashKey(Config.PropName)
local benchHash = GetHashKey(Config.BenchName)
local spawnedPianos = {}

RegisterNetEvent('atiya-piano:playNote')
AddEventHandler('atiya-piano:playNote', function(note, volume, coords)
    TriggerClientEvent('atiya-piano:playNote', -1, note, volume, coords)
end)

function loadServerPianos()
    for _, pianoData in ipairs(Config.PianoLocations) do
        if not spawnedPianos[pianoData.coords] then
            spawnedPianos[pianoData.coords] = { coords = pianoData.coords, heading = pianoData.heading }
            TriggerClientEvent('atiya-piano:spawnPiano', -1, pianoData.coords, pianoData.heading, propHash, benchHash)
            if Config.Debug then
                print("Server: Piano data sent for spawning at:", pianoData.coords)
            end
        end
    end
end

function deleteServerPianos()
    for locStr, _ in pairs(spawnedPianos) do
        TriggerClientEvent('atiya-piano:deletePiano', -1, locStr)
        if Config.Debug then
            print("Server: Piano delete sent for:", locStr)
        end
    end
    spawnedPianos = {}
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadServerPianos()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deleteServerPianos()
    end
end)

RegisterNetEvent('atiya-piano:requestPianos')
AddEventHandler('atiya-piano:requestPianos', function()
    local _source = source
    for coords, pianoData in pairs(spawnedPianos) do
        TriggerClientEvent('atiya-piano:spawnPiano', _source, coords, pianoData.heading, propHash, benchHash)
    end
end)
