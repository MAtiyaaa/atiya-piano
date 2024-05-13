RegisterNetEvent('atiya-piano:PlayWithinDistance')
AddEventHandler('atiya-piano:PlayWithinDistance', function(maxDistance, note, volume)
    local src = source
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)

    TriggerClientEvent('atiya-piano:playSoundForNearby', -1, note, volume, playerCoords, src)
end)

RegisterNetEvent('atiya-piano:StopPlayingPiano')
AddEventHandler('atiya-piano:StopPlayingPiano', function()
    local src = source
    TriggerClientEvent('atiya-piano:StopPlayingPianoForNearby', -1, src)
end)