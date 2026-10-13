-- Asura: World 2's Crimson Lands Legendary, a horned slate warrior with cyan hair, red
-- glowing eyes, a cape and a big sword held high. Large (QM, Oct 13). From QM's model
-- via tools/asura.py into designs/crimson/Asura.bbmodel, converted --zyx into
-- AsuraModel.luau by tools/bbmodel_to_luau.py. You ride on its shoulders, behind the helm.

local Horse = require(script.Parent.Horse)
local AsuraModel = require(script.Parent.AsuraModel)

return Horse.variant("Asura", AsuraModel, "Legendary", {
	seat = Vector3.new(0, 7.1, 1.3),
	seatBone = "body",
	neck = { center = Vector3.new(0, 7.8, 0.6), radius = 1.4 },
})
