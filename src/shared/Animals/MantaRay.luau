-- Manta Ray: World 1 Ocean's Epic (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_ocean.py (manta_ray), rigged by tools/filler_export.py into
-- designs/filler/rigged/MantaRay.bbmodel and converted into MantaRayModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local MantaRayModel = require(script.Parent.MantaRayModel)

return Horse.variant("MantaRay", MantaRayModel, "Epic", {
	seat = Vector3.new(0, 1.68, -0.41),
	neck = { center = Vector3.new(0, 1.02, -2.62), radius = 1.0 },
})
