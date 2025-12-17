-- v1.0
local function DoesExportExists(...)
    local _ = {...}
    local success, ret = pcall(function() 
        local exp = exports
        for k,v in pairs(_) do
            exp = exp[v]
        end
    end)

    return success
end

local GetInventoryConfig = function(type)
    if not Config.Inventories[type] then
        error("Inventory type:"..type.." is not supported")
    end
    
    return Config.Inventories[type]
end

local StandardizeItem = function(item)
    return {
        name = item.name,
        label = item.label,
        slot = item.slot,
        count = item.count or item.amount,
        metadata = item.metadata or item.info
    }
end

RegisterUsableItem = function(frameworks, inv, item, func)
    if frameworks.qb and QBCore then
        QBCore.Functions.CreateUseableItem(item, function(source, item)
            func(source, StandardizeItem(item))
        end)
    elseif frameworks.esx and ESX then
        ESX.RegisterUsableItem(item, function(source, item, data)
            local _item = nil

            if type(item) == "table" then
                _item = item
            elseif type(data) == "table" then
                _item = data
            end

            func(source, StandardizeItem(_item))
        end)
    else
        error("registerUsableItem: ["..(frameworks.esx and "ESX or " or "")..(frameworks.qb and "QBCore" or "").."] are not loaded but using "..inv)
    end
end
----------

