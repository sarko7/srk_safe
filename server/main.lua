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

RegisterCommand('checkIfExists', function(src, args)
    local uNetId = tonumber(args[1])
    print('Checking if uNetId ${tostring(uNetId)} exists')
    print(Entities.list[tostring(uNetId)] == nil)
    for _, obj in pairs(Entities.list) do
        if obj is SafeContent and obj.id == uNetId then
            print("uNetId ${tostring(uNetId)} exists on Entities.list (${tostring(obj.id)}) ? ${tostring(uNetId == obj.id)}")
        end
    end
end, false)