do
    local OldModBlueprints = ModBlueprints

    -- Load mod config
    local modConfig = {}
    for _, v in __active_mods do
        if v.uid == "abcdefg-fffe-fffe-fffe-24ehxst8372t" then
            modConfig = v.config
            break
        end
    end

    -- Get overspill factor from config
    local OVESPILL_MULTIPLIER = 0.0
    if modConfig['overspill_percent'] == '0' then
        local OVESPILL_MULTIPLIER = 0.0
    elseif modConfig['overspill_percent'] == '25' then
        local OVESPILL_MULTIPLIER = 0.25
    elseif modConfig['overspill_percent'] == '50' then
        local OVESPILL_MULTIPLIER = 0.50
    elseif modConfig['overspill_percent'] == '75' then
        local OVESPILL_MULTIPLIER = 0.75
    else
        local OVESPILL_MULTIPLIER = 1.00
    end

    -- Apply function to all blueprints
    function ModBlueprints(all_blueprints)
        OldModBlueprints(all_blueprints)
        AdjustShieldOverspill(all_blueprints)
    end

    -- Custom function to change damage overspill amount
    function AdjustShieldOverspill(all_blueprints)
        for _, bp in all_blueprints.Unit do
            local shield = bp.Defense and bp.Defense.Shield
            if shield then
                -- QUIET default is 0.15
                local base = shield.ShieldSpillOverDamageMod or 0.15
                shield.ShieldSpillOverDamageMod = base * OVESPILL_MULTIPLIER
            end
        end
    end
end
