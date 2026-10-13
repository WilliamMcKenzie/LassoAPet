-- Marble Colossus: World 2 Meadow's Epic. A gorilla-stance marble golem with arms that
-- reach the ground, glowing yellow eyes on black, gold bracers, headband and spikes.
-- Model from designs/world2/MarbleColossus.bbmodel (tools/marble_colossus.py), converted
-- into MarbleColossusModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local MarbleColossusModel = require(script.Parent.MarbleColossusModel)

return Horse.variant("MarbleColossus", MarbleColossusModel, "Epic", {
	seat = Vector3.new(0, 8.4, -0.6),
	neck = { center = Vector3.new(0, 6.1, -4.0), radius = 1.6 },
})
