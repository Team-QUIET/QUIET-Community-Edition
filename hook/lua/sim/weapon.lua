QCEWeapon = Weapon
Weapon = ClassWeapon(QCEWeapon) {
    -- this event is triggered at the moment that a weapon fires a shell
    CreateProjectileForWeapon = function(self, bone)

        local proj = LOUDCREATEPROJECTILE( self, bone )

        -- used for the retargeting feature
        proj.CreatedByWeapon = self

        proj.OriginalTarget = self:GetCurrentTarget()
        if proj.OriginalTarget.GetSource then
            proj.OriginalTarget = proj.OriginalTarget:GetSource()
        end
        
        if not proj.BlueprintID then
        
            local target
        
            while self and proj and not proj.BlueprintID do
            
                target = self:GetCurrentTarget()

                if target and not target.Dead then
            
                    WaitTicks(1)

                    proj = LOUDCREATEPROJECTILE( self, bone )
                else

                    -- the weapon has lost its target during firing
                    --LOG("*AI DEBUG Projectile for Weapon "..repr(self.bp.Label).." "..repr(bone).." failed at "..GetGameTick().." Weapon has target is "..repr(self:WeaponHasTarget()).." Current target is "..repr(target.BlueprintID).." Dead "..repr(target.Dead) )                                

                    break
                end
            end
        end
		
        if proj and not BeenDestroyed(proj) then

            if ScenarioInfo.ProjectileDialog then
                LOG("*AI DEBUG Weapon CreateProjectileForWeapon "..repr(self.bp.Label).." at bone "..repr(bone).." on tick "..GetGameTick() )
            end
            
            PassDamageData( proj, self.damageTable )
			
            if self.NukeWeapon then
			
                local bp = self.bp

                proj.Data = {
				
                    NukeInnerRingDamage = bp.NukeInnerRingDamage or 2000,
                    NukeInnerRingRadius = bp.NukeInnerRingRadius or 30,
                    NukeInnerRingTicks = bp.NukeInnerRingTicks or 5,
                    NukeInnerRingTotalTime = bp.NukeInnerRingTotalTime or 2,
					
                    NukeOuterRingDamage = bp.NukeOuterRingDamage or 10,
                    NukeOuterRingRadius = bp.NukeOuterRingRadius or 45,
                    NukeOuterRingTicks = bp.NukeOuterRingTicks or 20,
                    NukeOuterRingTotalTime = bp.NukeOuterRingTotalTime or 20,

                }

            end

        end
		
        return proj
    end,

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