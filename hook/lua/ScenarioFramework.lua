function ClearIntel(position, radius)
    local minX = position[1] - radius
    local maxX = position[1] + radius
    local minZ = position[3] - radius
    local maxZ = position[3] + radius
    FlushIntelInRect(minX, minZ, maxX, maxZ)
end