-- Blue Crab: QM's King Crab in blue (QM's file, twice the King Crab's model size,
-- the same bones and animations). Legendary, Ocean. Its sprint is a smashing
-- sideways crab walk, and its ability, Feast, cashes in what it broke since the
-- last one (Config.Abilities). designs/ocean/BlueCrab.bbmodel is converted into
-- BlueCrabModel.luau with `tools/bbmodel_to_luau.py --zyx`. You ride on top of its shell.

local Horse = require(script.Parent.Horse)
local BlueCrabModel = require(script.Parent.BlueCrabModel)

return Horse.variant("BlueCrab", BlueCrabModel, "Legendary", {
	seat = Vector3.new(0, 5.1, 0.4),
	neck = { center = Vector3.new(0, 3.8, -3.0), radius = 3.0 },
})
