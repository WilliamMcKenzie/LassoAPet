-- Eyepatch Shark: World 3 Pirate Cove's Epic (Oct 14). A bright blue land shark swimming through the
-- air just over the sand: an eyepatch, a red bandana, a scar, an open grin of pyramid teeth (the
-- jaw chomps), a tall dorsal fin and a two-lobed tail. You ride behind the dorsal fin.
-- designs/world3/pirate/EyepatchShark.bbmodel (tools/pirate_shark.py), converted (--zyx) into EyepatchSharkModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local EyepatchSharkModel = require(script.Parent.EyepatchSharkModel)

return Horse.variant("EyepatchShark", EyepatchSharkModel, "Epic", {
	seat = Vector3.new(0, 5.61, 1.6),
	neck = { center = Vector3.new(0, 4.16, -6.3), radius = 2.6 },
})
