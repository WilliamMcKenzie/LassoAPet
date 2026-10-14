-- Starfish: a chunky orange five-armed star with yellow bumps, a pale underside and
-- the Horse's googly eyes on a hump in the middle. Common, Ocean, small.
-- designs/ocean/Starfish.bbmodel is built and animated by tools/starfish_design.py,
-- converted into StarfishModel.luau by tools/bbmodel_to_luau.py. You sit on the hump.

local Horse = require(script.Parent.Horse)
local StarfishModel = require(script.Parent.StarfishModel)

return Horse.variant("Starfish", StarfishModel, "Uncommon", {
	seat = Vector3.new(0, 2.92, 0.1),
	neck = { center = Vector3.new(0, 2.27, 0), radius = 1.7 },
})
