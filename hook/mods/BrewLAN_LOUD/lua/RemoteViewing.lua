local QuietPreviousRemoteViewing = RemoteViewing

function RemoteViewing(SuperClass)
    local Previous = QuietPreviousRemoteViewing(SuperClass)
    return Class(Previous) {
        OnKilled = function(self, instigator, damageType, overkillRatio)
            SuperClass.OnKilled(self, instigator, damageType, overkillRatio)
            local data = self.RemoteViewingData
            local satellite = data and data.Satellite
            if data then data.Satellite = nil end
            -- The unit's death cleanup may already have destroyed the vision marker.
            if satellite and not(moho.entity_methods.BeenDestroyed(satellite)) then
                satellite:DisableIntel('Vision')
                satellite:Destroy()
            end
            self:SetMaintenanceConsumptionInactive()
        end,
    }
end
