local CStructureUnit = import('/lua/defaultunits.lua').StructureUnit
local CKrilTorpedoLauncherWeapon = import('/lua/cybranweapons.lua').CKrilTorpedoLauncherWeapon

XRB2308 = ClassUnit(CStructureUnit) {

    Weapons = {
        Turret01 = ClassWeapon(CKrilTorpedoLauncherWeapon) { FxMuzzleFlashScale = 0.5 },
    },

    OnStopBeingBuilt = function(self, builder, layer)

        CStructureUnit.OnStopBeingBuilt(self, builder, layer)

        self:StartSinkingFromBuild()

        local army = self.Army
        local bone = 'xrb2308'

        self.Trash:Add(CreateAttachedEmitter(self, bone, army, '/effects/emitters/tt_water02_footfall01_01_emit.bp'):ScaleEmitter(1.4))
        self.Trash:Add(CreateAttachedEmitter(self, bone, army, '/effects/emitters/tt_snowy01_landing01_01_emit.bp'):ScaleEmitter(1.5))

        ChangeState(self, self.IdleState)

    end,

    StartSinkingFromBuild = function(self)

        local pos = self:GetPosition()

        if GetSurfaceHeight(pos[1], pos[3]) > pos[2] then return end

        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', self.Army, '/effects/emitters/tt_water_submerge02_01_emit.bp'):ScaleEmitter(1.5))

        local proj = self:CreateProjectileAtBone('/projectiles/Sinker/Sinker_proj.bp', 0)

        self.sinkProjectile = proj
        proj:SetLocalAngularVelocity(0, 0, 0)
        proj:Start(0, self, 0)
        proj:SetBallisticAcceleration(-0.75)

        self.Trash:Add(proj)
        self.Trash:Add(ForkThread(self.DepthWatcher, self))

    end,

    DepthWatcher = function(self)

        self.sinkingFromBuild = true

        local sinkFor = 2.25

        while self.sinkProjectile and sinkFor > 0 do
            WaitTicks(1)
            sinkFor = sinkFor - 0.1
        end

        if not self.Dead then

            if self.sinkProjectile then
                self.sinkProjectile:Destroy()
                self.sinkProjectile = nil
            end

            self:SetPosition(self:GetPosition(), true)
            self:FinalAnimation()

        end

        self.sinkingFromBuild = false

    end,

    FinalAnimation = function(self)

        local bp = self.bp

        self.OpenAnim = CreateAnimator(self)
        self.OpenAnim:PlayAnim(bp.Display.AnimationDeploy)
        self.Trash:Add(self.OpenAnim)

        local pos = self:GetPosition()

        for _, army in self.SpottedByArmy or {} do
            VizMarker({ X = pos[1], Z = pos[3], Radius = 4, LifeTime = 0.3, Army = army, Vision = true })
        end

    end,
}

TypeClass = XRB2308
