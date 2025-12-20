@model(Config.ContentPropModel)
class SafeContent extends BaseEntity {
    OnSpawn = function()
        if IsClient then
            print("OnSpawn SafeContent (uNetId: ${self.id})")
            local offsetVector = vec3(0.0, 0.15, 1.025)
            local propCoords = GetOffsetFromEntityInWorldCoords(self.parent.obj, offsetVector)
            SetEntityRotation(self.obj, GetEntityRotation(self.parent.obj).xyz)
            FreezeEntityPosition(self.obj, true)
            SetEntityCoords(self.obj, propCoords.xyz)
            print('Changed coords of SafeContent to ${propCoords}')
        else
            print('OnSpawn of SafeContent (uNetId: ${tostring(self.id)}) | parent: ${type(self.parent)} (uNetId: ${self.parent.id})')
        end
    end,
}