RegisterNetEvent('atiya-piano:PlayWithinDistance')
AddEventHandler('atiya-piano:PlayWithinDistance', function(maxDistance, note, volume)
    local src = source
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)

    TriggerClientEvent('atiya-piano:playSoundForNearby', -1, note, volume, playerCoords, src)
end)
