-- Beholder: a round orange blob floating over six stubby tentacles, one huge eye on its
-- front under a heavy brow. Rare, medium, Godlands (QM, Oct 4). designs/beholder/Beholder.bbmodel is
-- built and animated by tools/beholder_design.py, converted into BeholderModel.luau by
-- tools/bbmodel_to_luau.py. You sit on top of the blob. Its ability is Devour, like the
-- Kraken's, but with one tentacle for one animal (Config.Abilities.Beholder).

local Horse = require(script.Parent.Horse)
local BeholderModel = require(script.Parent.BeholderModel)

return Horse.variant("Beholder", BeholderModel, "Rare", {
	seat = Vector3.new(0, 15.2, 0.3), -- on top of the blob
	seatBone = "root", -- bobs with the blob, not with the eye looking about
	neck = { center = Vector3.new(0, 10.6, 0), radius = 5 }, -- round the blob's middle
})
