-- The Royal Cnidarian as a pet (Oct 14): World 3 Cnidaria's boss, the crowned jellyfish with
-- four orbiting Gold Cnidarians, also a trophy in its stampede about 1 in 1,000. You ride on top
-- of its bell inside the crown. The same model as the boss (Shared/Bosses/RoyalCnidarianModel,
-- from tools/royal_cnidarian.py), sized by its tier like any pet.

local Horse = require(script.Parent.Horse)
local RoyalCnidarianModel = require(script.Parent.Parent.Bosses.RoyalCnidarianModel)

return Horse.variant("RoyalCnidarian", RoyalCnidarianModel, "Legendary", {
	seat = Vector3.new(0, 17.6, 0), -- (on top of the bell, inside the crown)
	neck = { center = Vector3.new(0, 12, 0), radius = 6 },
})
