-- Beholder: an orange cube floating over six stubby tentacles, one square eye plate and pupil on its
-- front (QM: just three cubes over the tentacles). Rare, medium, Godlands (QM, Oct 4). designs/beholder/Beholder.bbmodel is
-- built and animated by tools/beholder_design.py, converted into BeholderModel.luau by
-- tools/bbmodel_to_luau.py. You sit on top of the cube. Its ability is Devour, like the
-- Kraken's, but with one tentacle for one animal (Config.Abilities.Beholder).

local Horse = require(script.Parent.Horse)
local BeholderModel = require(script.Parent.BeholderModel)

return Horse.variant("Beholder", BeholderModel, "Rare", {
	seat = Vector3.new(0, 14.6, 0.3), -- on top of the cube
	seatBone = "root", -- bobs with the blob, not with the eye looking about
	neck = { center = Vector3.new(0, 10.6, 0), radius = 6 }, -- round the body cube
})
