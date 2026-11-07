-- Castle Wyvern (QM, Nov 7): Fight to Steal an Egg's Red Castle dragon boss, as a Legendary pet
-- in the Red Castle, about 1 in 120. Its model is FTSAE's CastleWyvernModel.luau
-- verbatim (tools/boss_recolors.py there, from our Rock Candy Dragon), so it sits as that does.

local Horse = require(script.Parent.Horse)
local CastleWyvernModel = require(script.Parent.CastleWyvernModel)

return Horse.variant("CastleWyvern", CastleWyvernModel, "Legendary", {
	seat = Vector3.new(0, 9.65, -0.2),
	neck = { center = Vector3.new(0, 9.4, -5.8), radius = 1.9 },
})
