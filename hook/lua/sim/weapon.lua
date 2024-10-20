QCEWeapon = Weapon
Weapon = Class(QCEWeapon) {

    ---@param self Weapon
    OnGotTarget = function(self)
        local animator = self.unit.Animator
        if self.DisabledFiringBones and animator then
            for _, value in self.DisabledFiringBones do
                animator:SetBoneEnabled(value, false)
            end
        end
    end,

    ---@param self Weapon
    OnLostTarget = function(self)
        local animator = self.unit.Animator
        if self.DisabledFiringBones and animator then
            for _, value in self.DisabledFiringBones do
                animator:SetBoneEnabled(value, true)
            end
        end
    end,
}