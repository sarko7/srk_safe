@model(Config.SafeModel)
class Safe extends BaseEntity {
    safeCoords = nil,
    OnRegister = function(coords)
        self.safeCoords = coords
    end,

    @crpc(true)
    GetSafeCoords = function()
        return self.safeCoords
    end,

    OnAwake = function()
        if IsServer then
            local safeContent = new SafeContent(vec3(.0, .0, .0))
            print('OnAwake type of SafeContent: ${type(safeContent)}')
            self:addChild('content', safeContent)
            local _safeContent = self.state.children['content']
            print('Checking if child is correct: ${type(_safeContent)}: ${tostring(_safeContent)}')
            -- print('Getting child diffderently: ${self:getChild()}')
            self:InitInventoryHook()
        end
    end,

    OnSpawn = function()
        if IsServer then
            local safeContent = self:getChild('content')
            -- safeContent.safeCoords
        else
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
                        distance = 1.5,
                        onSelect = function(data)
                            self:OpenSafeInventory()
                        end
                    }
                }
            })
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

    InitInventoryHook = function()
        if IsServer then
            local stashId = self.state.stashId
            Inventory.OnSwapItems(function(payload)
                if payload.action == 'stack' then
                    return true
                end

                local from = payload.fromInventory
                local to = payload.toInventory
                if from ~= stashId and to ~= stashId then
                    return true
                end

                local newState = to == stashId or DoesInventoryHasItems(stashId)
                self:HandleContentAppearance(payload.source, newState)
                print('onSwap updated "hasContent" state: ${tostring(self.state.hasContent)}')
                
            end)
        end
    end,

    HandleContentAppearance = function(requesterId, newState)
        if IsServer then
            local safeContent = self:getChild('content')
            if not safeContent then
                error("safeContent doesn't exists")
                return
            end

            -- print('Handling content appearance with state "hasContent" set to ${tostring(self.state.hasContent)}')
            
            if self.state.hasContent then
                safeContent:create(self.client.await:GetSafeCoords(requesterId))
            else
                safeContent:destroy()
            end

            self.state.hasContent = newState
        end
    end,

    @state('hasContent')
    OnContentUpdate = function(newValue, _load)
        if _load then
            -- print('initializing hasContent on load')
            return
        end

        print("ChildId: " .. tonumber(self.state.children['content']))
        local safeContent self:getChild('content')
        -- print('OnContentUpdate ${type(safeContent)}')
    end
}