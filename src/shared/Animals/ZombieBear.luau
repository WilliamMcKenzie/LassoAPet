-- ZombieBear: the Halloween world's Soul Valley Rare (QM, Oct 15): a green zombie bear with a stitched purple patch and one bandaged leg.
-- designs/halloween/ZombieBear.bbmodel (tools/halloween_zombie_bear.py), converted (--zyx --meshes) into
-- ZombieBearModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ZombieBearModel = require(script.Parent.ZombieBearModel)

return Horse.variant("ZombieBear", ZombieBearModel, "Rare", {
	seat = Vector3.new(0, 7.7, 0.6),
	neck = { center = Vector3.new(0, 7.4, -4.4), radius = 2.4 },
})
