RegisterCommand('spawn', function(src, args)
    CreateObject(args[1], GetEntityCoords(PlayerPedId()))
end)