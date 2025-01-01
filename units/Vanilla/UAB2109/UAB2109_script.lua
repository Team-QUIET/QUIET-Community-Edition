local AStructureUnit = import('/lua/defaultunits.lua').StructureUnit

local AANChronoTorpedoWeapon = import('/lua/aeonweapons.lua').AANChronoTorpedoWeapon

UAB2109 = ClassUnit(AStructureUnit) {

    Weapons = {
        Turret01 = ClassWeapon(AANChronoTorpedoWeapon) {},
    },
	
	OnCreate = function(self)
		AStructureUnit.OnCreate(self)

        self.DomeEntity = import('/lua/sim/Entity.lua').Entity({Owner = self,})
        self.DomeEntity:AttachBoneTo( -1, self, 'UAB2109' )
        self.DomeEntity:SetMesh('/effects/Entities/UAB2109_Dome/UAB2109_Dome_mesh')
        self.DomeEntity:SetDrawScale(0.3)
        self.DomeEntity:SetVizToAllies('Intel')
        self.DomeEntity:SetVizToNeutrals('Intel')
        self.DomeEntity:SetVizToEnemies('Intel')         
        self.Trash:Add(self.DomeEntity)
	end,       
}

TypeClass = UAB2109