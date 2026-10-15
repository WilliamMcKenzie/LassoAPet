-- Ghost: the Halloween world's Soul Valley Common (QM, Oct 15): a plump mint ghost with a pointed hem and stubby arms; it floats.
-- designs/halloween/Ghost.bbmodel (tools/halloween_ghost.py), converted (--zyx --meshes) into
-- GhostModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GhostModel = require(script.Parent.GhostModel)

return Horse.variant("Ghost", GhostModel, "Common", {
	seat = Vector3.new(0, 8.2, 0.3),
	neck = { center = Vector3.new(0, 5, 0), radius = 2.8 },
})
