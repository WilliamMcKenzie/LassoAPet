-- WispWolf: the Halloween world's Soul Valley Epic (QM, Oct 15): a teal spirit wolf with a glowing ruff, tail and paws.
-- designs/halloween/WispWolf.bbmodel (tools/halloween_wisp_wolf.py), converted (--zyx --meshes) into
-- WispWolfModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local WispWolfModel = require(script.Parent.WispWolfModel)

return Horse.variant("WispWolf", WispWolfModel, "Epic", {
	seat = Vector3.new(0, 8.6, 0.8),
	neck = { center = Vector3.new(0, 9.4, -5), radius = 2.2 },
})
