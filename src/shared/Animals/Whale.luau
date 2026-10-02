-- Whale: a big blue sperm whale with a huge square head, a pale ridged belly and cyan
-- spiral glyphs. Rare, Ocean, XL (tier 4). QM's model designs/ocean/Whale.bbmodel, converted
-- into WhaleModel.luau by tools/bbmodel_to_luau.py. You ride on its back, behind the head.

local Horse = require(script.Parent.Horse)
local WhaleModel = require(script.Parent.WhaleModel)

return Horse.variant("Whale", WhaleModel, "Rare", {
	seat = Vector3.new(0, 6.4, 1.2),
	neck = { center = Vector3.new(0, 4.5, -6.5), radius = 3.8 },
})
