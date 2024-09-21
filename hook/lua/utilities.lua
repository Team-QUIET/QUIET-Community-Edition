function GetTrueEnemyUnitsInSphere(unit, position, radius, categories)
    local x1 = position.x - radius
    local y1 = position.y - radius
    local z1 = position.z - radius
    local x2 = position.x + radius
    local y2 = position.y + radius
    local z2 = position.z + radius
    local UnitsinRec = GetUnitsInRect(x1, z1, x2, z2)

    -- Check for empty rectangle
    if not UnitsinRec then
        return UnitsinRec
    end

    local RadEntities = {}
    for _, v in UnitsinRec do
        local dist = VDist3(position, v:GetPosition())
        local vArmy = v.Army
        -- The IsAlly errors in LOUD but not FAF unsure why?
        -- I assume the data structure is different inside the Unit so we need to figure out a way to compare the two armies
        if unit.Army ~= vArmy and --[[not IsAlly(unit.Army, vArmy) and]] dist <= radius and EntityCategoryContains(categories or categories.ALLUNITS, v) then
            table.insert(RadEntities, v)
        end
    end

    return RadEntities
end

function GetDistanceBetweenTwoEntities(entity1, entity2)
    return VDist3(entity1:GetPosition(), entity2:GetPosition())
end