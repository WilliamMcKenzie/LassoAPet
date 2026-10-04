-- Loong: QM's Eastern dragon, green with red whiskers, gold bands and bone horns, floating
-- with its legs hanging. Legendary, Godlands, large (tier 3). QM's model is
-- designs/godlands/Loong_QM.bbmodel; tools/dragon_rig.py scales it 2x, gives it its slither
-- (a sine wave running head to tail, hovering clear of the ground) and its "special" fire
-- breath, and writes designs/godlands/Loong.bbmodel, converted into LoongModel.luau with
-- `tools/bbmodel_to_luau.py --zyx`. You ride in the saddle on its chest.

local Horse = require(script.Parent.Horse)
local LoongModel = require(script.Parent.LoongModel)

return Horse.variant("Loong", LoongModel, "Legendary", {
	seat = Vector3.new(0, 7, -1.2),
	seatBone = "saddle", -- on the chest, which the slither swings about
	neck = { center = Vector3.new(0, 4.8, -7.2), radius = 2.6 },
})
