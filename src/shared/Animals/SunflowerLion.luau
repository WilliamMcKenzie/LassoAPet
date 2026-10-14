-- SunflowerLion: World 3's Garden Legendary (Oct 14; roster approved by the coordinator for QM): a hefty golden lion whose mane is a sunflower wrapped round its head in
-- layers of pyramid petals, leaf cuffs on its legs, a stem tail ending in a little sunflower.
-- designs/garden/SunflowerLion.bbmodel (tools/garden_lion.py), converted (--zyx) into SunflowerLionModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SunflowerLionModel = require(script.Parent.SunflowerLionModel)

return Horse.variant("SunflowerLion", SunflowerLionModel, "Legendary", {
	seat = Vector3.new(0, 9.0, 1.4),
	neck = { center = Vector3.new(0, 9.6, -5.2), radius = 2.7 },
})
