-- BlackCat: the Halloween world's Haunted Hills Common (QM, Oct 15): a chunky black cat with a purple collar and an orange bell, pink ears, a tall hooked tail.
-- designs/halloween/BlackCat.bbmodel (tools/halloween_black_cat.py), converted (--zyx --meshes) into
-- BlackCatModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local BlackCatModel = require(script.Parent.BlackCatModel)

return Horse.variant("BlackCat", BlackCatModel, "Common", {
	seat = Vector3.new(0, 5.2, 0.6),
	neck = { center = Vector3.new(0, 5.8, -3.2), radius = 2.0 },
})
