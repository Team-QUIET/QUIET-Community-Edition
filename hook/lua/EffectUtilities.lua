local PreviousCreateUEFBuildSliceBeams = CreateUEFBuildSliceBeams
local EntityBeenDestroyed = moho.entity_methods.BeenDestroyed

function CreateUEFBuildSliceBeams(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    -- The effect thread can start after cancellation or destruction of its target.
    if not(builder) or builder.Dead or EntityBeenDestroyed(builder)
            or not(unitBeingBuilt) or unitBeingBuilt.Dead or EntityBeenDestroyed(unitBeingBuilt) then
        return
    end
    return PreviousCreateUEFBuildSliceBeams(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
end
