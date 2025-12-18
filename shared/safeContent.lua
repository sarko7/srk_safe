-- @model(Config.ContentPropModel, true)
@model(Config.ContentPropModel)
class SafeContent extends BaseEntity {
    OnSpawn = function()
        if IsClient then
            local parent = self.parent or self.root
            if not parent then
                print('No parent found ?')
            end

            FreezeEntityPosition(self.obj, true)
        end
    end,
}