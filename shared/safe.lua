@model(Config.SafeModel)
class Safe extends BaseEntity {
    safeCoords = nil,
    OnAwake = function(coords)
        if IsServer then
            print('OnAwake of Safe, only one safe is registered checking if called multiple time ')
            local safeContent = new SafeContent(vec3(0.0, 0.0, 0.0))
            self:addChild('content', safeContent)
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
        else
            self.state.hasContent = self:DoesSafeContainsItems()
            print("self:DoesSafeContainsItems()",self:DoesSafeContainsItems())
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

    @srpc
    UpdateContentDisplay = function(coords)
        local safeContent = self:getChild('content')
        if self.state.hasContent then
            safeContent:create(coords)
        else
            safeContent:destroy()
        end
    end,

    @state('hasContent')
    OnContentStateChange = function(value, _load)
        print("OnContentStateChange: ${tostring(value)}")
        self.server:UpdateContentDisplay(GetEntityCoords(self.obj))
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