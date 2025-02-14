do
    local OldModBlueprints = ModBlueprints
        
    function ModBlueprints(all_blueprints)
        
        OldModBlueprints(all_blueprints)

        UnitBalanceQCE(all_blueprints)
    end

    --=======================================
    -- FUNCTION UnitBalanceQCE(ALL_BLUEPRINTS)
    -- Overrall Unit Alterations that are changing vast amounts of the game.
    --=======================================

    function UnitBalanceQCE(all_blueprints)
    end
end -- do end