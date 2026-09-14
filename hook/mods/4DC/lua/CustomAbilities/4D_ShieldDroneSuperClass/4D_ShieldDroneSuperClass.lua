local QuietPreviousShieldDrone = AutoSelectShieldDrone

function AutoSelectShieldDrone(SuperClass)
    local Previous = QuietPreviousShieldDrone(SuperClass)
    return Class(Previous) {
        ShieldEnhance = function(self)
            -- The legacy merge effect expects instance methods on its native trash bag.
            local bag = self.BuildEffectsBag or TrashBag()
            bag.Add = TrashBag.Add
            bag.Destroy = TrashBag.Destroy
            self.BuildEffectsBag = bag
            return Previous.ShieldEnhance(self)
        end,
    }
end
