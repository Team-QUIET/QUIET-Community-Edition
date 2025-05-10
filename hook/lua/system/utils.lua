-- upvalue table operations for performance
local TableInsert = table.insert 
local TableGetn = table.getn 
local TableRemove = table.remove 
local TableSort = table.sort

--- Write all undefined keys from t2 into t1.
function table.assimilate(t1, t2)
    if not t2 then return t1 end -- prevent looping over nil table
    for k, v in t2 do
        if t1[k] == nil then
            t1[k] = v
        end
    end

    return t1
end

---Returns a random entry from an array
---@generic T
---@param array T[]
---@return T
function table.random(array)
    return array[Random(1, TableGetn(array))]
end