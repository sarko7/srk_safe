function uuidv4()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local v = c == "x" ? math.random(0, 15) : math.random(8, 11)
        return string.format("%x", v)
    end)
end

function vec4ToTable(vec)
    return {vec.xyzw}
end

function tableToVec4(t)
    return vec4(t.x, t.y, t.z, t.w)
end

function LoadPhysicalSafe(position, ownerIdentifier, stashId, save)
    local coords = vec3(position.xyz)
    local rotZ = position.w
    local safe = UtilityNet.CreateEntity(Config.SafeModel, coords, {rotation = vec3(0.0,0.0, rotZ)})
    local state = UtilityNet.State(safe)
    local safeStashCfg = Config.SafeStash

    exports['ox_inventory']:RegisterStash(stashId, safeStashCfg.Label, safeStashCfg.NbSlots, safeStashCfg.MaxWeight, ownerIdentifier)
    state.stashId = stashId

    if save then
        SavePlayerSafe(position, ownerIdentifier, stashId, save)
    end

    return safe
end

function LoadPlayersSafes()
    local results = ExecuteSql('SELECT * FROM players_safes;')
    for k,v in pairs(results) do
        LoadPhysicalSafe(tableToVec4(json.decode(v.position)[1]), v.ownerIdenfifier, v.stashId, false)
    end
end

function SavePlayerSafe(position, playerIdentifier, stashId)
    local result = ExecuteSql('INSERT INTO players_safes VALUES (?, ?, ?);', {
        stashId,
        playerIdentifier,
        json.encode(vec4ToTable(position))
    })
end