Config.Inventories = {
    ["qb-inventory"] = {
        registerInventory = function(self, id, label, slots, maxWeight, owner)
            if not DoesExportExists("qb-inventory", "RegisterInventory") then
                error("Please modify qb-inventory following this tutorial: https://docs.markz3d.com/other/installation-for-qb-inventory")
            end

            exports["qb-inventory"]:RegisterInventory(id, {
                label = label,
                slots = slots,
                maxweight = maxWeight,
                owner = owner
            })
        end,
        getInventory = function(self, id)
            if type(id) == "number" then
                if not QBCore then
                    error("getInventory: QBCore is not loaded but using qb-inventory")
                end

                local Player = QBCore.Functions.GetPlayer(id)
                local items = Player.PlayerData.items
            
                return items
            else
                local id = Inventory.Identifier.ToString(id)
            
                if not DoesExportExists("qb-inventory", "GetInventory") then
                    error("Please modify qb-inventory following this tutorial: https://docs.markz3d.com/other/installation-for-qb-inventory")
                end
    
                return exports["qb-inventory"]:GetInventory(id)
            end
        end,
        addItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports["qb-inventory"]:AddItem(id, item, count, slot, metadata)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports["qb-inventory"]:AddItem(id, item, count, slot, metadata)
            end
        end,
        removeItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports["qb-inventory"]:RemoveItem(id, item, count, slot)
            else
                id = Inventory.Identifier.ToString(id)

                if type(metadata) == "table" and not table.empty(metadata) then
                    warn("[qb-inventory] removeItem: metadata is ignored since current inventory does not support metadata filtering (this may lead to bugs)")
                end
    
                exports["qb-inventory"]:RemoveItem(id, item, count, slot)
            end
        end,
        getItemCount = function(self, id, item)
            if type(id) == "number" then
                return exports["qb-inventory"]:GetItemCount(id, item) or 0
            else
                id = Inventory.Identifier.ToString(id)

                local inv = exports["qb-inventory"]:GetInventory(id)
                local amount = 0
    
                if inv then
                    for k, v in pairs(inv.items) do
                        if type(item) == "table" then
                            if table.includes(item, v.name) then
                                amount = amount + v.amount
                            end
                        elseif type(item) == "string" then
                            if v.name == item then
                                amount = amount + v.amount
                            end
                        end
                    end 
                end
    
                return amount
            end
        end,
        serverOpenInventory = function(self, id)
            if not DoesExportExists("qb-inventory", "OpenInventoryWithOwner") then
                error("Please modify qb-inventory following this tutorial: https://docs.markz3d.com/other/installation-for-qb-inventory")
            end

            exports['qb-inventory']:OpenInventoryWithOwner(source, id)
        end,
        canCarryItem = function(self, id, item, count)
            if type(id) ~= "number" then
                error("[qb-inventory] canCarryItem: id must be a number")
            end

            return exports['qb-inventory']:CanAddItem(id, item, count)
        end,

        registerUsableItem = function(self, item, func)
            RegisterUsableItem({
                qb = true
            }, "qb-inventory", item, func)
        end,

        onSwapItems = function(self, cb, _filter)
            if not DoesExportExists("qb-inventory", "RegisterOnSwapItems") then
                error("Please modify qb-inventory following this tutorial: https://docs.markz3d.com/other/installation-for-qb-inventory")
            end

            exports['qb-inventory']:RegisterOnSwapItems(function(payload)
                --print("payload", json.encode(payload))
                if _filter.inventoryFilter then
                    local found = false

                    for k, v in pairs(_filter.inventoryFilter) do
                        if tostring(payload.fromInventory):find(v) or tostring(payload.toInventory):find(v) then
                            found = true
                            break
                        end
                    end

                    if not found then
                        return true
                    end
                end

                return cb(payload)
            end)
        end
    },
    ["ox_inventory"] = {
        registerInventory = function(self, id, label, slots, maxWeight, owner)
            id = Inventory.Identifier.ToString({id = id, owner = owner})

            exports.ox_inventory:RegisterStash(
                id, label, slots, maxWeight, 
                owner == true -- Handled directly using the id (to avoid conflicts with other inventories, just keep true being handled by ox_inventory)
            )
        end,
        getInventory = function(self, id)
            if type(id) == "number" then
                return exports.ox_inventory:GetInventoryItems(id)
            else
                id = Inventory.Identifier.ToString(id)
                
                return exports.ox_inventory:GetInventory(id)
            end
        end,
        addItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                return exports.ox_inventory:AddItem(id, item, count, metadata, slot)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports.ox_inventory:AddItem(id, item, count, metadata, slot)
            end
        end,
        removeItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports.ox_inventory:RemoveItem(id, item, count, metadata, slot)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports.ox_inventory:RemoveItem(id, item, count, metadata, slot)
            end
        end,
        getItemCount = function(self, id, item)
            if type(id) == "number" then
                return exports.ox_inventory:Search(id, "count", item) or 0
            else
                id = Inventory.Identifier.ToString(id)
    
                return exports.ox_inventory:Search(id, "count", item) or 0
            end
        end,
        canCarryItem = function(self, id, item, count)
            return exports.ox_inventory:CanCarryItem(id, item, count)
        end,
        registerUsableItem = function(self, item, func)
            RegisterUsableItem({
                qb = true,
                esx = true
            }, "ox_inventory", item, func)
        end,
        onSwapItems = function(self, cb, _filter)
            exports.ox_inventory:registerHook("swapItems", cb, _filter)
        end
    },
    ["qs-inventory"] = {
        use_base32 = true,

        registerInventory = function(self, id, label, slots, maxWeight, owner)
            -- QUASAR INVENTORY DOESNT HAVE SECURITY CHECKS FOR STASHES
            --id = Inventory.Identifier.ToString({id = id, owner = owner})
            --exports['qs-inventory']:RegisterStash(-1, id, slots, maxWeight) 
        end,
        getInventory = function(self, id)
            if type(id) == "number" then
                return exports['qs-inventory']:GetInventory(id)
            else
                id = Inventory.Identifier.ToString(id)
                
                return exports['qs-inventory']:GetStashItems(id)
            end
        end,
        addItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports['qs-inventory']:AddItem(id, item, count, slot, metadata)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports['qs-inventory']:AddItemIntoStash(id, item, count, slot, metadata)
            end
        end,
        removeItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports['qs-inventory']:RemoveItem(id, item, count, slot, metadata)
            else
                id = Inventory.Identifier.ToString(id)
    
                if type(metadata) == "table" and not table.empty(metadata) then
                    warn("[qs-inventory] removeItem: metadata is ignored since current inventory does not support metadata filtering (this may lead to bugs)")
                end
    
                exports['qs-inventory']:RemoveItemIntoStash(id, item, count, slot)
            end
        end,
        getItemCount = function(self, id, item)
            if type(id) == "number" then
                return exports['qs-inventory']:GetItemTotalAmount(id, item) or 0
            else
                id = Inventory.Identifier.ToString(id)

                local inv = exports["qs-inventory"]:GetStashItems(id)
                local amount = 0
    
                if inv and not table.empty(inv) then
                    for k, v in pairs(inv.items) do
                        if type(item) == "table" then
                            if table.includes(item, v.name) then
                                amount = amount + v.amount
                            end
                        elseif type(item) == "string" then
                            if v.name == item then
                                amount = amount + v.amount
                            end
                        end
                    end 
                end
    
                return amount
            end
        end,
        canCarryItem = function(self, id, item, count)
            if type(id) ~= "number" then
                error("[qs-inventory] CanCarryItem: id must be a number")
            end

            return exports['qs-inventory']:CanCarryItem(id, item, count)
        end,
        registerUsableItem = function(self, item, func)
            RegisterUsableItem({
                qb = true,
                esx = true
            }, "qs-inventory", item, func)
        end,
        onSwapItems = function(self, cb, _filter)
            warn("[qs-inventory] onSwapItems: NEED IMPLEMENTATION")
            --exports.ox_inventory:registerHook("swapItems", cb, filter)

            RegisterNetEvent("inventory:server:SetInventoryData", function(...)
                print(...)
            end)
        end
    },
    ["origen_inventory"] = {
        registerInventory = function(self, id, label, slots, maxWeight, owner)
            id = Inventory.Identifier.ToString({id = id, owner = owner})

            if type(owner) == "boolean" and owner == true then
                if not OrigenStashesOwners then
                    OrigenStashesOwners = {}
                end

                OrigenStashesOwners[id] = {
                    label = label,
                    slots = slots,
                    weight = maxWeight
                }
            end

            exports['origen_inventory']:RegisterStash(id, {
                label = label,
                slots = slots,
                weight = maxWeight,
            })
        end,
        getInventory = function(self, id)
            if type(id) == "number" then
                return exports['origen_inventory']:getInventory(id)
            else
                id = Inventory.Identifier.ToString(id)
                return exports['origen_inventory']:getInventory(id)
            end
        end,
        addItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports['origen_inventory']:addItem(id, item, count, metadata, slot)
            else
                id = Inventory.Identifier.ToString(id)
                exports['origen_inventory']:addItem(id, item, count, metadata, slot)
            end
        end,
        removeItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports['origen_inventory']:removeItem(id, item, count, metadata, slot)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports['origen_inventory']:removeItem(id, item, count, metadata, slot)
            end
        end,
        getItemCount = function(self, id, item)
            if type(id) == "number" then
                return exports["origen_inventory"]:getItemCount(id, item, false, true) or 0
            else
                id = Inventory.Identifier.ToString(id)

                local items = exports["origen_inventory"]:getItems(id)
                local amount = 0

                for k, v in pairs(items) do
                    if v.name == item then
                        amount = amount + v.amount
                    end
                end

                return amount
            end
        end,

        -- Local
        getItemBySlot = function(self, id, slot)
            if type(id) == "number" then
                local inventoryItems = exports.origen_inventory:getItems(id)

                local k, v = table.find(inventoryItems, function(item)
                    return item.slot == slot
                end)

                return v
            else
                id = Inventory.Identifier.ToString(id)
                local inventoryItems = exports.origen_inventory:getItems(id)

                local k, v = table.find(inventoryItems, function(item)
                    return item.slot == slot
                end)

                return v
            end
        end,

        generatePayload = function(self, source, fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
            local action = nil

            fromAmount = tonumber(fromAmount)
            toAmount = tonumber(toAmount)
            fromSlot = tonumber(fromSlot)
            toSlot = tonumber(toSlot)

            fromInventory = fromInventory == "player" and source or fromInventory
            toInventory = toInventory == "player" and source or toInventory

            local fromItem = self:getItemBySlot(fromInventory, fromSlot)
            local toItem = self:getItemBySlot(toInventory, toSlot)

            if toItem and (fromItem and fromItem.name) == (toItem and toItem.name) then
                action = "stack"
            elseif not toItem and (toAmount or 0) < fromAmount then
                action = "move"
            else
                if toItem then
                    action = "swap"
                else
                    action = "move"
                end
            end

            return {
                source = source,
                action = action,

                fromInventory = fromInventory,
                toInventory = toInventory,

                -- fromType and toType are not implemented!
                fromType = nil,
                toType = nil,

                fromSlot = fromItem or fromSlot,
                toSlot = toItem or toSlot,
                count = toAmount
            }
        end,

        ensureItemIsTable = function(self, inventory, item)
            if type(item) == "number" then
                item = self:getItemBySlot(inventory, item)
            end

            return item
        end,

        canCarryItem = function(self, id, item, count)
            if type(id) ~= "number" then
                error("[origen_inventory] canCarryItem: id must be a number")
            end

            return exports.origen_inventory:canCarryItem(id, item, count)
        end,

        registerUsableItem = function(self, item, func)
            RegisterUsableItem({
                qb = true,
                esx = true
            }, "origen_inventory", item, func)
        end,

        onSwapItems = function(self, cb, _filter)
            RegisterNetEvent("inventory:server:SetInventoryData", function(fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
                local source = source
                local payload = self:generatePayload(source, fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
                
                if _filter.inventoryFilter then
                    local found = false

                    for k, v in pairs(_filter.inventoryFilter) do
                        if tostring(payload.fromInventory):find(v) or tostring(payload.toInventory):find(v) then
                            found = true
                            break
                        end
                    end

                    -- skip callback if not found
                    if not found then
                        return
                    end
                end

                local res = cb(payload)

                if res == false then
                    TriggerClientEvent("MXC:Internal:OrigenCloseInventory", source)
                    Citizen.Wait(500)

                    local fromItem = self:ensureItemIsTable(payload.fromInventory, payload.fromSlot)
                    local toItem = self:ensureItemIsTable(payload.toInventory, payload.toSlot)
                    local amount = tonumber(toAmount or fromAmount)
                    
                    self:removeItem(payload.toInventory, toItem.name, amount, nil, toItem.slot)
                    self:addItem(payload.fromInventory, fromItem.name, amount, nil, fromItem.slot)

                    if type(payload.toInventory) ~= "number" then
                        exports.origen_inventory:OpenInventory(source, 'stash', payload.toInventory)
                    end
                end
            end)
        end
    },
    ["core_inventory"] = {
        no_special_characters = true,

        registerInventory = function(self, id, label, slots, maxWeight, owner)
            id = Inventory.Identifier.ToString({id = id, owner = owner})

            print(id)
            exports.core_inventory:openInventory(nil, id, 'stash', 60, 0, false, nil, false)
        end,
        getInventory = function(self, id)
            if type(id) == "number" then
                return exports.core_inventory:getInventory(id)
            else
                id = Inventory.Identifier.ToString(id)
                
                return exports.core_inventory:getInventory(id)
            end
        end,
        addItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                return exports.core_inventory:addItem(id, item, count, metadata)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports.core_inventory:addItem(id, item, count, metadata, "stash")
            end
        end,
        removeItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports.core_inventory:removeItem(id, item, count)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports.core_inventory:removeItem(id, item, count, "stash")
            end
        end,
        getItemCount = function(self, id, item)
            if type(id) == "number" then
                return exports.core_inventory:getItemCount(id, item) or 0
            else
                id = Inventory.Identifier.ToString(id)
    
                return exports.core_inventory:getItemCount(id, item) or 0
            end
        end,
        canCarryItem = function(self, id, item, count)
            return exports.core_inventory:canCarry(id, item, count)
        end,
        registerUsableItem = function(self, item, func)
            RegisterUsableItem({
                qb = true,
                esx = true
            }, "core_inventory", item, func)
        end,


        findSlotById = function(self, inventory, id)
            for _, item in pairs(inventory) do
                if item.ids then
                    local k,v = table.find(item.ids, function(v) return v == id end)

                    if k then
                        return item.slots[k]
                    end
                else
                    if item.id == id then
                        return item.slot
                    end
                end
            end
        end,

        moveItemInInventory = function(self, source, itemInfo, inventory)
            TriggerClientEvent("MXC:Internal:CoreMoveItem", source, itemInfo.id, inventory, itemInfo.slot, inventory, itemInfo, true)
        end,

        getStash = function(self, from, to)
            return from:find("content-") ? to : from
        end,

        generatePayload = function(self, source, fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
            local action = nil

            fromAmount = tonumber(fromAmount)
            toAmount = tonumber(toAmount)
            fromSlot = tonumber(fromSlot)
            toSlot = tonumber(toSlot)

            local fromItem = exports.core_inventory:getItemBySlot(fromInventory, fromSlot)
            local toItem = exports.core_inventory:getItemBySlot(toInventory, toSlot)

            fromInventory = fromInventory:find("content-") and source or fromInventory
            toInventory = toInventory:find("content-") and source or toInventory


            return {
                source = source,
                action = "move",

                fromInventory = fromInventory,
                toInventory = toInventory,

                -- fromType and toType are not implemented!
                fromType = nil,
                toType = nil,

                fromSlot = fromItem or fromSlot,
                toSlot = toItem or toSlot,
                count = toAmount
            }
        end,

        onSwapItems = function(self, cb, _filter)
            RegisterNetEvent("core_inventory:server:changeItemLocation", function(itemId, toInv, toSlot, fromInv, itemData, invokedByServer)
                local source = source

                if invokedByServer then
                    return
                end

                if _filter.inventoryFilter then
                    local found = false
                
                    for k, v in pairs(_filter.inventoryFilter) do
                        if tostring(fromInv):find(v) or tostring(toInv):find(v) then
                            found = true
                            break
                        end
                    end
                
                    -- skip callback if not found
                    if not found then
                        return
                    end
                end

                local from = exports.core_inventory:getInventory(fromInv)
                local fromItemSlot = self:findSlotById(from, itemData.id)

                local payload = self:generatePayload(source, fromInv, toInv, fromItemSlot, toSlot, itemData.amount, itemData.amount)
                local res = cb(payload)

                if res == false then
                    print("Move item ${itemData.id} from ${fromInv} to ${toInv} slot ${toSlot}")
                    print("itemData", itemData.id, itemData.slot)

                    Player(source).state.invBusy = true
                    TriggerClientEvent("core_inventory:client:closeInventory", source)
                    Citizen.Wait(100)
    
                    -- Remove item from: toinventory
    
                    print("Removing item ${itemData.amount}x ${itemData.id} from "..toInv)
                    exports.core_inventory:removeItemExact(toInv, itemData.id, itemData.amount)

                    -- Add and move to correct slot of frominventory
                    print("Adding item ${itemData.amount}x ${itemData.name} to ${fromInv}")

                    local itemAdded = exports.core_inventory:addItem(fromInv, itemData.name, itemData.amount, itemData.metadata, "stash")[1]
                    print("Newly added item id ${itemAdded.id} to slot ${itemAdded.slot}")
                    itemAdded.slot = fromItemSlot
                    print("Setting new slot to ${itemAdded.slot}")
    
                    self:moveItemInInventory(source, itemAdded, fromInv)

                    Citizen.Wait(600)
                    
                    -- Reopen inventory
                    Player(source).state.invBusy = false
                    Citizen.Wait(50)
                    
                    local stash = self:getStash(fromInv, toInv)
                    exports.core_inventory:openInventory(source, stash, 'stash', nil, nil, true, nil, false)
                end
            end)
        end
    },

    ["codem-inventory"] = {
        registerInventory = function(self, id, label, slots, maxWeight, owner)
            id = Inventory.Identifier.ToString({id = id, owner = owner})

            print(id)
            exports.core_inventory:openInventory(nil, id, 'stash', 60, 0, false, nil, false)
        end,
        getInventory = function(self, id)
            if type(id) == "number" then
                return exports.core_inventory:getInventory(id)
            else
                id = Inventory.Identifier.ToString(id)
                
                return exports.core_inventory:getInventory(id)
            end
        end,
        addItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                return exports.core_inventory:addItem(id, item, count, metadata)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports.core_inventory:addItem(id, item, count, metadata, "stash")
            end
        end,
        removeItem = function(self, id, item, count, metadata, slot)
            if type(id) == "number" then
                exports.core_inventory:removeItem(id, item, count)
            else
                id = Inventory.Identifier.ToString(id)
    
                exports.core_inventory:removeItem(id, item, count, "stash")
            end
        end,
        getItemCount = function(self, id, item)
            if type(id) == "number" then
                return exports.core_inventory:getItemCount(id, item) or 0
            else
                id = Inventory.Identifier.ToString(id)
    
                return exports.core_inventory:getItemCount(id, item) or 0
            end
        end,
        canCarryItem = function(self, id, item, count)
            return exports.core_inventory:canCarry(id, item, count)
        end,
        registerUsableItem = function(self, item, func)
            RegisterUsableItem({
                qb = true,
                esx = true
            }, "core_inventory", item, func)
        end,


        findSlotById = function(self, inventory, id)
            for _, item in pairs(inventory) do
                if item.ids then
                    local k,v = table.find(item.ids, function(v) return v == id end)

                    if k then
                        return item.slots[k]
                    end
                else
                    if item.id == id then
                        return item.slot
                    end
                end
            end
        end,

        moveItemInInventory = function(self, source, itemInfo, inventory)
            TriggerClientEvent("MXC:Internal:CoreMoveItem", source, itemInfo.id, inventory, itemInfo.slot, inventory, itemInfo, true)
        end,

        getStash = function(self, from, to)
            return from:find("content-") ? to : from
        end,

        generatePayload = function(self, source, fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
            local action = nil

            fromAmount = tonumber(fromAmount)
            toAmount = tonumber(toAmount)
            fromSlot = tonumber(fromSlot)
            toSlot = tonumber(toSlot)

            local fromItem = exports.core_inventory:getItemBySlot(fromInventory, fromSlot)
            local toItem = exports.core_inventory:getItemBySlot(toInventory, toSlot)

            fromInventory = fromInventory:find("content-") and source or fromInventory
            toInventory = toInventory:find("content-") and source or toInventory


            return {
                source = source,
                action = "move",

                fromInventory = fromInventory,
                toInventory = toInventory,

                -- fromType and toType are not implemented!
                fromType = nil,
                toType = nil,

                fromSlot = fromItem or fromSlot,
                toSlot = toItem or toSlot,
                count = toAmount
            }
        end,

        onSwapItems = function(self, cb, _filter)
            RegisterNetEvent("core_inventory:server:changeItemLocation", function(itemId, toInv, toSlot, fromInv, itemData, invokedByServer)
                local source = source

                if invokedByServer then
                    return
                end

                if _filter.inventoryFilter then
                    local found = false
                
                    for k, v in pairs(_filter.inventoryFilter) do
                        if tostring(fromInv):find(v) or tostring(toInv):find(v) then
                            found = true
                            break
                        end
                    end
                
                    -- skip callback if not found
                    if not found then
                        return
                    end
                end

                local from = exports.core_inventory:getInventory(fromInv)
                local fromItemSlot = self:findSlotById(from, itemData.id)

                local payload = self:generatePayload(source, fromInv, toInv, fromItemSlot, toSlot, itemData.amount, itemData.amount)
                local res = cb(payload)

                if res == false then
                    print("Move item ${itemData.id} from ${fromInv} to ${toInv} slot ${toSlot}")
                    print("itemData", itemData.id, itemData.slot)

                    Player(source).state.invBusy = true
                    TriggerClientEvent("core_inventory:client:closeInventory", source)
                    Citizen.Wait(100)
    
                    -- Remove item from: toinventory
    
                    print("Removing item ${itemData.amount}x ${itemData.id} from "..toInv)
                    exports.core_inventory:removeItemExact(toInv, itemData.id, itemData.amount)

                    -- Add and move to correct slot of frominventory
                    print("Adding item ${itemData.amount}x ${itemData.name} to ${fromInv}")

                    local itemAdded = exports.core_inventory:addItem(fromInv, itemData.name, itemData.amount, itemData.metadata, "stash")[1]
                    print("Newly added item id ${itemAdded.id} to slot ${itemAdded.slot}")
                    itemAdded.slot = fromItemSlot
                    print("Setting new slot to ${itemAdded.slot}")
    
                    self:moveItemInInventory(source, itemAdded, fromInv)

                    Citizen.Wait(600)
                    
                    -- Reopen inventory
                    Player(source).state.invBusy = false
                    Citizen.Wait(50)
                    
                    local stash = self:getStash(fromInv, toInv)
                    exports.core_inventory:openInventory(source, stash, 'stash', nil, nil, true, nil, false)
                end
            end)
        end
    },
}

if Config.Functions.LoadInventoryForResource then
    for i=0, GetNumResources() do
        local resource = GetResourceByFindIndex(i)
        if resource then
            local ret = Config.Functions.LoadInventoryForResource(resource)

            if ret then
                Config.Inventories[resource] = ret
            end
        end
    end
end

----------

local inventoryType = ""

for k,v in pairs(Config.Inventories) do
    if GetResourceState(k):find("start") then
        inventoryType = k
        break
    end
end

----------

--#region Inject new exports
local InjectExport = function(resource, path, text)
    local file = LoadResourceFile(resource, path)
                
    file = file .."\n-- Injected by "..GetCurrentResourceName().." ["..os.date("%c").."]\n"
    file = file .. text

    SaveResourceFile(resource, path, file)
end

local invConfig = GetInventoryConfig(inventoryType)

local Install = function()
    local hooked = false
    local injected = false

    if invConfig.hooks then
        for k,v in pairs(invConfig.hooks) do
            local file = LoadResourceFile(inventoryType, v.path)
    
            if file then
                if not file:find(v.id) then
                    print("^2"..k.." installed!.^0")
                    file = file:gsub(v.sig, "-- Injected by "..GetCurrentResourceName().." ["..os.date("%c").."] ("..v.id..")\n"..v.hook.."\n"..v.sig)
                    
                    SaveResourceFile(inventoryType, v.path, file)
                else
                    print("^1"..k.." is already installed!.^0")
                end
            end
        end
    
        if hooked then
            if invConfig.onSomethingHooked then
                invConfig.onSomethingHooked()
            end
        end
    end
    
    if invConfig.exports then
        for k,v in pairs(invConfig.exports) do
            if not DoesExportExists(inventoryType, k) then
                InjectExport(inventoryType, v.path, v.text)
                injected = true
                print("^2"..k.." installed!.^0")
            else
                print("^1"..k.." is already installed!.^0")
            end
        end
    
        if injected then
            if invConfig.onSomethingInjected then
                invConfig.onSomethingInjected()
            end
        end
    end

    if injected or hooked then
        print("")
        Citizen.CreateThread(function()
            while true do
                print("^3We have installed some components for "..inventoryType..", please restart the server.^0")
                Citizen.Wait(5000)
            end
        end)
    end
end
--#endregion

RegisterNetEvent("MXC:Internal:OpenInventory", function(identifier)
    invConfig:serverOpenInventory(identifier)
end)

local b32chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
local b32lookup = {}

-- Create a lookup table to speed up decoding
for i = 1, #b32chars do
    b32lookup[b32chars:sub(i, i)] = i - 1
end

local function to_base32(input)
    local output = {}
    local len = #input
    local i = 1
    local buffer = 0
    local bitsLeft = 0

    while i <= len do
        local byte = string.byte(input, i)
        i = i + 1

        buffer = (buffer << 8) | byte  -- Shift left by 8 bits and add new byte
        bitsLeft = bitsLeft + 8

        while bitsLeft >= 5 do
            bitsLeft = bitsLeft - 5
            local index = ((buffer >> bitsLeft) & 0x1F) + 1
            table.insert(output, b32chars:sub(index, index))
        end
    end

    -- Handle padding for the last few bits
    if bitsLeft > 0 then
        buffer = (buffer << (5 - bitsLeft)) & 0x1F  -- Shift remaining bits to the left
        local index = (buffer & 0x1F) + 1
        table.insert(output, b32chars:sub(index, index))
    end

    return table.concat(output)
end

local function from_base32(input)
    local output = {}
    local buffer = 0
    local bitsLeft = 0

    for i = 1, #input do
        local char = input:sub(i, i)
        local value = b32lookup[char]

        if value then
            buffer = (buffer << 5) | value  -- Shift buffer and add new value
            bitsLeft = bitsLeft + 5

            -- Extract bytes when we have enough bits
            while bitsLeft >= 8 do
                bitsLeft = bitsLeft - 8
                local byte = (buffer >> bitsLeft) & 0xFF
                table.insert(output, string.char(byte))
            end
        end
    end

    return table.concat(output)
end

Inventory = {
    ---@param identifier string|table|number The identifier of the inventory or the player server id (table: {id = id, owner = owner})
    ---@return table If a stash the stash data, if a player inventory the inventory items
    GetInventory = function(identifier)
        return invConfig:getInventory(identifier)
    end,

    ---@param identifier string|table|number The identifier of the inventory or the player server id (table: {id = id, owner = owner})
    ---@param label string The label of the inventory
    ---@param slots number The amount of slots the inventory has
    ---@param maxWeight number The maximum weight of the inventory
    ---@param owner string|boolean The owner of the inventory, if true then the inventory is a player inventory
    ---Registers a new inventory
    RegisterInventory = function(identifier, label, slots, maxWeight, owner)
        return invConfig:registerInventory(identifier, label, slots, maxWeight, owner)
    end,

    ---@param identifier string|table|number The identifier of the inventory or the player server id (table: {id = id, owner = owner})
    ---@param item string The name of the item
    ---@return number The amount of the item in the inventory
    GetItemCount = function(identifier, item)
        return invConfig:getItemCount(identifier, item)
    end,

    ---@param identifier string|table|number The identifier of the inventory or the player server id (table: {id = id, owner = owner})
    ---@param item string The name of the item
    ---@return boolean Whether the item exists in the inventory
    HaveItem = function(identifier, item)
        return invConfig:getItemCount(identifier, item) > 0
    end,

    ---@param identifier string|table|number The identifier of the inventory or the player server id (table: {id = id, owner = owner})
    ---@param item string The name of the item
    ---@param count number The amount of the item
    ---@param metadata table The metadata of the item
    ---@param slot number The slot of the item
    AddItem = function(identifier, item, count, metadata, slot)
        if type(identifier) == "number" and Config.Functions.AddItem then
            Config.Functions.AddItem(identifier, item, count, metadata or {}, slot)
            return
        end

        invConfig:addItem(identifier, item, count, metadata, slot)
    end,

    ---@param identifier string|table|number The identifier of the inventory or the player server id (table: {id = id, owner = owner})
    ---@param item string The name of the item
    ---@param count number The amount of the item
    ---@param metadata table The metadata of the item
    ---@param slot number The slot of the item
    RemoveItem = function(identifier, item, count, metadata, slot)
        if type(identifier) == "number" and Config.Functions.RemoveItem then
            Config.Functions.RemoveItem(identifier, item, count, metadata or {}, slot)
            return
        end

        invConfig:removeItem(identifier, item, count, metadata, slot)
    end,

    ---@param identifier string|table|number The identifier of the inventory or the player server id (table: {id = id, owner = owner})
    ---@param item string The name of the item
    ---@param count number The amount of the items
    CanCarryItem = function(identifier, item, count)
        return invConfig:canCarryItem(identifier, item, count)
    end,

    RegisterUsableItem = function(item, func)
        if Config.Functions.RegisterUsableItem then
            Config.Functions.RegisterUsableItem(item, func)
            return
        end

        invConfig:registerUsableItem(item, func)
    end,

    ---@param cb function The callback function that will be called when an item is swapped
    ---@param filter table The filter that will be used for the callback (supports only inventoryFilter)
    OnSwapItems = function(cb, _filter)
        invConfig:onSwapItems(cb, _filter)
    end,

    Identifier = {
        ---@param inventory string|table|number The identifier of the inventory or the player server id, numbers will not be converted (table: {id = id, owner = owner})
        ---@return table The inventory identfier {id = id, owner = owner}
        ToTable = function(inventory)
            if type(inventory) == "string" then
                if invConfig.use_base32 then
                    inventory = from_base32(inventory)
                end

                if inventory:find(":") then
                    local id, owner = inventory:match("(.+):(.+)")

                    return {
                        id = id,
                        owner = owner
                    }
                elseif invConfig.no_special_characters and inventory:find("-divisor-") then
                    local id, owner = inventory:match("(.+)%-divisor%-(.+)")

                    return {
                        id = id,
                        owner = owner
                    }
                end
            end
        
            if type(inventory) == "table" or type(inventory) == "number" then
                return inventory
            end

            error("Inventory.Identifier.ToTable: Invalid inventory identifier "..tostring(inventory).." - "..type(inventory))
            return nil
        end,

        ---@param inventory string|table|number The identifier of the inventory or the player server id, numbers will not be converted (table: {id = id, owner = owner})
        ---@return string The inventory identifier (id:owner)
        ToString = function(inventory)
            if type(inventory) == "table" then
                if inventory.owner and type(inventory.owner) ~= "boolean" then
                    inventory = inventory.id..":"..tostring(inventory.owner)
                else
                    inventory = inventory.id
                end
            end
            
            if type(inventory) == "string" or type(inventory) == "number" then
                if invConfig.no_special_characters then
                    inventory = inventory:gsub(":", "-divisor-")
                    inventory = inventory:gsub("%.", "_")
                elseif invConfig.use_base32 then
                    inventory = to_base32(inventory)
                end

                return inventory
            end

            error("Inventory.Identifier.ToString: Invalid inventory identifier "..tostring(inventory).." - "..type(inventory))
            return nil 
        end,

        GetSeparator = function()
            if invConfig.no_special_characters then
                return "-divisor-"
            else
                return ":"
            end
        end
    }
}

RegisterCommand("install_stash", function(source, args)
    if source ~= 0 then
        return
    end

    if args[1] == GetCurrentResourceName() then
        Install()
    end
end)