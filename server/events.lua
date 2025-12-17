function tableLength(t)
    local c = 0
    for k,v in pairs(t) do
        c += 1
    end
    return c
end

RegisterServerEvent('srk_safe:Server:OpenSafe', function(uNetId) --using CanPlayerOpenSafe(source, uNetId)
    local state = UtilityNet.State(uNetId)
    state.hasContent = not state.hasContent
    print('Updated content state: ' .. tostring(state.hasContent))
end)
