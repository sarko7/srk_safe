@model(Config.SafeModel)
class Safe extends BaseEntity {
    OnAwake = function()
        print('On awake executed')
        if IsServer then
            self:addChild('content', new SafeContent(vec3(.0, .0, .0)))
        end
    end,

    OnSpawn = function()
        print('On spawn executed')
        if IsServer then
            local safeContent = self:getChild('content')
            print("safeContent: " .. type(safeContent))
            return
        end

        UniversalInteraction.AddLocalEntity(self.obj, {
            native = {
                {
                    name = "open",
                    notify = "Press {E} to open",
                    action = function(entity, marker)
                        Server.OpenSafe(self.id)
                    end
                }
            },
            target = {
                {
                    name = "open",
                    label = "Ouvrir",
                    distance = 1.5,
                    onSelect = function(data)
                        Server.OpenSafe(self.id)
                    end
                }
            }
        })
    end,

    OnDestroy = function()
        if IsClient then
            UniversalInteraction.RemoveLocalEntity(self.obj)
        end
    end,

    @state('hasContent')
    OnContentUpdate = function(value, _load)
        if IsServer then
            local safeContent = self:getChild('content')
            if not safeContent then
                return
            end

            if value then
                safeContent:create()
                return
            end

            safeContent:destroy()
        end
    end
}