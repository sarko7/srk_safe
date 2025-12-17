-- v1.2
local NativeModels = {}
local NativeEntities = {}
local NativeInteractionLoopRunning = false

UniversalInteraction = {}

function NeedToUseTarget()
    if Config and Config.Target ~= nil then
        return Config.Target and Target:isLoaded()
    else
        return Target:isLoaded()
    end
end

function GetHigherDistance(options)
    local distance = 0

    for _,v in pairs(options) do
        if (v.interactionDistance or 0) > distance then
            distance = v.interactionDistance
        end

        if (v.renderDistance or 0) > distance then
            distance = v.renderDistance
        end

        if (v.distance or 0) > distance then
            distance = v.distance
        end
    end

    return distance
end

function CreateInteraction(pool, data)
    local key, interaction = table.find(pool, function(value) return value.obj == (data.obj or -1) or value.model == (data.model or -1) end)

    if type(data.model) == "string" then
        data.model = GetHashKey(data.model)
    end

    if not interaction then
        interaction = {
            obj = data.obj,
            model = data.model,
            options = data.options
        }

        table.insert(pool, interaction)
    else
        for k,v in pairs(data.options) do
            -- Remove if exists
            local _key,_value = table.find(interaction.options, function(value) return value.name == v.name end)

            if _value then
                table.remove(interaction.options, _key)
            end

            table.insert(interaction.options, v)
        end
    end

    interaction.maxDistance = GetHigherDistance(interaction.options)
    
    for k,v in pairs(interaction.options) do
        local model = data.model or GetEntityModel(data.obj)
        local id = "UI_"..model.."_"..v.name

        if DoesExist("marker", id) then
            DeleteMarker(id)
        end
        
        CreateMarker(id, vec3(0.0, 0.0, -100.0), v.renderDistance or 0.0, v.interactionDistance or 0.0, {
            notify = v.notify
        })
    end
end

function UpdateNativeInteractions(obj, tag, options)
    local model = GetEntityModel(obj)
    local player = GetEntityCoords(PlayerPedId())

    for _,v in pairs(options) do                
        local markerId = tag.."_"..model.."_"..v.name
        if not DoesExist("marker", markerId) then
            goto _continue
        end

        local markerCoords = GetCoordOf("marker", markerId)
        local newCoords = GetOffsetFromEntityInWorldCoords(obj, v.offset or vector3(0.0, 0.0, 0.0))

        if #(player - newCoords) < v.interactionDistance and (v.canInteract and {v.canInteract(obj, markerId)} or {true})[1] then
            -- NEED CHECK
            if GetFrom(markerId, "obj") ~= obj then
                SetFor(markerId, "obj", obj)
            end

            if #(markerCoords - newCoords) > 0.01 then
                SetMarkerCoords(markerId, newCoords)
                SetMarkerNotify(markerId, v.notify)
            end

            return true
        else
            if #(markerCoords - vec3(0.0, 0.0, -100.0)) > 0.01 then
                ClearAllHelpMessages()
                SetMarkerCoords(markerId, vec3(0.0, 0.0, -100.0))
            end
        end

        ::_continue::
    end

    return false
end

function GetEntitiesToCheck()
    local entities = {}
    local coords = GetEntityCoords(PlayerPedId())

    -- Add entity to entities if necessary
    local AddIfNecessary = function(entity, data)
        if not DoesEntityExist(entity) then
            return
        end

        local distance = #(coords - GetEntityCoords(entity))

        -- Only if in range
        if distance < data.maxDistance then
            table.insert(entities, {
                entity = entity,
                options = data.options,
                distance = distance
            })
        end
    end

    -- Loop models and entities
    for _,data in pairs(NativeModels) do
        local obj = GetClosestObjectOfType(coords, 20.0, data.model)

        if DoesEntityExist(obj) then
            AddIfNecessary(obj, data)
        end
    end

    for _,data in pairs(NativeEntities) do
        if DoesEntityExist(data.obj) then
            AddIfNecessary(data.obj, data)
        end
    end

    -- Sort by distance
    table.sort(entities, function(a, b)
        return a.distance < b.distance
    end)

    return entities
end

local entities = {}

