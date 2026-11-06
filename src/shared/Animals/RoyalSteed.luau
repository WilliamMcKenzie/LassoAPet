-- RoyalSteed: The Horse dressed for the Red Castle: white, a crimson caparison with gold
-- trim, a steel face plate and a red plume.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Divine there is Lasso's Uncommon, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local RoyalSteedModel = require(script.Parent.RoyalSteedModel)

return Horse.variant("RoyalSteed", RoyalSteedModel, "Uncommon")
