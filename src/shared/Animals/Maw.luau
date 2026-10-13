-- Maw: World 2's Crimson Lands Rare, a wide toothy mouth on three tentacles, no eyes.
-- QM's model designs/crimson/Maw.bbmodel (first made and animated by tools/crimson_maw.py),
-- converted --zyx into MawModel.luau by tools/bbmodel_to_luau.py. You ride on top of
-- its upper jaw (the Top bone, propped open), so the seat follows that bone.

local Horse = require(script.Parent.Horse)
local MawModel = require(script.Parent.MawModel)

return Horse.variant("Maw", MawModel, "Rare", {
	seat = Vector3.new(0, 8.5, -0.2),
	seatBone = "Top",
	neck = { center = Vector3.new(0, 5.5, -0.2), radius = 5 },
})
