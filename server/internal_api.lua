local _print = print
print = function(...)
    if Config.Debug then
        _print(...)
    end
end

fprint = function(func, ...)
    print("["..func.."]", ...)
end

RegisterServerCallback = function(name, cb)
    local handler = nil
    name = Config.Namespace..":ServerCallback:" .. name

    RegisterServerEvent(name)
    handler = AddEventHandler(name, function(...)
        local source = source
        
        -- For make the return of lua works
        local _cb = table.pack(cb(...))
            
        if _cb ~= nil then -- If the callback is not nil
            TriggerClientEvent(name, source, _cb) -- Trigger the client event
        end
    end)

    return handler
end

RegisterServerAction = function(name, cb, needReturn)
    if needReturn then
        RegisterServerCallback(name, cb)
    else
        RegisterServerEvent(Config.Namespace..name, cb)
    end
end

TriggerClientAction = function(name, source, ...)
    TriggerClientEvent(Config.Namespace..name, source, ...)
end