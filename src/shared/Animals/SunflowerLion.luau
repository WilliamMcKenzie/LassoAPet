-- SunflowerLion: World 3's Garden Legendary (Oct 14; roster approved by the coordinator for QM): a proud golden lion, head held high inside a huge sunflower mane (made
-- majestic Oct 15 for QM): a studded seed disc and rings of smooth mesh petals, mesh leaf cuffs, a stem tail
-- ending in a little sunflower.
-- designs/garden/SunflowerLion.bbmodel (tools/garden_lion.py), converted (--zyx) into SunflowerLionModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SunflowerLionModel = require(script.Parent.SunflowerLionModel)

return Horse.variant("SunflowerLion", SunflowerLionModel, "Legendary", {
	seat = Vector3.new(0, 9.0, 1.4),
	neck = { center = Vector3.new(0, 10.7, -4.6), radius = 2.7 },
})