On("marker", function(id)
    if not id:find("UI") then
        return
    end

    local model, option_name = id:match("UI_([%d%p]+)_(.*)")
    model = tonumber(model)

    local obj = GetFrom(id, "obj")
    
    if not option_name then
        error("Marker "..id.." is missing the option_name")
    end

    if not model then
        error("Marker "..id.." is missing the model")
    end
    
    if not DoesEntityExist(obj) then
        ClearAllHelpMessages()
        DeleteMarker(id)
        return
    end

    local _, v = table.find(entities, function(v) return v.entity == obj end)

    for i,v in pairs(v.options) do
        if v.name == option_name then
            v.action(obj, id)
            break
        end
    end
end)

function StartUniversalInteractionLoop()
    if NativeInteractionLoopRunning then
        return
    end
    NativeInteractionLoopRunning = true

    
    -- Update entities
    Citizen.CreateThread(function()
        while next(NativeModels) or next(NativeEntities) do
            entities = GetEntitiesToCheck()
            Citizen.Wait(3000)
        end
    end)

    Citizen.CreateThread(function()
        while next(NativeModels) or next(NativeEntities) do
            for _,v in pairs(entities) do
                local stop = UpdateNativeInteractions(v.entity, "UI", v.options)
                    
                if stop then
                    break
                end
            end

            Citizen.Wait(1000)
        end

        NativeInteractionLoopRunning = false
    end)
end

function GetInteraction(name)
    local names = {string.strsplit(".", name)}
    local interaction = Config.Interactions
    
    
    for _, v in pairs(names) do
        if _ == #names then
            v = v:match("(.*);") or v -- Ignore everything after the last ; (used for numeric thing in utility_kitchen)
        end
        
        if not interaction[v] then
            warn("Interaction "..tostring(v).." of ${json.encode(names)} does not exist in ${json.encode(interaction)}")
            break
        end
        
        interaction = interaction[v]
    end


    return interaction
end

function ConvertInteractionsWithConfig(options)
    if not Config.Interactions then
        return
    end

    if type(options.native) == "table" then
        for k,v in pairs(options.native) do
            local interaction = GetInteraction(v.name)

            if not v.notify or not v.interactionDistance then
                if not interaction then
                    error("Interaction "..v.name.." can be created since: there's no interaction config and nothing is defined")
                end
            end
            
            v.notify = v.notify or interaction.notify
            v.interactionDistance = v.interactionDistance or interaction.distance
        end
    end
    
    if type(options.target) == "table" then
        for k,v in pairs(options.target) do
            local interaction = GetInteraction(v.name)

            if not v.label or not v.icon or not v.distance then
                if not interaction then
                    error("Interaction "..v.name.." can be created since: there's no interaction config and nothing is defined")
                end
            end

            v.label = v.label or interaction.label
            v.icon = v.icon or interaction.icon
            v.distance = v.distance or interaction.distance

            if not v.noItems then
                v.items = v.items or interaction.items
            end
        end
    end
end

UniversalInteraction.AddModel = function(models, options)
    ConvertInteractionsWithConfig(options)

    if NeedToUseTarget() then
        Target:addModel(models, options.target)
    else
        if type(models) == "string" or type(models) == "number" then models = {models} end
        local options = options.native[1] and options.native or {options.native}

        for k,v in pairs(models) do
            CreateInteraction(NativeModels, {
                model = v,
                options = options
            })
        end

        StartUniversalInteractionLoop()
    end
end

UniversalInteraction.AddLocalEntity = function(entity, options)
    ConvertInteractionsWithConfig(options)

    if NeedToUseTarget() then
        Target:addLocalEntity(entity, options.target)
    else
        local options = options.native[1] and options.native or {options.native}

        CreateInteraction(NativeEntities, {
            obj = entity,
            options = options
        })

        StartUniversalInteractionLoop()
    end
end

UniversalInteraction.RemoveLocalEntity = function(entity)
    if NeedToUseTarget() then
        Target:removeLocalEntity(entity)
    else
        local model = GetEntityModel(entity)
        local key, interaction = table.find(NativeEntities, function(value)
            return value.obj == entity
        end)
        
        if not interaction then
            print("SKIPPING", entity, "SINCE NOT FOUND")
            return
        end
        
        for _,options in pairs(interaction.options) do
            local markerId = "UI_"..model.."_"..options.name
            DeleteMarker(markerId)
        end
    end
end