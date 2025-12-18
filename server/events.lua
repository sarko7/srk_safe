function tableLength(t)
    local c = 0
    for k,v in pairs(t) do
        c += 1
    end
    return c
end
