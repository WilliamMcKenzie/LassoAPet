-- GrimReaper: the Halloween world's Soul Valley Legendary (QM, Oct 15): a floating reaper in a dark hooded robe with a glowing teal scythe.
-- designs/halloween/GrimReaper.bbmodel (tools/halloween_grim_reaper.py), converted (--zyx --meshes) into
-- GrimReaperModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GrimReaperModel = require(script.Parent.GrimReaperModel)

return Horse.variant("GrimReaper", GrimReaperModel, "Legendary", {
	seat = Vector3.new(0, 7.2, 2),
	neck = { center = Vector3.new(0, 8.6, -0.5), radius = 2.8 },
})
