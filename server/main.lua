RegisterCommand("usesafe", function(source, args)
    local playerPed = GetPlayerPed(source)
    local coords = GetEntityCoords(playerPed) + vec3(0.0, 1.0, -0.97)
    local rot = GetEntityRotation(playerPed)
    local position = vec4(coords.xyz, rot.z)
    local playerIdentifier = GetPlayerIdentifierByType(source, 'license')

    local stashId = uuidv4()
    LoadPhysicalSafe(position, playerIdentifier, stashId)
    SavePlayerSafe(position, playerIdentifier, stashId)
end)

filter CanPlayerOpenSafe(netId)
    UtilityNet.DoesUNetIdExist(netId) and UtilityNet.State(safe)?.stashId != nil else "Netid ${tostring(netId)} doesn't exist and/or stashId is nil"
end

Citizen.CreateThread(function()
    StartMySQL()
    LoadPlayersSafes()
end)