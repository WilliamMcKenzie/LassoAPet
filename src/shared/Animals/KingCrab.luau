-- King Crab: QM's crab, red shell with gold spikes, a big claw and a small one, googly
-- eyes on stalks. Epic, Ocean. designs/ocean/KingCrab.bbmodel is QM's model coloured,
-- rigged and animated by tools/king_crab.py, converted into KingCrabModel.luau by
-- tools/bbmodel_to_luau.py. You ride on top of its shell.

local Horse = require(script.Parent.Horse)
local KingCrabModel = require(script.Parent.KingCrabModel)

return Horse.variant("KingCrab", KingCrabModel, "Epic", {
	seat = Vector3.new(0, 2.65, 0.2),
	neck = { center = Vector3.new(0, 2.0, -1.5), radius = 1.5 },
})
