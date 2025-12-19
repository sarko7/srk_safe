@model(Config.ContentPropModel)
class SafeContent extends BaseEntity {
    OnSpawn = function()
        if IsClient then
            print('OnSpawn executed for SafeContent, type of parent: ${type(self.parent)} uNetId: ${tostring(self.id)}')
            if not self.parent then
                return
            end

            local offsetVector = vec3(0.0, 0.15, 1.025)
            local propCoords = GetOffsetFromEntityInWorldCoords(self.parent.obj, offsetVector)
            SetEntityRotation(self.obj, GetEntityRotation(self.parent.obj).xyz)
            FreezeEntityPosition(self.obj, true)
            SetEntityCoords(self.obj, propCoords.xyz)
        else
            print('OnSpawn of SafeContent ${self.id} | parent: ${type(self.parent)} | parent id: ${self.parent.id}')
        end
    end,
}