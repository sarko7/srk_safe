@model(Config.SafeModel)
class Safe extends BaseEntity {
    OnAwake = function(coords)
        if IsServer then
            local safeContent = new SafeContent(coords)
            self:addChild('content', safeContent)
            print("SafeContent with uNetId ${tostring(safeContent.id)} was added as a child of Safe ${tonumber(self.id)} as 'content'")
        end
    end,

    OnSpawn = function()
        if IsClient then
            FreezeEntityPosition(self.obj, true)

            UniversalInteraction.AddLocalEntity(self.obj, {
                native = {
                    {
                        name = "open",
                        notify = "Press {E} to open",
                        action = function(entity, marker)
                            self:OpenSafeInventory()
                        end
                    }
                },
                target = {
                    {
                        name = "open",
                        label = "Ouvrir",
                        distance = 3.0,
                        onSelect = function(data)
                            self:OpenSafeInventory()
                        end
                    }
                }
            })

            print('Is children list empty ?: ${tostring(table.empty(self.state.children))}')
            for k,v in pairs(self.state.children) do
                print('Child name: ${k}, uNetId: ${v}')
            end
        else
            self.state.hasContent = self:DoesSafeContainsItems()
            self:InitContentHandleEvent()
        end
    end,

    OnDestroy = function()
        if IsClient then
            UniversalInteraction.RemoveLocalEntity(self.obj)
        end
    end,

    OpenSafeInventory = function()
        exports['ox_inventory']:openInventory('stash', self.state.stashId)
    end,

    @state('hasContent')
    OnContentStateChange = function(value, _load)
        local visibility = value ? 255 : 0
        print("OnContentStateChange: ${tostring(value)} | alpha: ${tostring(visibility)}")
        local safeContent = self:getChild('content')
        SetEntityAlpha(safeContent.obj, visibility)
    end,

    DoesSafeContainsItems = function()
        local stashContent = Inventory.GetInventory(self.state.stashId)
        return (not table.empty(stashContent.items))
    end,

    InitContentHandleEvent = function()
        AddEventHandler('ox_inventory:closedInventory', function(playerId, inventoryId)
            if inventoryId != self.state.stashId then
                return
            end

            self.state.hasContent = self:DoesSafeContainsItems()
        end)
    end
}

-- debug purpose
if IsClient then
    local lastProp = nil
    RegisterCommand('spawnProp', function(_, args)
        if lastProp then
            DeleteEntity(lastProp)
        end

        local model = args[1] or 'prop_alien_egg_01'
        lastProp = CreateObject(model, GetEntityCoords(PlayerPedId()) + GetEntityForwardVector(PlayerPedId()), false)
    end, false)
end