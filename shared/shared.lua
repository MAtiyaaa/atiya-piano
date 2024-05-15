local modelLoadTimeout = 1000

function requestModelCustom(model)
    if not HasModelLoaded(model) then
        if Config.Debug then 
            print("^5Debug^7: ^2Loading Model^7: '^6" .. model .. "^7'") 
        end
        RequestModel(model)
        local timeoutCounter = modelLoadTimeout
        while not HasModelLoaded(model) do
            if timeoutCounter > 0 then
                timeoutCounter = timeoutCounter - 1
            else
                timeoutCounter = modelLoadTimeout
                print("Debug: requestModelCustom: Timed out loading model '" .. model .. "'")
                break
            end
            Wait(10)
        end
    end
end

function releaseModelCustom(model)
    if Config.Debug then 
        print("Debug: Releasing Model: '" .. model .. "'") 
    end
    SetModelAsNoLongerNeeded(model)
end

function createCustomProp(data, shouldFreeze, shouldSync)
    requestModelCustom(data.prop)
    local createdProp = CreateObject(
        data.prop, 
        data.coords.x, 
        data.coords.y, 
        data.coords.z, 
        shouldSync or false, 
        shouldSync or false, 
        false
    )
    SetEntityHeading(createdProp, data.coords.w)
    FreezeEntityPosition(createdProp, shouldFreeze or false)
    if Config.Debug then
        local coordString = string.format(
            "vec4(%.2f, %.2f, %.2f, %.2f)", 
            data.coords.x, 
            data.coords.y, 
            data.coords.z, 
            data.coords.w or 0.0
        )
        print(string.format(
            "Debug: Prop Created: '%s' | Hash: '%s' | Coordinates: %s", 
            createdProp, 
            data.prop, 
            coordString
        ))
    end
    return createdProp
end
