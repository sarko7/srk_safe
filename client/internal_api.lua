-- v1.1
--Server = {}

local _print = print
print = function(...)
    if Config.Debug then
        _print(...)
    end
end

fprint = function(func, ...)
    print("["..func.."]", ...)
end

TriggerServerCallback = function(name, ...)
    local p = promise.new()        
    local eventHandler = nil

    name = Config.Namespace..":ServerCallback:" .. name

    -- Register a new event to handle the callback from the server
    RegisterNetEvent(name)
    eventHandler = AddEventHandler(name, function(data)
        Citizen.SetTimeout(1, function()
            RemoveEventHandler(eventHandler)
        end)
        p:resolve(data)
    end)
    
    TriggerServerEvent(name, ...) -- Trigger the server event to get the data
    return table.unpack(Citizen.Await(p))
end

LoadServerAction = function(name, needReturn)
    if Server and Server.namespace then -- Already handled by objectify
        return
    elseif not Server then -- No objectify, create Server table
        Server = {}
    end

    if needReturn then
        Server[name] = function(...)
            return TriggerServerCallback(name, ...)
        end
    else
        Server[name] = function(...)
            TriggerServerEvent(Config.Namespace..name, ...)
        end
    end
end

RegisterClientAction = function(name, cb)
    RegisterNetEvent(Config.Namespace..name, cb)
end

local ConvertOptionForQBTarget = function(index, option)
    return {
        num = index,
        icon = option.icon,
        label = option.label,
        
        action = function(entity)
            if option.onSelect then
                option.onSelect({
                    coords = GetEntityCoords(entity),
                    entity = entity
                })
            end
        end,
        canInteract = function(entity, distance, data)
            if option.canInteract then
                return option.canInteract(entity, distance, GetEntityCoords(entity), option.name)
            else
                return true                
            end
        end
    }
end

local ConvertOptionsForQBTarget = function(options)
    local _opt = {
        options = {},
        distance = options.distance or 2.0
    }

    for k,v in pairs(options) do
        table.insert(_opt.options, ConvertOptionForQBTarget(k, v))
    end

    return _opt
end

Target = {
    isLoaded = function(self)
        return GetResourceState(Config.CustomTargetResource or "") ~= "missing" or GetResourceState("ox_target") ~= "missing" or GetResourceState("qb-target") ~= "missing"
    end,

    addModel = function(self, models, options)
        if Config.Functions and Config.Functions.TargetAddModel then
            Config.Functions.TargetAddModel(models, options)
        elseif GetResourceState("ox_target") ~= "missing" then
            exports["ox_target"]:addModel(models, options)
        elseif GetResourceState("qb-target") ~= "missing" then
            exports["qb-target"]:AddTargetModel(models, ConvertOptionsForQBTarget(options))
        else
            error("No target resource found, please dont use targets if you cant", 2)
        end
    end,
    addLocalEntity = function(self, entity, options)
        if Config.Functions and Config.Functions.TargetAddLocalEntity then
            Config.Functions.TargetAddLocalEntity(entity, options)
        elseif GetResourceState("ox_target") ~= "missing" then
            exports["ox_target"]:addLocalEntity(entity, options)
        elseif GetResourceState("qb-target") ~= "missing" then
            exports["qb-target"]:AddTargetEntity(entity, ConvertOptionsForQBTarget(options))
        else
            error("No target resource found, please dont use targets if you cant", 2)
        end
    end,
    removeLocalEntity = function(self, entity)
        if Config.Functions and Config.Functions.TargetRemoveLocalEntity then
            Config.Functions.TargetRemoveLocalEntity(entity)
        elseif GetResourceState("ox_target") ~= "missing" then
            exports["ox_target"]:removeLocalEntity(entity)
        elseif GetResourceState("qb-target") ~= "missing" then
            exports["qb-target"]:RemoveTargetEntity(entity)
        else
            error("No target resource found, please dont use targets if you cant", 2)
        end
    end
}