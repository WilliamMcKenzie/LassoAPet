-- Kitten: a chibi ginger tabby with a white muzzle, chest and paws and its tail up
-- (QM's reference picture, Oct 7). Model from designs/desert/Kitten.bbmodel
-- (tools/kitten_design.py game), converted into KittenModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local KittenModel = require(script.Parent.KittenModel)

return Horse.variant("Kitten", KittenModel, "Uncommon", {
	seat = Vector3.new(0, 5, 0.9),
	neck = { center = Vector3.new(0, 4.6, -3.5), radius = 2.1 },
})
